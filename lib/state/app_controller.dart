import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/admin_models.dart';
import '../models/app_notification.dart';
import '../models/exam_question.dart';
import '../services/api_service.dart';
import '../services/app_changelog.dart';
import '../services/content_repository.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/google_drive_backup_service.dart';
import '../services/notification_service.dart';
import '../services/home_widget_service.dart';
import '../services/feature_flags_service.dart';
import '../services/progress_sync_service.dart';
import '../services/tts_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.repository,
    required this.tts,
    GoogleDriveBackupService? driveBackup,
  }) : driveBackup = driveBackup ?? GoogleDriveBackupService();

  final ContentRepository repository;
  final TtsService tts;
  final ApiService _api = ApiService();
  final GoogleDriveBackupService driveBackup;
  // Lazy agar konstruksi controller tidak crash saat Firebase belum
  // dikonfigurasi (tes, mode offline). Akses pertama yang butuh Firebase
  // tetap aman karena seluruh pemakaian dibungkus try/catch.
  FirebaseAuthService? _firebaseAuth;
  ProgressSyncService? _syncService;

  FirebaseAuthService get firebaseAuth =>
      _firebaseAuth ??= FirebaseAuthService();
  set firebaseAuth(FirebaseAuthService value) => _firebaseAuth = value;

  ProgressSyncService get syncService => _syncService ??= ProgressSyncService();
  set syncService(ProgressSyncService value) => _syncService = value;

  final ValueNotifier<int> bootstrapRevision = ValueNotifier(0);

  /// UID cloud aktif (Firebase uid). Null = hanya lokal/offline.
  String? cloudUid;

  /// Status sinkronisasi untuk UI: idle/syncing/offline/error.
  String syncStatus = 'idle';
  DateTime? lastSyncAt;
  String? lastSyncError;

  /// Waktu update per field (epoch-ms) untuk merge LWW yang adil.
  final Map<String, int> _fieldUpdatedAt = {};

  SharedPreferences? _preferences;
  Timer? _reviewSaveTimer;
  bool ready = false;
  bool contentReady = false;
  bool darkMode = false;
  bool furiganaVisible = true;
  String profileName = 'Tamu';
  String profileEmail = '';
  String profilePhotoUrl = '';
  String profilePhotoData = '';
  String profileBirthDate = '';
  String profilePhone = '';
  String profileBio = '';
  String profileHandle = '';
  String profileInstagram = '';
  String profileYoutube = '';
  int profileFollowers = 0;
  int profileFollowing = 0;
  bool onboardingComplete = false;
  String studyGoal = 'JLPT';
  String selfLevel = 'Pemula';
  int dailyStudyMinutes = 20;
  String selectedStudyLevel = 'N5';
  String learningMode = 'Seimbang';
  String appLanguage = 'id';
  String ttsGender = 'auto';
  int reviewIntervalDays = 2;
  bool googleLinked = false;
  bool isAuthenticated = false;
  bool isAdmin = false;
  String authProvider = '';
  final Map<String, String> _localAccounts = {};
  final Map<String, String> _localAccountNames = {};
  bool isPremium = false;
  String membershipTier = 'free';
  String membershipPlan = 'free';
  DateTime? premiumUntil;
  final Set<String> unlockedLevels = {'N5'};
  final Map<String, int> placementBestScores = {};
  String activeRoadmapStepId = 'n5';
  bool hasUnreadNotifications = true;
  final List<AppNotification> inbox = [];
  final Set<String> _seenAnnouncementIds = {};
  bool reviewReminderEnabled = true;
  int reviewReminderHour = 20;
  int reviewReminderMinute = 0;
  String lastReminderDismissDate = '';
  String lastDriveBackupLabel = 'belum ada';
  bool driveBackupBusy = false;
  int xp = 0;
  int dailyXp = 0;
  int streak = 0;
  int quizCorrect = 0;
  int quizAnswered = 0;
  int examPoints = 0;
  final Map<String, int> examBestScores = {};
  String lastStudyDate = '';
  final Set<String> studyDateKeys = {};
  final Set<int> reviewReminderWeekdays = {1, 2, 3, 4, 5, 6, 7};
  bool calendarReminderEnabled = false;
  bool glassTheme = true;
  String todayKanjiMode = 'adaptive';
  int todayKanjiPinnedId = 0;
  DateTime? firstUsedAt;
  DateTime? sessionStartedAt;
  int totalActiveSeconds = 0;
  int sessionCount = 0;
  final List<Map<String, Object?>> activityJournal = [];
  final Set<int> learnedKanjiIds = {};
  final Set<int> masteredKanjiIds = {};
  final Map<int, int> kanjiMasteryStreaks = {};
  final Map<int, int> kanjiReviewSteps = {};
  final Map<int, int> kanjiNextReviewDays = {};
  final Set<int> favoriteKanjiIds = {};
  final Set<int> masteredVocabularyIds = {};
  final Set<String> completedGrammarIds = {};
  final Set<String> completedLearningStepIds = {};
  final Set<String> completedPhraseIds = {};
  final Set<String> completedSentenceIds = {};
  final Set<String> completedCultureIds = {};
  Map<String, bool> featureFlags = {};

  static const dailyGoal = 100;
  static const kanjiMasteryThreshold = 3;
  List<int> get kanjiReviewIntervals => [
        reviewIntervalDays,
        reviewIntervalDays * 2,
        reviewIntervalDays * 4,
        reviewIntervalDays * 8,
        reviewIntervalDays * 16,
      ];

  @override
  void dispose() {
    _reviewSaveTimer?.cancel();
    driveBackup.dispose();
    final sync = _syncService;
    if (sync != null) unawaited(sync.dispose());
    unawaited(tts.stop());
    bootstrapRevision.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      await _load();
    } catch (_) {
      // A corrupt local preference or an unavailable asset must not leave the
      // user on the startup screen forever. The shell can still open and any
      // content-dependent screen will remain unavailable until a restart.
      ready = true;
      bootstrapRevision.value++;
      notifyListeners();
    }
  }

  Future<void> _load() async {
    _preferences = await SharedPreferences.getInstance();
    final prefs = _preferences!;
    final savedAccounts = prefs.getStringList('localAccounts_v1') ?? const [];
    _localAccounts.clear();
    _localAccountNames.clear();
    for (final raw in savedAccounts) {
      final parts = raw.split('\u001f');
      if (parts.length >= 3 && parts[0].trim().isNotEmpty) {
        final email = parts[0].trim().toLowerCase();
        final stored = parts[1];
        _localAccounts[email] = RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(stored)
            ? stored
            : _hashPassword(stored);
        _localAccountNames[email] =
            parts[2].trim().isEmpty ? email.split('@').first : parts[2].trim();
      }
    }
    darkMode = prefs.getBool('darkMode') ?? false;
    furiganaVisible = prefs.getBool('furiganaVisible') ?? true;
    profileName = prefs.getString('profileName') ?? 'Tamu';
    profileEmail = prefs.getString('profileEmail') ?? '';
    profilePhotoUrl = prefs.getString('profilePhotoUrl') ?? '';
    profilePhotoData = prefs.getString('profilePhotoData') ?? '';
    profileBirthDate = prefs.getString('profileBirthDate') ?? '';
    profilePhone = prefs.getString('profilePhone') ?? '';
    profileBio = prefs.getString('profileBio') ?? '';
    profileHandle = prefs.getString('profileHandle') ?? '';
    profileInstagram = prefs.getString('profileInstagram') ?? '';
    profileYoutube = prefs.getString('profileYoutube') ?? '';
    profileFollowers = prefs.getInt('profileFollowers') ?? 0;
    profileFollowing = prefs.getInt('profileFollowing') ?? 0;
    onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    studyGoal = prefs.getString('studyGoal') ?? 'JLPT';
    selfLevel = prefs.getString('selfLevel') ?? 'Pemula';
    dailyStudyMinutes = prefs.getInt('dailyStudyMinutes') ?? 20;
    selectedStudyLevel = prefs.getString('selectedStudyLevel') ?? 'N5';
    learningMode = prefs.getString('learningMode') ?? 'Seimbang';
    appLanguage = prefs.getString('appLanguage') ?? 'id';
    ttsGender = prefs.getString('ttsGender') ?? 'auto';
    reviewIntervalDays =
        ((prefs.getInt('reviewIntervalDays') ?? 2).clamp(1, 30)).toInt();
    googleLinked = prefs.getBool('googleLinked') ?? false;
    isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    isAdmin = prefs.getBool('isAdmin') ?? false;
    authProvider = prefs.getString('authProvider') ?? '';
    final savedUid = prefs.getString('cloudUid');
    if (savedUid != null && savedUid.isNotEmpty) cloudUid = savedUid;
    try {
      final times = jsonDecode(
          prefs.getString('progressFieldUpdatedAt') ?? '{}') as Map;
      _fieldUpdatedAt
        ..clear()
        ..addAll(times.map((k, v) =>
            MapEntry('$k', (v as num?)?.toInt() ?? 0)));
    } catch (_) {}
    isPremium = prefs.getBool('isPremium') ?? false;
    membershipPlan =
        prefs.getString('membershipPlan') ?? (isPremium ? 'premium' : 'free');
    membershipTier = membershipPlan == 'lifetime' ? 'premium' : membershipPlan;
    premiumUntil = _readDate(prefs.getString('premiumUntil'));
    unlockedLevels
      ..clear()
      ..addAll(prefs.getStringList('unlockedLevels') ?? const ['N5']);
    if (!unlockedLevels.contains('N5')) unlockedLevels.add('N5');
    placementBestScores
      ..clear()
      ..addAll(_readStringIntMap('placementBestScores'));
    isPremium = membershipPlan != 'free' &&
        (membershipPlan == 'lifetime' ||
            premiumUntil == null ||
            premiumUntil!.isAfter(DateTime.now()));
    activeRoadmapStepId = prefs.getString('activeRoadmapStepId') ?? 'n5';
    hasUnreadNotifications = prefs.getBool('hasUnreadNotifications') ?? true;
    _seenAnnouncementIds
      ..clear()
      ..addAll(prefs.getStringList('seenAnnouncementIds') ?? const []);
    inbox
      ..clear()
      ..addAll(AppNotification.pruneExpired(
        (prefs.getStringList('inbox_v1') ?? const []).map((raw) {
          try {
            return AppNotification.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map));
          } catch (_) {
            return AppNotification(id: '', title: '', body: '');
          }
        }).toList(),
      ));
    inbox.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    reviewReminderEnabled = prefs.getBool('reviewReminderEnabled') ?? true;
    reviewReminderHour = prefs.getInt('reviewReminderHour') ?? 20;
    reviewReminderMinute = prefs.getInt('reviewReminderMinute') ?? 0;
    lastReminderDismissDate = prefs.getString('lastReminderDismissDate') ?? '';
    lastDriveBackupLabel =
        prefs.getString('lastDriveBackupLabel') ?? 'belum ada';
    xp = prefs.getInt('xp') ?? 0;
    dailyXp = prefs.getInt('dailyXp') ?? 0;
    streak = prefs.getInt('streak') ?? 0;
    quizCorrect = prefs.getInt('quizCorrect') ?? 0;
    quizAnswered = prefs.getInt('quizAnswered') ?? 0;
    examPoints = prefs.getInt('examPoints') ?? 0;
    examBestScores
      ..clear()
      ..addAll(_readStringIntMap('examBestScores'));
    lastStudyDate = prefs.getString('lastStudyDate') ?? '';
    studyDateKeys.addAll(prefs.getStringList('studyDateKeys') ?? const []);
    if (lastStudyDate.isNotEmpty) studyDateKeys.add(lastStudyDate);
    reviewReminderWeekdays
      ..clear()
      ..addAll(_readIntSet('reviewReminderWeekdays'));
    if (reviewReminderWeekdays.isEmpty) {
      reviewReminderWeekdays.addAll({1, 2, 3, 4, 5, 6, 7});
    }
    calendarReminderEnabled = prefs.getBool('calendarReminderEnabled') ?? false;
    glassTheme = prefs.getBool('glassTheme') ?? true;
    todayKanjiMode = prefs.getString('todayKanjiMode') ?? 'adaptive';
    todayKanjiPinnedId = prefs.getInt('todayKanjiPinnedId') ?? 0;
    featureFlags = await FeatureFlagsService.load();
    firstUsedAt = _readDate(prefs.getString('firstUsedAt'));
    totalActiveSeconds = prefs.getInt('totalActiveSeconds') ?? 0;
    sessionCount = prefs.getInt('sessionCount') ?? 0;
    _installIdentitySeed = prefs.getString('installIdentitySeed') ?? '';
    if (_installIdentitySeed.isEmpty) {
      _installIdentitySeed =
          '${DateTime.now().microsecondsSinceEpoch}-${profileEmail.hashCode}';
      await prefs.setString('installIdentitySeed', _installIdentitySeed);
    }
    if (firstUsedAt == null) {
      firstUsedAt = DateTime.now();
      await prefs.setString('firstUsedAt', firstUsedAt!.toIso8601String());
    }
    final rawJournal = prefs.getString('activityJournal_v1');
    if (rawJournal != null && rawJournal.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJournal);
        if (decoded is List) {
          activityJournal
            ..clear()
            ..addAll(decoded
                .whereType<Map>()
                .map((e) => Map<String, Object?>.from(e))
                .take(2000));
        }
      } catch (_) {}
    }
    learnedKanjiIds.addAll(_readIntSet('learnedKanji'));
    masteredKanjiIds.addAll(_readIntSet('masteredKanji'));
    kanjiMasteryStreaks.addAll(_readIntMap('kanjiMasteryStreaks'));
    kanjiReviewSteps.addAll(_readIntMap('kanjiReviewSteps'));
    kanjiNextReviewDays.addAll(_readIntMap('kanjiNextReviewDays'));
    final today = _epochDay(DateTime.now());
    var reviewScheduleChanged = false;
    for (final id in masteredKanjiIds) {
      kanjiMasteryStreaks.remove(id);
      learnedKanjiIds.add(id);
      if (!kanjiNextReviewDays.containsKey(id)) {
        kanjiNextReviewDays[id] = today + kanjiReviewIntervals.first;
        reviewScheduleChanged = true;
      }
    }
    kanjiReviewSteps.removeWhere((id, _) => !masteredKanjiIds.contains(id));
    kanjiNextReviewDays.removeWhere((id, _) => !masteredKanjiIds.contains(id));
    if (reviewScheduleChanged) {
      _saveReviewSchedule();
    }
    favoriteKanjiIds.addAll(_readIntSet('favoriteKanji'));
    masteredVocabularyIds.addAll(_readIntSet('masteredVocabulary'));
    completedGrammarIds
        .addAll(prefs.getStringList('completedGrammar') ?? const []);
    if (isAuthenticated && authProvider.isEmpty) {
      authProvider = googleLinked ? 'google' : 'email';
    }
    // Pulihkan sesi bila prefs bilang logout tapi Firebase masih login
    // (mis. install ulang tanpa hapus data Auth / prefs korup).
    if (!isAuthenticated) {
      try {
        final fbUser = firebaseAuth.currentUser;
        if (fbUser != null) {
          cloudUid = fbUser.uid;
          isAuthenticated = true;
          if (profileEmail.isEmpty) profileEmail = fbUser.email ?? '';
          final fbName = (fbUser.displayName ?? '').trim();
          if (profileName.trim().isEmpty || profileName == 'Tamu') {
            profileName = fbName.isEmpty
                ? (profileEmail.contains('@')
                    ? profileEmail.split('@').first
                    : 'Tamu')
                : fbName;
          }
          final providers =
              fbUser.providerData.map((p) => p.providerId).toSet();
          googleLinked = providers.contains('google.com');
          authProvider = googleLinked ? 'google' : 'email';
          await _saveAuthPrefs();
          await _persistCloudUid();
          unawaited(syncNow());
        }
      } catch (_) {}
    }
    completedLearningStepIds.addAll(
      prefs.getStringList('completedLearningSteps') ?? const [],
    );
    completedPhraseIds.addAll(
      prefs.getStringList('completedPhrases') ?? const [],
    );
    completedSentenceIds.addAll(
      prefs.getStringList('completedSentences') ?? const [],
    );
    completedCultureIds.addAll(
      prefs.getStringList('completedCulture') ?? const [],
    );
    _refreshDailyCounter();

    // Tampilkan shell aplikasi segera setelah state lokal siap. Dataset besar
    // dimuat setelah frame pertama agar cold start tidak menunggu JSON.
    ready = true;
    startSession();
    bootstrapRevision.value++;
    notifyListeners();

    repository.onRefreshed = () {
      bootstrapRevision.value++;
      notifyListeners();
    };
    await repository.load();
    contentReady = true;
    bootstrapRevision.value++;
    notifyListeners();
    unawaited(HomeWidgetService.instance
        .update(streak: streak, xp: xp, kanji: todayKanjiCharacter));
    unawaited(NotificationService.instance.syncReviewSchedule(
      enabled: reviewReminderEnabled,
      hour: reviewReminderHour,
      minute: reviewReminderMinute,
      weekdays: reviewReminderWeekdays,
      dueCount: dueKanjiReviewCount,
    ));
    unawaited(checkAppUpdateNotes());
  }

  int get level => xp ~/ 500 + 1;
  int get levelXp => xp % 500;
  double get levelProgress => levelXp / 500;
  double get dailyProgress => (dailyXp / dailyGoal).clamp(0.0, 1.0).toDouble();
  double get quizAccuracy => quizAnswered == 0 ? 0 : quizCorrect / quizAnswered;

  int get learnedVocabularyCount => masteredVocabularyIds.length;
  int get learnedGrammarCount => completedGrammarIds.length;
  int get learnedKanjiCount => learnedKanjiIds.length;
  int get masteredKanjiCount => masteredKanjiIds.length;
  String get languageLabel =>
      appLanguage == 'en' ? 'English' : 'Bahasa Indonesia';
  String get greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 17) return 'Konnichiwa';
    return 'Konbanwa';
  }

  String get homeGreeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Okaerinasai';
    if (h >= 12 && h < 18) return 'Irasshaimase';
    return 'Konbanwa';
  }

  /// Nama yang disapa di beranda: tamu (belum login) dipanggil Okyaku-sama.
  String get homeDisplayName {
    if (!isAuthenticated) return 'Okyaku-sama';
    final name = profileName.trim();
    return name.isEmpty ? 'Tamu' : name;
  }

  bool get hasNeverStudiedJapanese =>
      learnedKanjiIds.isEmpty &&
      masteredVocabularyIds.isEmpty &&
      completedGrammarIds.isEmpty &&
      completedLearningStepIds.isEmpty &&
      quizAnswered == 0;

  String adaptiveReading({required String reading, required String level}) {
    if (reading.isEmpty) return '';
    if (hasNeverStudiedJapanese) return _toRomaji(reading);
    return level == 'N5' ? reading : '';
  }

  bool featureEnabled(String key) => featureFlags[key] ?? false;
  bool get communityEnabled => featureEnabled(FeatureFlagsService.community);
  bool get followersEnabled => featureEnabled(FeatureFlagsService.followers);
  bool get commentsEnabled => featureEnabled(FeatureFlagsService.comments);
  bool get aiCoachEnabled => featureEnabled(FeatureFlagsService.aiCoach);
  bool get speakingEnabled => featureEnabled(FeatureFlagsService.speaking);

  Future<void> setFeatureFlag(String key, bool enabled) async {
    await FeatureFlagsService.set(key, enabled);
    featureFlags[key] = enabled;
    notifyListeners();
  }

  Future<void> reloadFeatureFlags() async {
    featureFlags = await FeatureFlagsService.load();
    notifyListeners();
  }

  String _toRomaji(String input) {
    const map = {
      'あ': 'a',
      'い': 'i',
      'う': 'u',
      'え': 'e',
      'お': 'o',
      'か': 'ka',
      'き': 'ki',
      'く': 'ku',
      'け': 'ke',
      'こ': 'ko',
      'さ': 'sa',
      'し': 'shi',
      'す': 'su',
      'せ': 'se',
      'そ': 'so',
      'た': 'ta',
      'ち': 'chi',
      'つ': 'tsu',
      'て': 'te',
      'と': 'to',
      'な': 'na',
      'に': 'ni',
      'ぬ': 'nu',
      'ね': 'ne',
      'の': 'no',
      'は': 'ha',
      'ひ': 'hi',
      'ふ': 'fu',
      'へ': 'he',
      'ほ': 'ho',
      'ま': 'ma',
      'み': 'mi',
      'む': 'mu',
      'め': 'me',
      'も': 'mo',
      'や': 'ya',
      'ゆ': 'yu',
      'よ': 'yo',
      'ら': 'ra',
      'り': 'ri',
      'る': 'ru',
      'れ': 're',
      'ろ': 'ro',
      'わ': 'wa',
      'を': 'wo',
      'ん': 'n',
      'が': 'ga',
      'ぎ': 'gi',
      'ぐ': 'gu',
      'げ': 'ge',
      'ご': 'go',
      'ざ': 'za',
      'じ': 'ji',
      'ず': 'zu',
      'ぜ': 'ze',
      'ぞ': 'zo',
      'だ': 'da',
      'ぢ': 'ji',
      'づ': 'zu',
      'で': 'de',
      'ど': 'do',
      'ば': 'ba',
      'び': 'bi',
      'ぶ': 'bu',
      'べ': 'be',
      'ぼ': 'bo',
      'ぱ': 'pa',
      'ぴ': 'pi',
      'ぷ': 'pu',
      'ぺ': 'pe',
      'ぽ': 'po',
      'ゃ': 'ya',
      'ゅ': 'yu',
      'ょ': 'yo',
      'っ': '',
      'ー': '-',
    };
    final pairs = <String, String>{
      'きゃ': 'kya',
      'きゅ': 'kyu',
      'きょ': 'kyo',
      'しゃ': 'sha',
      'しゅ': 'shu',
      'しょ': 'sho',
      'ちゃ': 'cha',
      'ちゅ': 'chu',
      'ちょ': 'cho',
      'にゃ': 'nya',
      'にゅ': 'nyu',
      'にょ': 'nyo',
      'ひゃ': 'hya',
      'ひゅ': 'hyu',
      'ひょ': 'hyo',
      'みゃ': 'mya',
      'みゅ': 'myu',
      'みょ': 'myo',
      'りゃ': 'rya',
      'りゅ': 'ryu',
      'りょ': 'ryo',
      'ぎゃ': 'gya',
      'ぎゅ': 'gyu',
      'ぎょ': 'gyo',
      'じゃ': 'ja',
      'じゅ': 'ju',
      'じょ': 'jo',
      'びゃ': 'bya',
      'びゅ': 'byu',
      'びょ': 'byo',
      'ぴゃ': 'pya',
      'ぴゅ': 'pyu',
      'ぴょ': 'pyo'
    };
    var out = '';
    for (var i = 0; i < input.length; i++) {
      if (i + 1 < input.length &&
          pairs.containsKey(input.substring(i, i + 2))) {
        out += pairs[input.substring(i, i + 2)]!;
        i++;
        continue;
      }
      final c = input[i];
      if (c == 'っ' && i + 1 < input.length) {
        final next = map[input[i + 1]] ?? '';
        if (next.isNotEmpty) out += next[0];
        continue;
      }
      out += map[c] ?? c;
    }
    return out;
  }

  int get activeDays => studyDateKeys.length;
  int get totalActiveMinutes => totalActiveSeconds ~/ 60;
  String _installIdentitySeed = '';
  int get overallMasteryPoints =>
      learnedKanjiCount +
      learnedVocabularyCount +
      learnedGrammarCount +
      completedLearningStepIds.length;
  double levelOverallMastery(String level) {
    final order = ['N5', 'N4', 'N3', 'N2', 'N1'];
    final index = order.indexOf(level);
    if (index < 0) return 0;
    final stepPrefix = 'path-${level.toLowerCase()}-';
    final doneSteps = completedLearningStepIds
        .where((id) => id.startsWith(stepPrefix))
        .length;
    final totalSteps =
        const {'N5': 25, 'N4': 25, 'N3': 20, 'N2': 15, 'N1': 14}[level] ?? 1;
    final kanjiPool = repository.kanji.where((k) => k.level == level).length;
    final vocabPool =
        repository.vocabulary.where((v) => v.level == level).length;
    final grammarPool = repository.grammar.length.clamp(1, 100000);
    final kp = kanjiPool == 0
        ? 0.0
        : masteredKanjiIds
                .where((id) => repository.kanjiById(id)?.level == level)
                .length /
            kanjiPool;
    final vp = vocabPool == 0
        ? 0.0
        : masteredVocabularyIds
                .where((id) => repository.vocabularyById(id)?.level == level)
                .length /
            vocabPool;
    final gp =
        (completedGrammarIds.length / grammarPool).clamp(0.0, 1.0).toDouble();
    final sp = (doneSteps / totalSteps).clamp(0.0, 1.0).toDouble();
    return (kp * .25 + vp * .25 + gp * .20 + sp * .30)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  int? get todayKanjiId {
    final candidates = switch (todayKanjiMode) {
      'favorites' => favoriteKanjiIds.toList(),
      'due' => dueKanjiReviewIds,
      'manual' => todayKanjiPinnedId > 0 ? [todayKanjiPinnedId] : <int>[],
      _ => learnedKanjiIds.toList(),
    };
    final source = candidates.isNotEmpty
        ? candidates
        : repository.kanji
            .where((k) => isLevelUnlocked(k.level))
            .map((k) => k.id)
            .toList();
    if (source.isEmpty) return null;
    source.sort();
    final daySeed = _epochDay(DateTime.now());
    return source[daySeed % source.length];
  }

  String get todayKanjiCharacter =>
      repository.kanjiById(todayKanjiId ?? -1)?.character ?? '日';

  int featureXpRequirement(String feature) => switch (feature) {
        'kanji' => 20,
        'quiz_center' => 50,
        'exam_simulation' => 250,
        'community' => 400,
        'advanced_path' => 100,
        _ => 0,
      };

  bool canAccessFeature(String feature) =>
      xp >= featureXpRequirement(feature) || hasFullAccess;

  /// Tamu boleh melihat + mencoba fitur dalam mode pratinjau terbatas
  /// (kuis dibatasi [guestPreviewSessionSize] soal per sesi).
  bool get isGuestPreview => !isAuthenticated;
  static const int guestPreviewSessionSize = 5;

  /// Murni (pure) agar mudah dites.
  static int previewSessionSize(bool isGuest, int full) =>
      isGuest && full > guestPreviewSessionSize ? guestPreviewSessionSize : full;

  int cappedSessionSize(int full) => previewSessionSize(isGuestPreview, full);

  String get reviewReminderTimeLabel =>
      '${reviewReminderHour.toString().padLeft(2, '0')}:'
      '${reviewReminderMinute.toString().padLeft(2, '0')}';

  String get reviewReminderDaysLabel {
    const labels = {
      1: 'Sen',
      2: 'Sel',
      3: 'Rab',
      4: 'Kam',
      5: 'Jum',
      6: 'Sab',
      7: 'Min',
    };
    if (reviewReminderWeekdays.length == 7) return 'Setiap hari';
    final ordered = reviewReminderWeekdays.toList()..sort();
    return ordered.map((day) => labels[day] ?? '$day').join(', ');
  }

  String get streakTierName {
    if (streak >= 100) return 'Kokuen';
    if (streak >= 50) return 'Kurohonoo';
    if (streak >= 30) return 'Murasaki';
    if (streak >= 20) return 'Aka';
    if (streak >= 10) return 'Ooki Honoo';
    if (streak >= 7) return 'Atsui';
    if (streak >= 3) return 'Nukumori';
    if (streak >= 1) return 'Tomoshibi';
    return 'Hi no tane';
  }

  int get streakFlameStage {
    if (streak >= 100) return 7;
    if (streak >= 50) return 6;
    if (streak >= 30) return 5;
    if (streak >= 20) return 4;
    if (streak >= 10) return 3;
    if (streak >= 7) return 2;
    if (streak >= 1) return 1;
    return 0;
  }

  bool hasStudyOnDate(DateTime date) => studyDateKeys.contains(_dateKey(date));

  bool get shouldShowInAppReviewReminder {
    if (!reviewReminderEnabled || dueKanjiReviewCount <= 0) return false;
    final now = DateTime.now();
    if (!reviewReminderWeekdays.contains(now.weekday)) return false;
    final today = _dateKey(now);
    if (lastReminderDismissDate == today) return false;
    final reminderMoment = DateTime(
      now.year,
      now.month,
      now.day,
      reviewReminderHour,
      reviewReminderMinute,
    );
    return !now.isBefore(reminderMoment);
  }

  void toggleGlassTheme() {
    glassTheme = !glassTheme;
    _preferences?.setBool('glassTheme', glassTheme);
    notifyListeners();
  }

  void setTodayKanjiMode(String mode, {int? pinnedId}) {
    if (!{'adaptive', 'favorites', 'due', 'manual'}.contains(mode)) return;
    todayKanjiMode = mode;
    if (pinnedId != null) todayKanjiPinnedId = pinnedId;
    _preferences?.setString('todayKanjiMode', todayKanjiMode);
    _preferences?.setInt('todayKanjiPinnedId', todayKanjiPinnedId);
    notifyListeners();
  }

  void startSession() {
    if (sessionStartedAt != null) return;
    sessionStartedAt = DateTime.now();
    sessionCount++;
    _preferences?.setInt('sessionCount', sessionCount);
    recordActivity('session_started', 'Sesi belajar dimulai');
  }

  void endSession() {
    final started = sessionStartedAt;
    if (started == null) return;
    final seconds =
        DateTime.now().difference(started).inSeconds.clamp(0, 86400).toInt();
    totalActiveSeconds += seconds;
    sessionStartedAt = null;
    _preferences?.setInt('totalActiveSeconds', totalActiveSeconds);
    recordActivity(
        'session_ended', 'Sesi belajar selesai (${seconds ~/ 60} menit)');
  }

  void recordActivity(String type, String label,
      {Map<String, Object?> meta = const {}}) {
    activityJournal.add({
      'at': DateTime.now().toIso8601String(),
      'type': type,
      'label': label,
      'meta': meta,
    });
    if (activityJournal.length > 2000) {
      activityJournal.removeRange(0, activityJournal.length - 2000);
    }
    _preferences?.setString('activityJournal_v1', jsonEncode(activityJournal));
  }

  void markFeatureRelease(String title, String details) {
    recordActivity('feature_release', title, meta: {'details': details});
    NotificationService.instance.showFeatureRelease(title, details);
  }

  void toggleTheme() {
    darkMode = !darkMode;
    _preferences?.setBool('darkMode', darkMode);
    bootstrapRevision.value++;
    notifyListeners();
  }

  void toggleFurigana() {
    furiganaVisible = !furiganaVisible;
    _preferences?.setBool('furiganaVisible', furiganaVisible);
    notifyListeners();
  }

  void updateProfileName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    profileName = trimmed;
    _preferences?.setString('profileName', profileName);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String goal,
    required String level,
    required int minutes,
    required String targetLevel,
  }) async {
    studyGoal = goal;
    selfLevel = level;
    dailyStudyMinutes = minutes;
    selectedStudyLevel = targetLevel;
    onboardingComplete = true;
    await Future.wait([
      _preferences?.setString('studyGoal', studyGoal) ?? Future.value(false),
      _preferences?.setString('selfLevel', selfLevel) ?? Future.value(false),
      _preferences?.setInt('dailyStudyMinutes', dailyStudyMinutes) ??
          Future.value(false),
      _preferences?.setString('selectedStudyLevel', selectedStudyLevel) ??
          Future.value(false),
      _preferences?.setBool('onboardingComplete', true) ?? Future.value(false),
    ]);
    notifyListeners();
  }

  void setSelectedStudyLevel(String level) {
    const allowed = {'N5', 'N4', 'N3', 'N2', 'N1', 'JFT'};
    if (!allowed.contains(level)) return;
    selectedStudyLevel = level;
    _preferences?.setString('selectedStudyLevel', level);
    notifyListeners();
  }

  void setLearningMode(String mode) {
    learningMode = mode;
    _preferences?.setString('learningMode', mode);
    notifyListeners();
  }

  void setAppLanguage(String value) {
    if (value != 'id' && value != 'en') return;
    appLanguage = value;
    _preferences?.setString('appLanguage', value);
    notifyListeners();
  }

  void setTtsGender(String value) {
    if (!{'auto', 'female', 'male'}.contains(value)) return;
    ttsGender = value;
    _preferences?.setString('ttsGender', value);
    tts.setGender(value);
    notifyListeners();
  }

  void setReviewIntervalDays(int days) {
    reviewIntervalDays = days.clamp(1, 30).toInt();
    _preferences?.setInt('reviewIntervalDays', reviewIntervalDays);
    _saveReviewSchedule();
    notifyListeners();
  }

  void updateProfilePhotoData(String dataUrl) {
    profilePhotoData = dataUrl;
    profilePhotoUrl = '';
    _preferences?.setString('profilePhotoData', profilePhotoData);
    _preferences?.remove('profilePhotoUrl');
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? email,
    String? photoUrl,
    String? birthDate,
    String? phone,
    String? bio,
    String? handle,
    String? instagram,
    String? youtube,
    int? followers,
    int? following,
  }) {
    final nextName = name?.trim();
    final nextEmail = email?.trim();
    final nextPhoto = photoUrl?.trim();
    if (nextName != null && nextName.isNotEmpty) {
      profileName = nextName;
      _preferences?.setString('profileName', profileName);
    }
    if (nextEmail != null) {
      profileEmail = nextEmail;
      _preferences?.setString('profileEmail', profileEmail);
    }
    if (nextPhoto != null) {
      profilePhotoUrl = nextPhoto;
      _preferences?.setString('profilePhotoUrl', profilePhotoUrl);
    }
    if (birthDate != null) {
      profileBirthDate = birthDate.trim();
      _preferences?.setString('profileBirthDate', profileBirthDate);
    }
    if (phone != null) {
      profilePhone = phone.trim();
      _preferences?.setString('profilePhone', profilePhone);
    }
    if (bio != null) {
      profileBio = bio.trim();
      _preferences?.setString('profileBio', profileBio);
    }
    if (handle != null) {
      profileHandle = handle.trim();
      _preferences?.setString('profileHandle', profileHandle);
    }
    if (instagram != null) {
      profileInstagram = instagram.trim();
      _preferences?.setString('profileInstagram', profileInstagram);
    }
    if (youtube != null) {
      profileYoutube = youtube.trim();
      _preferences?.setString('profileYoutube', profileYoutube);
    }
    if (followers != null) {
      profileFollowers = followers.clamp(0, 1000000000);
      _preferences?.setInt('profileFollowers', profileFollowers);
    }
    if (following != null) {
      profileFollowing = following.clamp(0, 1000000000);
      _preferences?.setInt('profileFollowing', profileFollowing);
    }
    notifyListeners();
  }

  /// Login Google via Firebase (benerin auth). Fallback ke profil Drive
  /// lokal bila Firebase belum dikonfigurasi agar tetap bisa offline.
  /// Pesan error login Google terakhir (untuk ditampilkan di UI).
  String? lastAuthError;

  Future<bool> signInWithGoogle() async {
    lastAuthError = null;
    try {
      final result = await firebaseAuth.signInWithGoogle();
      cloudUid = result.uid;
      googleLinked = true;
      profileName = result.displayName.trim().isEmpty
          ? profileName
          : result.displayName.trim();
      profileEmail = result.email.trim();
      profilePhotoUrl = result.photoUrl.trim();
      // Tukar Firebase idToken jadi JWT backend (kalau server terjangkau).
      try {
        if (result.idToken.isNotEmpty) {
          await _api.loginWithGoogle(idToken: result.idToken);
        }
      } catch (_) {
        // Offline / server mati: sesi Firebase lokal tetap valid.
      }
      await Future.wait([
        _preferences?.setBool('googleLinked', true) ?? Future.value(false),
        _preferences?.setString('profileName', profileName) ??
            Future.value(false),
        _preferences?.setString('profileEmail', profileEmail) ??
            Future.value(false),
        _preferences?.setString('profilePhotoUrl', profilePhotoUrl) ??
            Future.value(false),
        _preferences?.setString('cloudUid', cloudUid ?? '') ??
            Future.value(false),
      ]);
      notifyListeners();
      unawaited(syncNow());
      return true;
    } catch (e) {
      lastAuthError =
          '$e'.replaceFirst('Exception: ', '').trim().isEmpty
              ? 'Login Google gagal. Coba lagi.'
              : '$e'.replaceFirst('Exception: ', '');
      // Fallback lama: hanya profil Drive lokal (offline).
      try {
        final profile = await driveBackup.signIn();
        if (profile == null) return false;
        lastAuthError = null;
        googleLinked = true;
        profileName = profile.name.trim().isEmpty
            ? profileName
            : profile.name.trim();
        profileEmail = profile.email.trim();
        profilePhotoUrl = profile.photoUrl.trim();
        await Future.wait([
          _preferences?.setBool('googleLinked', true) ?? Future.value(false),
          _preferences?.setString('profileName', profileName) ??
              Future.value(false),
          _preferences?.setString('profileEmail', profileEmail) ??
              Future.value(false),
          _preferences?.setString('profilePhotoUrl', profilePhotoUrl) ??
              Future.value(false),
        ]);
        notifyListeners();
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<void> disconnectGoogleProfile() async {
    try {
      await firebaseAuth.signOut();
    } catch (_) {}
    await driveBackup.signOut();
    googleLinked = false;
    _preferences?.setBool('googleLinked', false);
    notifyListeners();
  }

  bool get hasFullAccess => membershipPlan == 'lifetime' || isPremium;

  bool isLevelUnlocked(String level) {
    if (level == 'N5') return true;
    if (!isAuthenticated) return false;
    if (level == 'N4') return true;
    if (hasFullAccess && ['N3', 'N2', 'N1'].contains(level)) return true;
    return unlockedLevels.contains(level) &&
        !['N3', 'N2', 'N1'].contains(level);
  }

  void unlockLevel(String level) {
    if (['N5', 'N4', 'N3', 'N2', 'N1'].contains(level)) {
      unlockedLevels.add(level);
      _preferences?.setStringList('unlockedLevels', unlockedLevels.toList());
      markProgressDirty(const ['unlockedLevels']);
      notifyListeners();
    }
  }

  String? requiredPreviousLevel(String level) {
    const order = ['N5', 'N4', 'N3', 'N2', 'N1'];
    final i = order.indexOf(level);
    return i <= 0 ? null : order[i - 1];
  }

  bool canUnlockNextLevel(String level) {
    const order = ['N5', 'N4', 'N3', 'N2', 'N1'];
    final i = order.indexOf(level);
    if (i < 0 || i == order.length - 1) return false;
    final completed =
        completedLearningStepIds.contains('level-${level.toLowerCase()}-final');
    return completed || (placementBestScores[level] ?? 0) >= 80;
  }

  void recordPlacement(String level, int score) {
    final best = placementBestScores[level] ?? 0;
    if (score > best) placementBestScores[level] = score;
    if (score >= 80) {
      const order = ['N5', 'N4', 'N3', 'N2', 'N1'];
      final i = order.indexOf(level);
      if (i >= 0 && i < order.length - 1) unlockedLevels.add(order[i + 1]);
    }
    _preferences?.setStringList('unlockedLevels', unlockedLevels.toList());
    _preferences?.setString(
        'placementBestScores', jsonEncode(placementBestScores));
    markProgressDirty(const ['unlockedLevels', 'placementBestScores']);
    notifyListeners();
  }

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<void> _persistLocalAccounts(SharedPreferences prefs) async {
    final emails = _localAccounts.keys.toList()..sort();
    final values = [
      for (final email in emails)
        [
          email,
          _localAccounts[email] ?? '',
          _localAccountNames[email] ?? email.split('@').first
        ].join('\u001f'),
    ];
    await prefs.setStringList('localAccounts_v1', values);
  }

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = name.trim();
    if (normalizedName.length < 2) return 'Nama minimal 2 karakter.';
    if (!normalizedEmail.contains('@') || !normalizedEmail.contains('.'))
      return 'Format email tidak valid.';
    if (password.length < 8) return 'Password minimal 8 karakter.';

    // 1. Firebase (backend utama) bila sudah dikonfigurasi.
    if (FirebaseBootstrap.isAvailable) {
      try {
        final fb = await firebaseAuth.signUpWithEmail(
          name: normalizedName,
          email: normalizedEmail,
          password: password,
        );
        cloudUid = fb.uid;
        isAuthenticated = true;
        isAdmin = false;
        authProvider = 'email';
        profileEmail = fb.email;
        profileName = fb.displayName;
        await _saveAuthPrefs();
        await _persistCloudUid();
        notifyListeners();
        unawaited(syncNow());
        return null;
      } on FirebaseAuthFailure catch (e) {
        if (!e.isNetworkError) return e.message;
        // Offline: lanjut ke fallback lokal di bawah.
      } catch (_) {
        // Lanjut ke fallback di bawah.
      }
    }

    try {
      final result = await _api.register(
        name: normalizedName,
        email: normalizedEmail,
        password: password,
      );
      final user = Map<String, dynamic>.from(result['user'] as Map? ?? const {});
      isAuthenticated = true;
      isAdmin = (user['role'] ?? 'user').toString() == 'admin';
      authProvider = 'email';
      profileEmail = (user['email'] ?? normalizedEmail).toString();
      profileName = (user['display_name'] ?? normalizedName).toString();
      await _saveAuthPrefs();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message.isNotEmpty ? e.message : 'Pendaftaran gagal.';
    } catch (_) {
      // Server tidak terjangkau: daftar di penyimpanan lokal (offline).
      if (_localAccounts.containsKey(normalizedEmail)) {
        return 'Email sudah terdaftar.';
      }
      _localAccounts[normalizedEmail] = _hashPassword(password);
      _localAccountNames[normalizedEmail] = normalizedName;
      final prefs = _preferences ?? await SharedPreferences.getInstance();
      _preferences ??= prefs;
      await _persistLocalAccounts(prefs);
      return null;
    }
  }

  Future<String?> loginWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty)
      return 'Email dan password wajib diisi.';

    // 1. Firebase (backend utama) bila sudah dikonfigurasi.
    if (FirebaseBootstrap.isAvailable) {
      try {
        final fb = await firebaseAuth.signInWithEmail(
          email: normalizedEmail,
          password: password,
        );
        cloudUid = fb.uid;
        isAuthenticated = true;
        isAdmin = false;
        authProvider = 'email';
        googleLinked = false;
        profileEmail = fb.email;
        profileName = fb.displayName;
        await _saveAuthPrefs();
        await _persistCloudUid();
        notifyListeners();
        unawaited(syncNow());
        return null;
      } on FirebaseAuthFailure catch (e) {
        if (!e.isNetworkError) return e.message;
        // Offline: lanjut ke fallback lokal di bawah.
      } catch (_) {
        // Lanjut ke fallback di bawah.
      }
    }

    try {
      final result = await _api.login(
        email: normalizedEmail,
        password: password,
      );
      final user = Map<String, dynamic>.from(result['user'] as Map? ?? const {});
      isAuthenticated = true;
      isAdmin = (user['role'] ?? 'user').toString() == 'admin';
      authProvider = 'email';
      googleLinked = false;
      profileEmail = (user['email'] ?? normalizedEmail).toString();
      profileName = (user['display_name'] ?? user['email'] ?? normalizedEmail)
          .toString();
      await _saveAuthPrefs();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      // Server merespons: pesan dari server bersifat otoritatif.
      return e.message.isNotEmpty ? e.message : 'Login gagal.';
    } catch (_) {
      // Server tidak terjangkau: verifikasi akun lokal (mode offline).
      final registeredPassword = _localAccounts[normalizedEmail];
      final passwordHash = _hashPassword(password);
      if (registeredPassword == null || registeredPassword != passwordHash) {
        return 'Email atau password salah. (mode offline)';
      }
      isAuthenticated = true;
      isAdmin = false;
      authProvider = 'email';
      googleLinked = false;
      profileEmail = normalizedEmail;
      profileName = _localAccountNames[normalizedEmail] ??
          normalizedEmail.split('@').first;
      await _saveAuthPrefs();
      notifyListeners();
      return null;
    }
  }

  Future<void> _persistCloudUid() async {
    final uid = cloudUid;
    if (uid == null || uid.isEmpty) return;
    await (_preferences?.setString('cloudUid', uid) ?? Future.value(false));
  }

  Future<void> _saveAuthPrefs() async {
    await Future.wait([
      _preferences?.setBool('isAuthenticated', isAuthenticated) ??
          Future.value(false),
      _preferences?.setBool('isAdmin', isAdmin) ?? Future.value(false),
      _preferences?.setString('authProvider', authProvider) ??
          Future.value(false),
      _preferences?.setString('profileEmail', profileEmail) ??
          Future.value(false),
      _preferences?.setString('profileName', profileName) ??
          Future.value(false),
      _preferences?.setBool('googleLinked', googleLinked) ??
          Future.value(false),
    ]);
  }

  Future<bool> loginWithGoogle() async {
    final ok = await signInWithGoogle();
    if (!ok) return false;
    isAuthenticated = true;
    isAdmin = false;
    authProvider = 'google';
    await _saveAuthPrefs();
    notifyListeners();
    // Tarik + gabung progress cloud agar HP baru langsung dapat data lama.
    unawaited(syncNow());
    return true;
  }

  Future<void> logout() async {
    if (googleLinked) await disconnectGoogleProfile();
    try {
      await firebaseAuth.signOut();
    } catch (_) {}
    try {
      await syncService.dispose();
    } catch (_) {}
    try {
      await _api.logout();
    } catch (_) {}
    cloudUid = null;
    syncStatus = 'idle';
    isAuthenticated = false;
    isAdmin = false;
    authProvider = '';
    await Future.wait([
      _preferences?.setBool('isAuthenticated', false) ?? Future.value(false),
      _preferences?.setBool('isAdmin', false) ?? Future.value(false),
      _preferences?.remove('authProvider') ?? Future.value(false),
      _preferences?.remove('cloudUid') ?? Future.value(false),
    ]);
    notifyListeners();
  }

  // ---------- Cloud sync offline-online (Firestore, merge per-field) ----------

  /// Snapshot progress lokal dalam format sync (tanpa foto besar).
  Map<String, dynamic> toSyncMap() {
    final raw = jsonDecode(exportProgress()) as Map<String, dynamic>;
    raw.remove('profilePhotoData');
    raw.remove('format');
    raw.remove('exportedAt');
    raw.remove('isAuthenticated');
    raw.remove('isAdmin');
    return raw;
  }

  /// Terapkan hasil merge remote ke state + tulis ke SharedPreferences.
  Future<void> applyMergedMap(Map<String, dynamic> merged) async {
    final wrapped = Map<String, dynamic>.from(merged)
      ..['format'] = 'japanese-study-progress-v1';
    await importProgress(jsonEncode(wrapped));
  }

  void _touchFields(Iterable<String> keys) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final k in keys) {
      _fieldUpdatedAt[k] = now;
    }
    _preferences?.setString('progressFieldUpdatedAt', jsonEncode(_fieldUpdatedAt));
  }

  /// Tandai progress kotor lalu jadwalkan push (dipanggil tiap ada perubahan).
  void markProgressDirty([Iterable<String> keys = const ['xp']]) {
    _touchFields(keys);
    final uid = cloudUid ?? _currentUidOrNull();
    if (uid == null || uid.isEmpty) {
      syncStatus = 'offline';
      notifyListeners();
      return;
    }
    cloudUid = uid;
    syncStatus = 'syncing';
    notifyListeners();
    syncService.schedulePush(() async {
      await syncNow();
    });
  }

  bool get _syncAvailable {
    try {
      return syncService.isAvailable;
    } catch (_) {
      return false;
    }
  }

  String? _currentUidOrNull() {
    if (cloudUid != null && cloudUid!.isNotEmpty) return cloudUid;
    try {
      return firebaseAuth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Sinkronisasi sekarang: pull remote -> merge -> push balik.
  /// Aman offline: gagal jaringan hanya tandai pending.
  Future<bool> syncNow() async {
    final uid = _currentUidOrNull();
    if (uid == null || uid.isEmpty) {
      syncStatus = 'offline';
      notifyListeners();
      return false;
    }
    cloudUid = uid;
    try {
      if (!_syncAvailable) {
        syncStatus = 'offline';
        lastSyncError = 'Firebase belum dikonfigurasi.';
        notifyListeners();
        return false;
      }
      syncStatus = 'syncing';
      notifyListeners();
      final remoteDoc = await syncService.pullRemote(uid);
      final remoteData = (remoteDoc?['data'] as Map?)
              ?.map((k, v) => MapEntry('$k', v)) ??
          {};
      final remoteTimes = (remoteDoc?['fieldUpdatedAt'] as Map?)
              ?.map((k, v) => MapEntry('$k', (v as num?)?.toInt() ?? 0)) ??
          {};
      final merged = ProgressSyncService.merge(
        toSyncMap(),
        Map<String, dynamic>.from(remoteData),
        localUpdatedAt: Map<String, int>.from(_fieldUpdatedAt),
        remoteUpdatedAt: Map<String, int>.from(remoteTimes),
      );
      await applyMergedMap(merged);
      await syncService.pushLocal(uid, merged,
          fieldUpdatedAt: Map<String, int>.from(_fieldUpdatedAt));
      lastSyncAt = DateTime.now();
      syncStatus = syncService.syncPending ? 'offline' : 'idle';
      lastSyncError = syncService.lastError;
      await _preferences?.setString(
          'lastCloudSyncAt', lastSyncAt!.toIso8601String());
      notifyListeners();
      // Dengarkan perubahan dari HP lain selama sesi ini.
      syncService.listenRemote(uid, (remote) async {
        final fresh = ProgressSyncService.merge(
          toSyncMap(),
          remote,
          localUpdatedAt: Map<String, int>.from(_fieldUpdatedAt),
          remoteUpdatedAt: Map<String, int>.from(remoteTimes),
        );
        await applyMergedMap(fresh);
      });
      return true;
    } catch (e) {
      syncStatus = 'error';
      lastSyncError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setPremiumForTesting(bool enabled) {
    setMembershipPlan(enabled ? 'premium' : 'free');
  }

  void setMembershipPlan(String plan, {DateTime? until}) {
    final normalized = switch (plan) {
      'premium' => 'premium',
      'lifetime' => 'lifetime',
      _ => 'free',
    };
    membershipPlan = normalized;
    membershipTier = normalized == 'free' ? 'free' : 'premium';
    premiumUntil = normalized == 'lifetime' ? null : until;
    isPremium = normalized == 'lifetime' || normalized == 'premium';
    _preferences?.setString('membershipPlan', membershipPlan);
    _preferences?.setString('membershipTier', membershipTier);
    _preferences?.setBool('isPremium', isPremium);
    if (premiumUntil == null) {
      _preferences?.remove('premiumUntil');
    } else {
      _preferences?.setString('premiumUntil', premiumUntil!.toIso8601String());
    }
    notifyListeners();
  }

  void setMembershipTier(String tier) {
    setMembershipPlan(tier);
  }

  void markPremiumPurchased() {
    setMembershipPlan('premium',
        until: DateTime.now().add(const Duration(days: 30)));
  }

  void markLifetimePurchased() {
    setMembershipPlan('lifetime');
  }

  void restoreFreePlanForTesting() {
    setMembershipPlan('free');
  }

  void startRoadmapStep(String id) {
    activeRoadmapStepId = id;
    _preferences?.setString('activeRoadmapStepId', id);
    notifyListeners();
  }

  void completeRoadmapStep(String id) {
    activeRoadmapStepId = id;
    completedLearningStepIds.add('roadmap-$id');
    _preferences?.setString('activeRoadmapStepId', id);
    _preferences?.setStringList(
        'completedLearningSteps', completedLearningStepIds.toList());
    recordStudy(xpGained: 20, notify: false);
    notifyListeners();
  }

  void markNotificationsRead() {
    var changed = hasUnreadNotifications;
    hasUnreadNotifications = false;
    _preferences?.setBool('hasUnreadNotifications', false);
    for (final item in inbox) {
      if (!item.read) {
        item.read = true;
        changed = true;
      }
    }
    if (changed) {
      unawaited(_persistInbox());
      notifyListeners();
    }
  }

  Future<void> _persistInbox() async {
    final prefs = _preferences;
    if (prefs == null) return;
    await prefs.setStringList(
      'inbox_v1',
      inbox.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// Tambah notifikasi ke kotak masuk (dedupe per id, tanpa hapus manual;
  /// kedaluwarsa otomatis 90 hari).
  void pushInboxNotification({
    required String id,
    required String title,
    required String body,
    String kind = 'info',
    DateTime? createdAt,
  }) {
    if (id.isEmpty || title.trim().isEmpty) return;
    if (inbox.any((e) => e.id == id)) return;
    inbox.insert(
      0,
      AppNotification(
        id: id,
        title: title.trim(),
        body: body.trim(),
        kind: kind,
        createdAt: createdAt,
      ),
    );
    // Batasi 200 entri agar penyimpanan lokal tetap ringan.
    if (inbox.length > 200) inbox.removeRange(200, inbox.length);
    hasUnreadNotifications = true;
    _preferences?.setBool('hasUnreadNotifications', true);
    unawaited(_persistInbox());
    notifyListeners();
  }

  /// Sinkronkan pengumuman admin menjadi notifikasi otomatis.
  ///
  /// Pemakaian pertama menandai semua yang sudah ada sebagai "terlihat"
  /// tanpa notifikasi (agar tidak banjir); pengumuman BARU setelah itu
  /// otomatis masuk kotak masuk.
  void syncAnnouncementInbox(List<AdminAnnouncement> announcements) {
    final prefs = _preferences;
    if (prefs == null) return;
    final firstRun = !prefs.containsKey('seenAnnouncementIds');
    var added = false;
    for (final a in announcements) {
      if (!a.active || a.id.isEmpty) continue;
      if (_seenAnnouncementIds.add(a.id)) {
        added = true;
        if (!firstRun) {
          pushInboxNotification(
            id: 'ann-${a.id}',
            title: a.title.isEmpty ? 'Pengumuman baru' : a.title,
            body: a.body,
            kind: 'pengumuman',
            createdAt: a.createdAt,
          );
        }
      }
    }
    if (added || firstRun) {
      unawaited(prefs.setStringList(
          'seenAnnouncementIds', _seenAnnouncementIds.toList()));
    }
  }

  /// Cek catatan perubahan bawaan aplikasi; tiap versi/konten baru otomatis
  /// menjadi notifikasi "update".
  Future<void> checkAppUpdateNotes() async {
    final prefs = _preferences;
    if (prefs == null) return;
    final seen = prefs.getString('lastChangelogVersion') ?? '';
    if (seen.isEmpty) {
      await prefs.setString(
          'lastChangelogVersion', AppChangelog.latestVersion);
      return;
    }
    final fresh = AppChangelog.newerThan(seen);
    for (final entry in fresh) {
      pushInboxNotification(
        id: 'changelog-${entry.version}',
        title: entry.title,
        body: entry.body,
        kind: 'update',
      );
    }
    if (fresh.isNotEmpty) {
      await prefs.setString(
          'lastChangelogVersion', AppChangelog.latestVersion);
    } else if (seen != AppChangelog.latestVersion) {
      await prefs.setString(
          'lastChangelogVersion', AppChangelog.latestVersion);
    }
  }

  void resetNotificationsForTesting() {
    hasUnreadNotifications = true;
    _preferences?.setBool('hasUnreadNotifications', true);
    notifyListeners();
  }

  Future<String> backupProgressToDrive() async {
    if (driveBackupBusy) return 'Pencadangan sedang berjalan';
    driveBackupBusy = true;
    notifyListeners();
    try {
      final link = await driveBackup.uploadProgressJson(exportProgress());
      lastDriveBackupLabel = DateTime.now().toIso8601String();
      await _preferences?.setString(
          'lastDriveBackupLabel', lastDriveBackupLabel);
      return link;
    } finally {
      driveBackupBusy = false;
      notifyListeners();
    }
  }

  Future<String> restoreProgressFromDrive() async {
    if (driveBackupBusy) return 'Sinkronisasi sedang berjalan';
    driveBackupBusy = true;
    notifyListeners();
    try {
      final jsonText = await driveBackup.downloadLatestProgressJson();
      final ok = await importProgress(jsonText);
      if (!ok) throw Exception('Format cadangan tidak cocok.');
      lastDriveBackupLabel = DateTime.now().toIso8601String();
      await _preferences?.setString(
          'lastDriveBackupLabel', lastDriveBackupLabel);
      return 'Kemajuan berhasil dipulihkan dari Google Drive.';
    } finally {
      driveBackupBusy = false;
      notifyListeners();
    }
  }

  void setReviewReminderEnabled(bool enabled) {
    reviewReminderEnabled = enabled;
    _preferences?.setBool('reviewReminderEnabled', enabled);
    unawaited(NotificationService.instance.syncReviewSchedule(
      enabled: reviewReminderEnabled,
      hour: reviewReminderHour,
      minute: reviewReminderMinute,
      weekdays: reviewReminderWeekdays,
      dueCount: dueKanjiReviewCount,
    ));
    notifyListeners();
  }

  void setReviewReminderTime(TimeOfDay time) {
    reviewReminderHour = time.hour;
    reviewReminderMinute = time.minute;
    _preferences?.setInt('reviewReminderHour', reviewReminderHour);
    _preferences?.setInt('reviewReminderMinute', reviewReminderMinute);
    unawaited(NotificationService.instance.syncReviewSchedule(
      enabled: reviewReminderEnabled,
      hour: reviewReminderHour,
      minute: reviewReminderMinute,
      weekdays: reviewReminderWeekdays,
      dueCount: dueKanjiReviewCount,
    ));
    notifyListeners();
  }

  void toggleReviewReminderWeekday(int weekday) {
    if (reviewReminderWeekdays.contains(weekday)) {
      if (reviewReminderWeekdays.length > 1) {
        reviewReminderWeekdays.remove(weekday);
      }
    } else {
      reviewReminderWeekdays.add(weekday);
    }
    _saveIntSet('reviewReminderWeekdays', reviewReminderWeekdays);
    unawaited(NotificationService.instance.syncReviewSchedule(
      enabled: reviewReminderEnabled,
      hour: reviewReminderHour,
      minute: reviewReminderMinute,
      weekdays: reviewReminderWeekdays,
      dueCount: dueKanjiReviewCount,
    ));
    notifyListeners();
  }

  void setCalendarReminderEnabled(bool enabled) {
    calendarReminderEnabled = enabled;
    _preferences?.setBool('calendarReminderEnabled', enabled);
    notifyListeners();
  }

  String generateKanjiReminderIcs() {
    final now = DateTime.now();
    final byDay = {
      1: 'MO',
      2: 'TU',
      3: 'WE',
      4: 'TH',
      5: 'FR',
      6: 'SA',
      7: 'SU',
    };
    final days = reviewReminderWeekdays.toList()..sort();
    final first = DateTime(
      now.year,
      now.month,
      now.day,
      reviewReminderHour,
      reviewReminderMinute,
    );
    String stamp(DateTime date) => '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}T'
        '${date.hour.toString().padLeft(2, '0')}'
        '${date.minute.toString().padLeft(2, '0')}00';
    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Belajar Bahasa Jepang//Ulangan Kanji//ID',
      'BEGIN:VEVENT',
      'UID:ulangan-kanji-${now.millisecondsSinceEpoch}@belajar-bahasa-jepang',
      'DTSTAMP:${stamp(now)}',
      'DTSTART:${stamp(first)}',
      'RRULE:FREQ=WEEKLY;BYDAY=${days.map((d) => byDay[d]).whereType<String>().join(',')}',
      'SUMMARY:Ulangan Kanji Belajar Bahasa Jepang',
      'DESCRIPTION:Buka aplikasi dan ulangi kanji yang sudah waktunya dipelajari kembali.',
      'END:VEVENT',
      'END:VCALENDAR',
    ].join('\n');
  }

  void dismissReviewReminderForToday() {
    lastReminderDismissDate = _dateKey(DateTime.now());
    _preferences?.setString(
      'lastReminderDismissDate',
      lastReminderDismissDate,
    );
    notifyListeners();
  }

  void toggleFavoriteKanji(int id) {
    if (!favoriteKanjiIds.remove(id)) favoriteKanjiIds.add(id);
    _saveIntSet('favoriteKanji', favoriteKanjiIds);
    notifyListeners();
  }

  void toggleLearnedKanji(int id) {
    if (!learnedKanjiIds.remove(id)) {
      learnedKanjiIds.add(id);
      recordStudy(xpGained: 5, notify: false);
    }
    _saveIntSet('learnedKanji', learnedKanjiIds);
    notifyListeners();
  }

  int kanjiMasteryStreak(int id) => masteredKanjiIds.contains(id)
      ? kanjiMasteryThreshold
      : (kanjiMasteryStreaks[id] ?? 0).clamp(0, kanjiMasteryThreshold).toInt();

  bool isKanjiMastered(int id) => masteredKanjiIds.contains(id);

  bool isKanjiReviewDue(int id) {
    final reviewDay = kanjiNextReviewDays[id];
    return masteredKanjiIds.contains(id) &&
        reviewDay != null &&
        reviewDay <= _epochDay(DateTime.now());
  }

  List<int> get dueKanjiReviewIds {
    final today = _epochDay(DateTime.now());
    final ids = kanjiNextReviewDays.entries
        .where(
          (entry) =>
              masteredKanjiIds.contains(entry.key) && entry.value <= today,
        )
        .map((entry) => entry.key)
        .toList();
    ids.sort((a, b) {
      final dateCompare =
          (kanjiNextReviewDays[a] ?? 0).compareTo(kanjiNextReviewDays[b] ?? 0);
      return dateCompare != 0 ? dateCompare : a.compareTo(b);
    });
    return ids;
  }

  int get dueKanjiReviewCount {
    final today = _epochDay(DateTime.now());
    var count = 0;
    for (final entry in kanjiNextReviewDays.entries) {
      if (masteredKanjiIds.contains(entry.key) && entry.value <= today) {
        count++;
      }
    }
    return count;
  }

  int get scheduledKanjiReviewCount => kanjiNextReviewDays.length;

  DateTime? get nextKanjiReviewDate {
    if (kanjiNextReviewDays.isEmpty) return null;
    final day = kanjiNextReviewDays.values.reduce(
      (current, next) => current < next ? current : next,
    );
    return _dateFromEpochDay(day);
  }

  KanjiMasteryResult recordKanjiMasteryAnswer({
    required int kanjiId,
    required bool correct,
  }) {
    quizAnswered++;
    if (correct) quizCorrect++;
    _preferences?.setInt('quizCorrect', quizCorrect);
    _preferences?.setInt('quizAnswered', quizAnswered);

    final previous = kanjiMasteryStreak(kanjiId);
    final next =
        correct ? (previous + 1).clamp(0, kanjiMasteryThreshold).toInt() : 0;
    final wasMastered = masteredKanjiIds.contains(kanjiId);
    final justMastered = !wasMastered && next >= kanjiMasteryThreshold;

    if (justMastered || wasMastered) {
      masteredKanjiIds.add(kanjiId);
      learnedKanjiIds.add(kanjiId);
      kanjiMasteryStreaks.remove(kanjiId);
    } else if (next == 0) {
      kanjiMasteryStreaks.remove(kanjiId);
    } else {
      kanjiMasteryStreaks[kanjiId] = next;
    }

    if (justMastered) {
      kanjiReviewSteps.remove(kanjiId);
      kanjiNextReviewDays[kanjiId] =
          _epochDay(DateTime.now()) + kanjiReviewIntervals.first;
      _saveIntSet('masteredKanji', masteredKanjiIds);
      _saveIntSet('learnedKanji', learnedKanjiIds);
      _scheduleReviewSave();
    }
    _saveIntMap('kanjiMasteryStreaks', kanjiMasteryStreaks);
    recordStudy(
      xpGained: correct ? (justMastered ? 25 : 5) : 0,
      notify: false,
    );
    notifyListeners();
    return KanjiMasteryResult(
      correct: correct,
      streak: kanjiMasteryStreak(kanjiId),
      mastered: masteredKanjiIds.contains(kanjiId),
      justMastered: justMastered,
    );
  }

  KanjiReviewResult recordKanjiReviewAnswer({
    required int kanjiId,
    required bool correct,
  }) {
    quizAnswered++;
    if (correct) quizCorrect++;
    _preferences?.setInt('quizCorrect', quizCorrect);
    _preferences?.setInt('quizAnswered', quizAnswered);

    final currentStep = kanjiReviewSteps[kanjiId] ?? 0;
    final nextStep = correct
        ? (currentStep + 1).clamp(0, kanjiReviewIntervals.length - 1).toInt()
        : 0;
    final intervalDays = correct ? kanjiReviewIntervals[nextStep] : 1;
    final nextReviewDay = _epochDay(DateTime.now()) + intervalDays;
    if (nextStep == 0) {
      kanjiReviewSteps.remove(kanjiId);
    } else {
      kanjiReviewSteps[kanjiId] = nextStep;
    }
    kanjiNextReviewDays[kanjiId] = nextReviewDay;
    _scheduleReviewSave();
    recordStudy(
      xpGained: correct ? 8 : 0,
      notify: false,
    );
    notifyListeners();
    return KanjiReviewResult(
      correct: correct,
      intervalDays: intervalDays,
      nextReviewDate: _dateFromEpochDay(nextReviewDay),
    );
  }

  void toggleMasteredVocabulary(int id) {
    if (!masteredVocabularyIds.remove(id)) {
      masteredVocabularyIds.add(id);
      recordStudy(xpGained: 3, notify: false);
    }
    _saveIntSet('masteredVocabulary', masteredVocabularyIds);
    notifyListeners();
  }

  void toggleGrammarComplete(String id) {
    if (!completedGrammarIds.remove(id)) {
      completedGrammarIds.add(id);
      recordStudy(xpGained: 8, notify: false);
    }
    _preferences?.setStringList(
      'completedGrammar',
      completedGrammarIds.toList(),
    );
    notifyListeners();
  }

  void completeLearningStep(String id) {
    if (completedLearningStepIds.add(id)) {
      _preferences?.setStringList(
          'completedLearningSteps', completedLearningStepIds.toList());
      final match = RegExp(r'^path-(n5|n4|n3|n2|n1)-(\d+)$').firstMatch(id);
      if (match != null) {
        final level = match.group(1)!.toUpperCase();
        final chapter = int.tryParse(match.group(2)!) ?? 0;
        final finalChapters = const {
          'N5': 25,
          'N4': 25,
          'N3': 20,
          'N2': 15,
          'N1': 14
        };
        if (chapter == finalChapters[level]) {
          completedLearningStepIds.add('level-${level.toLowerCase()}-final');
          const order = ['N5', 'N4', 'N3', 'N2', 'N1'];
          final index = order.indexOf(level);
          if (index >= 0 && index < order.length - 1)
            unlockedLevels.add(order[index + 1]);
          _preferences?.setStringList(
              'unlockedLevels', unlockedLevels.toList());
          _preferences?.setStringList(
              'completedLearningSteps', completedLearningStepIds.toList());
        }
      }
      recordStudy(xpGained: 10, notify: false);
      notifyListeners();
    }
  }

  void togglePhraseComplete(String id) {
    if (!completedPhraseIds.remove(id)) {
      completedPhraseIds.add(id);
      recordStudy(xpGained: 3, notify: false);
    }
    _preferences?.setStringList(
        'completedPhrases', completedPhraseIds.toList());
    notifyListeners();
  }

  void toggleSentenceComplete(String id) {
    if (!completedSentenceIds.remove(id)) {
      completedSentenceIds.add(id);
      recordStudy(xpGained: 4, notify: false);
    }
    _preferences?.setStringList(
      'completedSentences',
      completedSentenceIds.toList(),
    );
    notifyListeners();
  }

  void toggleCultureComplete(String id) {
    if (!completedCultureIds.remove(id)) {
      completedCultureIds.add(id);
      recordStudy(xpGained: 5, notify: false);
    }
    _preferences?.setStringList(
        'completedCulture', completedCultureIds.toList());
    notifyListeners();
  }

  void recordQuiz({required int correct, required int total}) {
    if (total <= 0) return;
    recordActivity('quiz', 'Kuis diselesaikan',
        meta: {'correct': correct, 'total': total});
    quizCorrect += correct;
    quizAnswered += total;
    _preferences?.setInt('quizCorrect', quizCorrect);
    _preferences?.setInt('quizAnswered', quizAnswered);
    recordStudy(
      xpGained: correct * 10 + (correct == total ? 20 : 0),
    );
  }

  String examKey(ExamType examType, String level, int stage) =>
      '${examType.name}::$level::$stage';

  void recordExamSimulation({
    required ExamType examType,
    required String level,
    required int stage,
    required int correct,
    required int total,
    required int points,
  }) {
    if (total <= 0) return;
    final score = (correct / total * 100).round().clamp(0, 100).toInt();
    final key = examKey(examType, level, stage);
    final previousBest = examBestScores[key] ?? 0;
    if (score > previousBest) {
      examBestScores[key] = score;
      _saveStringIntMap('examBestScores', examBestScores);
    }
    examPoints += points;
    _preferences?.setInt('examPoints', examPoints);
    recordQuiz(correct: correct, total: total);
  }

  void recordStudy({int xpGained = 2, bool notify = true}) {
    _refreshDailyCounter();
    final today = _dateKey(DateTime.now());
    if (lastStudyDate != today) {
      final yesterday = _dateKey(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      streak = lastStudyDate == yesterday ? streak + 1 : 1;
      lastStudyDate = today;
      studyDateKeys.add(today);
      _preferences?.setInt('streak', streak);
      _preferences?.setString('lastStudyDate', lastStudyDate);
      _preferences?.setStringList('studyDateKeys', studyDateKeys.toList());
    }
    xp += xpGained;
    dailyXp += xpGained;
    _preferences?.setInt('xp', xp);
    _preferences?.setInt('dailyXp', dailyXp);
    recordActivity('study', 'Aktivitas belajar', meta: {'xp': xpGained});
    unawaited(HomeWidgetService.instance
        .update(streak: streak, xp: xp, kanji: todayKanjiCharacter));
    markProgressDirty(const [
      'xp',
      'dailyXp',
      'streak',
      'lastStudyDate',
      'studyDateKeys',
      'activityJournal',
    ]);
    if (notify) notifyListeners();
  }

  Future<void> addBonusXp(int amount) async {
    if (amount <= 0) return;
    xp += amount;
    dailyXp += amount;
    _preferences?.setInt('xp', xp);
    _preferences?.setInt('dailyXp', dailyXp);
    recordActivity('reward', 'Bonus iklan', meta: {'xp': amount});
    markProgressDirty(const ['xp', 'dailyXp', 'activityJournal']);
    notifyListeners();
  }

  String exportProgress() => const JsonEncoder.withIndent('  ').convert({
        'format': 'japanese-study-progress-v1',
        'exportedAt': DateTime.now().toIso8601String(),
        'profileName': profileName,
        'profileEmail': profileEmail,
        'profilePhotoUrl': profilePhotoUrl,
        'profilePhotoData': profilePhotoData,
        'onboardingComplete': onboardingComplete,
        'studyGoal': studyGoal,
        'selfLevel': selfLevel,
        'dailyStudyMinutes': dailyStudyMinutes,
        'selectedStudyLevel': selectedStudyLevel,
        'learningMode': learningMode,
        'appLanguage': appLanguage,
        'ttsGender': ttsGender,
        'reviewIntervalDays': reviewIntervalDays,
        'googleLinked': googleLinked,
        'isPremium': isPremium,
        'membershipPlan': membershipPlan,
        'membershipTier': membershipTier,
        'unlockedLevels': unlockedLevels.toList(),
        'placementBestScores': placementBestScores,
        'isAuthenticated': isAuthenticated,
        'isAdmin': isAdmin,
        'activeRoadmapStepId': activeRoadmapStepId,
        'hasUnreadNotifications': hasUnreadNotifications,
        'reviewReminderEnabled': reviewReminderEnabled,
        'reviewReminderHour': reviewReminderHour,
        'reviewReminderMinute': reviewReminderMinute,
        'lastDriveBackupLabel': lastDriveBackupLabel,
        'xp': xp,
        'dailyXp': dailyXp,
        'streak': streak,
        'lastStudyDate': lastStudyDate,
        'studyDateKeys': studyDateKeys.toList()..sort(),
        'reviewReminderWeekdays': reviewReminderWeekdays.toList()..sort(),
        'calendarReminderEnabled': calendarReminderEnabled,
        'glassTheme': glassTheme,
        'todayKanjiMode': todayKanjiMode,
        'todayKanjiPinnedId': todayKanjiPinnedId,
        'firstUsedAt': firstUsedAt?.toIso8601String(),
        'totalActiveSeconds': totalActiveSeconds,
        'sessionCount': sessionCount,
        'activityJournal': activityJournal,
        'quizCorrect': quizCorrect,
        'quizAnswered': quizAnswered,
        'examPoints': examPoints,
        'examBestScores': examBestScores,
        'learnedKanji': learnedKanjiIds.toList()..sort(),
        'masteredKanji': masteredKanjiIds.toList()..sort(),
        'kanjiMasteryStreaks': {
          for (final entry in kanjiMasteryStreaks.entries)
            '${entry.key}': entry.value,
        },
        'kanjiReviewSteps': {
          for (final entry in kanjiReviewSteps.entries)
            '${entry.key}': entry.value,
        },
        'kanjiNextReviewDays': {
          for (final entry in kanjiNextReviewDays.entries)
            '${entry.key}': entry.value,
        },
        'favoriteKanji': favoriteKanjiIds.toList()..sort(),
        'masteredVocabulary': masteredVocabularyIds.toList()..sort(),
        'completedGrammar': completedGrammarIds.toList()..sort(),
        'completedLearningSteps': completedLearningStepIds.toList()..sort(),
        'completedPhrases': completedPhraseIds.toList()..sort(),
        'completedSentences': completedSentenceIds.toList()..sort(),
        'completedCulture': completedCultureIds.toList()..sort(),
      });

  Future<bool> importProgress(String source) async {
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      if (json['format'] != 'japanese-study-progress-v1') return false;
      profileName = (json['profileName'] as String?)?.trim().isNotEmpty == true
          ? (json['profileName'] as String).trim()
          : profileName;
      profileEmail = (json['profileEmail'] as String?)?.trim() ?? profileEmail;
      profilePhotoUrl =
          (json['profilePhotoUrl'] as String?)?.trim() ?? profilePhotoUrl;
      profilePhotoData =
          (json['profilePhotoData'] as String?) ?? profilePhotoData;
      onboardingComplete =
          json['onboardingComplete'] as bool? ?? onboardingComplete;
      studyGoal = (json['studyGoal'] as String?) ?? studyGoal;
      selfLevel = (json['selfLevel'] as String?) ?? selfLevel;
      dailyStudyMinutes =
          (json['dailyStudyMinutes'] as num? ?? dailyStudyMinutes)
              .toInt()
              .clamp(5, 180)
              .toInt();
      selectedStudyLevel =
          (json['selectedStudyLevel'] as String?) ?? selectedStudyLevel;
      learningMode = (json['learningMode'] as String?) ?? learningMode;
      appLanguage = (json['appLanguage'] as String?) ?? appLanguage;
      ttsGender = (json['ttsGender'] as String?) ?? ttsGender;
      reviewIntervalDays =
          ((json['reviewIntervalDays'] as num?) ?? reviewIntervalDays)
              .toInt()
              .clamp(1, 30)
              .toInt();
      googleLinked = json['googleLinked'] as bool? ?? googleLinked;
      isPremium = json['isPremium'] as bool? ?? isPremium;
      membershipPlan = (json['membershipPlan'] as String?) ??
          (json['membershipTier'] as String?) ??
          (isPremium ? 'premium' : 'free');
      if (!['free', 'premium', 'lifetime'].contains(membershipPlan))
        membershipPlan = 'free';
      membershipTier = membershipPlan == 'free' ? 'free' : 'premium';
      isPremium = membershipPlan != 'free';
      unlockedLevels
        ..clear()
        ..addAll((json['unlockedLevels'] as List<dynamic>? ?? const [])
            .whereType<String>());
      if (!unlockedLevels.contains('N5')) unlockedLevels.add('N5');
      placementBestScores
        ..clear()
        ..addAll((json['placementBestScores'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
            {});
      activeRoadmapStepId =
          (json['activeRoadmapStepId'] as String?) ?? activeRoadmapStepId;
      hasUnreadNotifications =
          json['hasUnreadNotifications'] as bool? ?? hasUnreadNotifications;
      reviewReminderEnabled =
          json['reviewReminderEnabled'] as bool? ?? reviewReminderEnabled;
      reviewReminderHour =
          (json['reviewReminderHour'] as num? ?? reviewReminderHour)
              .toInt()
              .clamp(0, 23)
              .toInt();
      reviewReminderMinute =
          (json['reviewReminderMinute'] as num? ?? reviewReminderMinute)
              .toInt()
              .clamp(0, 59)
              .toInt();
      lastDriveBackupLabel =
          (json['lastDriveBackupLabel'] as String?) ?? lastDriveBackupLabel;
      xp = (json['xp'] as num? ?? 0).toInt().clamp(0, 1 << 31).toInt();
      dailyXp = (json['dailyXp'] as num? ?? 0).toInt().clamp(0, 100000).toInt();
      streak = (json['streak'] as num? ?? 0).toInt().clamp(0, 100000).toInt();
      quizCorrect =
          (json['quizCorrect'] as num? ?? 0).toInt().clamp(0, 1 << 31).toInt();
      quizAnswered =
          (json['quizAnswered'] as num? ?? 0).toInt().clamp(0, 1 << 31).toInt();
      examPoints =
          (json['examPoints'] as num? ?? 0).toInt().clamp(0, 1 << 31).toInt();
      examBestScores
        ..clear()
        ..addAll(_jsonStringIntMap(json['examBestScores']));
      lastStudyDate = json['lastStudyDate'] as String? ?? '';
      studyDateKeys
        ..clear()
        ..addAll((json['studyDateKeys'] as List<dynamic>? ?? const [])
            .map((value) => '$value'));
      if (lastStudyDate.isNotEmpty) studyDateKeys.add(lastStudyDate);
      reviewReminderWeekdays
        ..clear()
        ..addAll(_jsonIntSet(json['reviewReminderWeekdays'])
            .where((day) => day >= 1 && day <= 7));
      if (reviewReminderWeekdays.isEmpty) {
        reviewReminderWeekdays.addAll({1, 2, 3, 4, 5, 6, 7});
      }
      calendarReminderEnabled =
          json['calendarReminderEnabled'] as bool? ?? calendarReminderEnabled;
      glassTheme = json['glassTheme'] as bool? ?? glassTheme;
      todayKanjiMode = (json['todayKanjiMode'] as String?) ?? todayKanjiMode;
      todayKanjiPinnedId =
          (json['todayKanjiPinnedId'] as num? ?? todayKanjiPinnedId).toInt();
      final importedFirstUsed = json['firstUsedAt'] as String?;
      if (importedFirstUsed != null)
        firstUsedAt = DateTime.tryParse(importedFirstUsed);
      totalActiveSeconds =
          (json['totalActiveSeconds'] as num? ?? totalActiveSeconds)
              .toInt()
              .clamp(0, 1 << 31)
              .toInt();
      sessionCount = (json['sessionCount'] as num? ?? sessionCount)
          .toInt()
          .clamp(0, 1000000)
          .toInt();
      activityJournal
        ..clear()
        ..addAll((json['activityJournal'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, Object?>.from(e))
            .take(2000));
      learnedKanjiIds
        ..clear()
        ..addAll(
          _jsonIntSet(json['learnedKanji'])
              .where((id) => repository.kanjiById(id) != null),
        );
      masteredKanjiIds
        ..clear()
        ..addAll(
          _jsonIntSet(json['masteredKanji'])
              .where((id) => repository.kanjiById(id) != null),
        );
      kanjiMasteryStreaks
        ..clear()
        ..addAll(
          _jsonIntMap(json['kanjiMasteryStreaks'])
            ..removeWhere((id, _) => repository.kanjiById(id) == null),
        );
      kanjiReviewSteps
        ..clear()
        ..addAll(
          _jsonIntMap(json['kanjiReviewSteps'])
            ..removeWhere((id, _) => repository.kanjiById(id) == null),
        );
      kanjiNextReviewDays
        ..clear()
        ..addAll(
          _jsonIntMap(json['kanjiNextReviewDays'])
            ..removeWhere((id, _) => repository.kanjiById(id) == null),
        );
      final today = _epochDay(DateTime.now());
      for (final id in masteredKanjiIds) {
        kanjiMasteryStreaks.remove(id);
        learnedKanjiIds.add(id);
        kanjiNextReviewDays.putIfAbsent(
          id,
          () => today + kanjiReviewIntervals.first,
        );
      }
      kanjiReviewSteps.removeWhere((id, _) => !masteredKanjiIds.contains(id));
      kanjiNextReviewDays
          .removeWhere((id, _) => !masteredKanjiIds.contains(id));
      favoriteKanjiIds
        ..clear()
        ..addAll(
          _jsonIntSet(json['favoriteKanji'])
              .where((id) => repository.kanjiById(id) != null),
        );
      masteredVocabularyIds
        ..clear()
        ..addAll(
          _jsonIntSet(json['masteredVocabulary'])
              .where((id) => repository.vocabularyById(id) != null),
        );
      final grammarIds = repository.grammar.map((item) => item.id).toSet();
      completedGrammarIds
        ..clear()
        ..addAll(
          (json['completedGrammar'] as List<dynamic>? ?? const [])
              .map((value) => '$value')
              .where(grammarIds.contains),
        );
      completedLearningStepIds
        ..clear()
        ..addAll(
          (json['completedLearningSteps'] as List<dynamic>? ?? const [])
              .map((value) => '$value'),
        );
      completedPhraseIds
        ..clear()
        ..addAll(
          (json['completedPhrases'] as List<dynamic>? ?? const [])
              .map((value) => '$value'),
        );
      completedSentenceIds
        ..clear()
        ..addAll(
          (json['completedSentences'] as List<dynamic>? ?? const [])
              .map((value) => '$value'),
        );
      completedCultureIds
        ..clear()
        ..addAll(
          (json['completedCulture'] as List<dynamic>? ?? const [])
              .map((value) => '$value'),
        );
      final prefs = _preferences;
      if (prefs != null) {
        await Future.wait([
          prefs.setString('profileName', profileName),
          prefs.setString('profileEmail', profileEmail),
          prefs.setString('profilePhotoUrl', profilePhotoUrl),
          prefs.setString('profilePhotoData', profilePhotoData),
          prefs.setBool('onboardingComplete', onboardingComplete),
          prefs.setString('studyGoal', studyGoal),
          prefs.setString('selfLevel', selfLevel),
          prefs.setInt('dailyStudyMinutes', dailyStudyMinutes),
          prefs.setString('selectedStudyLevel', selectedStudyLevel),
          prefs.setString('learningMode', learningMode),
          prefs.setBool('googleLinked', googleLinked),
          prefs.setBool('isPremium', isPremium),
          prefs.setString('membershipPlan', membershipPlan),
          prefs.setString('membershipTier', membershipTier),
          prefs.setString('activeRoadmapStepId', activeRoadmapStepId),
          prefs.setBool('hasUnreadNotifications', hasUnreadNotifications),
          prefs.setBool('reviewReminderEnabled', reviewReminderEnabled),
          prefs.setInt('reviewReminderHour', reviewReminderHour),
          prefs.setInt('reviewReminderMinute', reviewReminderMinute),
          prefs.setString('lastDriveBackupLabel', lastDriveBackupLabel),
          prefs.setInt('xp', xp),
          prefs.setInt('dailyXp', dailyXp),
          prefs.setInt('streak', streak),
          prefs.setInt('quizCorrect', quizCorrect),
          prefs.setInt('quizAnswered', quizAnswered),
          prefs.setInt('examPoints', examPoints),
          prefs.setString('examBestScores', jsonEncode(examBestScores)),
          prefs.setString('lastStudyDate', lastStudyDate),
          prefs.setStringList('studyDateKeys', studyDateKeys.toList()),
          prefs.setStringList(
            'reviewReminderWeekdays',
            reviewReminderWeekdays.map((day) => '$day').toList(),
          ),
          prefs.setBool('calendarReminderEnabled', calendarReminderEnabled),
          prefs.setStringList(
            'learnedKanji',
            learnedKanjiIds.map((id) => '$id').toList(),
          ),
          prefs.setStringList(
            'masteredKanji',
            masteredKanjiIds.map((id) => '$id').toList(),
          ),
          prefs.setString(
            'kanjiMasteryStreaks',
            jsonEncode({
              for (final entry in kanjiMasteryStreaks.entries)
                '${entry.key}': entry.value,
            }),
          ),
          prefs.setString(
            'kanjiReviewSteps',
            jsonEncode({
              for (final entry in kanjiReviewSteps.entries)
                '${entry.key}': entry.value,
            }),
          ),
          prefs.setString(
            'kanjiNextReviewDays',
            jsonEncode({
              for (final entry in kanjiNextReviewDays.entries)
                '${entry.key}': entry.value,
            }),
          ),
          prefs.setStringList(
            'favoriteKanji',
            favoriteKanjiIds.map((id) => '$id').toList(),
          ),
          prefs.setStringList(
            'masteredVocabulary',
            masteredVocabularyIds.map((id) => '$id').toList(),
          ),
          prefs.setStringList(
            'completedGrammar',
            completedGrammarIds.toList(),
          ),
          prefs.setStringList(
            'completedLearningSteps',
            completedLearningStepIds.toList(),
          ),
          prefs.setStringList(
            'completedPhrases',
            completedPhraseIds.toList(),
          ),
          prefs.setStringList(
            'completedSentences',
            completedSentenceIds.toList(),
          ),
          prefs.setStringList(
            'completedCulture',
            completedCultureIds.toList(),
          ),
        ]);
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mulai dari nol: bersihkan lokal DAN dokumen server.
  ///
  /// Hapus lokal saja tidak cukup — merge union/max akan mengisi ulang
  /// lokal dari data lama di server saat sync berikutnya. Mengembalikan
  /// true bila lokal bersih (server ikut terhapus bila sedang login).
  Future<bool> resetProgress() async {
    _reviewSaveTimer?.cancel();
    xp = 0;
    dailyXp = 0;
    streak = 0;
    quizCorrect = 0;
    quizAnswered = 0;
    examPoints = 0;
    examBestScores.clear();
    lastStudyDate = '';
    studyDateKeys.clear();
    learnedKanjiIds.clear();
    masteredKanjiIds.clear();
    kanjiMasteryStreaks.clear();
    kanjiReviewSteps.clear();
    kanjiNextReviewDays.clear();
    favoriteKanjiIds.clear();
    masteredVocabularyIds.clear();
    completedGrammarIds.clear();
    completedLearningStepIds.clear();
    completedPhraseIds.clear();
    completedSentenceIds.clear();
    completedCultureIds.clear();
    final prefs = _preferences;
    if (prefs != null) {
      for (final key in [
        'xp',
        'dailyXp',
        'streak',
        'quizCorrect',
        'quizAnswered',
        'examPoints',
        'examBestScores',
        'lastStudyDate',
        'studyDateKeys',
        'learnedKanji',
        'masteredKanji',
        'kanjiMasteryStreaks',
        'kanjiReviewSteps',
        'kanjiNextReviewDays',
        'favoriteKanji',
        'masteredVocabulary',
        'completedGrammar',
        'completedLearningSteps',
        'completedPhrases',
        'completedSentences',
        'completedCulture',
        'progressFieldUpdatedAt',
        'lastCloudSyncAt',
      ]) {
        await prefs.remove(key);
      }
    }
    _fieldUpdatedAt.clear();
    // Hapus juga salinan server supaya sync berikutnya tidak mengisi ulang
    // lokal dari data lama.
    final uid = _currentUidOrNull();
    if (uid != null && uid.isNotEmpty && _syncAvailable) {
      final ok = await syncService.deleteRemote(uid);
      if (!ok) {
        syncStatus = 'error';
        lastSyncError = syncService.lastError;
        notifyListeners();
        return false;
      }
      syncStatus = 'idle';
    }
    notifyListeners();
    return true;
  }

  Map<String, int> _readStringIntMap(String key) {
    final value = _preferences?.getString(key);
    if (value == null || value.isEmpty) return {};
    try {
      return _jsonStringIntMap(jsonDecode(value));
    } catch (_) {
      return {};
    }
  }

  Map<String, int> _jsonStringIntMap(dynamic value) {
    if (value is! Map) return {};
    final output = <String, int>{};
    for (final entry in value.entries) {
      final score = entry.value is num
          ? (entry.value as num).toInt()
          : int.tryParse('${entry.value}');
      if (score != null) {
        output['${entry.key}'] = score.clamp(0, 100).toInt();
      }
    }
    return output;
  }

  void _saveStringIntMap(String key, Map<String, int> values) {
    _preferences?.setString(key, jsonEncode(values));
    markProgressDirty([key]);
  }

  Set<int> _readIntSet(String key) =>
      (_preferences?.getStringList(key) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

  Set<int> _jsonIntSet(dynamic value) => (value as List<dynamic>? ?? const [])
      .map((item) => item is num ? item.toInt() : int.tryParse('$item'))
      .whereType<int>()
      .toSet();

  Map<int, int> _readIntMap(String key) {
    final value = _preferences?.getString(key);
    if (value == null || value.isEmpty) return {};
    try {
      return _jsonIntMap(jsonDecode(value));
    } catch (_) {
      return {};
    }
  }

  Map<int, int> _jsonIntMap(dynamic value) {
    if (value is! Map) return {};
    final output = <int, int>{};
    for (final entry in value.entries) {
      final id = int.tryParse('${entry.key}');
      final streak = entry.value is num
          ? (entry.value as num).toInt()
          : int.tryParse('${entry.value}');
      if (id != null && streak != null && streak > 0) {
        output[id] = streak;
      }
    }
    return output;
  }

  void _saveIntSet(String key, Set<int> values) {
    _preferences?.setStringList(
      key,
      values.map((e) => '$e').toList(growable: false),
    );
    markProgressDirty([key]);
  }

  void _saveIntMap(String key, Map<int, int> values) {
    _preferences?.setString(
      key,
      jsonEncode({
        for (final entry in values.entries) '${entry.key}': entry.value,
      }),
    );
    markProgressDirty([key]);
  }

  void _scheduleReviewSave() {
    _reviewSaveTimer?.cancel();
    _reviewSaveTimer = Timer(
      const Duration(milliseconds: 850),
      _saveReviewSchedule,
    );
  }

  void flushPendingPersistence() {
    if (_reviewSaveTimer?.isActive != true) return;
    _reviewSaveTimer?.cancel();
    _saveReviewSchedule();
  }

  void _saveReviewSchedule() {
    _reviewSaveTimer?.cancel();
    _saveIntMap('kanjiReviewSteps', kanjiReviewSteps);
    _saveIntMap('kanjiNextReviewDays', kanjiNextReviewDays);
    markProgressDirty(const [
      'kanjiMasteryStreaks',
      'kanjiReviewSteps',
      'kanjiNextReviewDays',
      'learnedKanji',
      'masteredKanji',
      'xp',
    ]);
  }

  void _refreshDailyCounter() {
    final today = _dateKey(DateTime.now());
    if (lastStudyDate.isNotEmpty && lastStudyDate != today) {
      dailyXp = 0;
      _preferences?.setInt('dailyXp', 0);
    }
  }

  DateTime? _readDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  int _epochDay(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  DateTime _dateFromEpochDay(int day) {
    final utc = DateTime.fromMillisecondsSinceEpoch(
      day * Duration.millisecondsPerDay,
      isUtc: true,
    );
    return DateTime(utc.year, utc.month, utc.day);
  }
}

class KanjiMasteryResult {
  const KanjiMasteryResult({
    required this.correct,
    required this.streak,
    required this.mastered,
    required this.justMastered,
  });

  final bool correct;
  final int streak;
  final bool mastered;
  final bool justMastered;
}

class KanjiReviewResult {
  const KanjiReviewResult({
    required this.correct,
    required this.intervalDays,
    required this.nextReviewDate,
  });

  final bool correct;
  final int intervalDays;
  final DateTime nextReviewDate;
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(result != null, 'AppScope tidak ditemukan.');
    return result!.notifier!;
  }
}
