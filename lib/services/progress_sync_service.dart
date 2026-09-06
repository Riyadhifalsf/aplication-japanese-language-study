import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_bootstrap.dart';

/// Sinkronisasi progress offline-online via Firestore.
///
/// Desain:
/// - Lokal (SharedPreferences via AppController) tetap sumber utama saat
///   offline agar aplikasi bisa dipakai tanpa internet.
/// - Firestore `users/{uid}/progress/main` jadi sumber online.
/// - Setiap push/pull memakai merge per-field (bukan timpa utuh):
///   counter -> max, set -> union, best-score -> max per key,
///   config -> last-write-wins, journal -> gabung + cap.
/// - `fieldUpdatedAt` menyimpan waktu update per field untuk LWW yang adil.
/// - Gagal jaringan -> tandai pending, coba lagi (debounce + manual sync).
class ProgressSyncService {
  ProgressSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  Timer? _debounce;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  bool syncPending = false;
  DateTime? lastSyncAt;
  String? lastError;

  static const docPath = 'main';

  bool get isAvailable => FirebaseBootstrap.isAvailable;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid).collection('progress').doc(docPath);

  /// Gabung dua snapshot progress. [localUpdatedAt]/[remoteUpdatedAt] berisi
  /// epoch-ms per field bila ada.
  static Map<String, dynamic> merge(
    Map<String, dynamic> local,
    Map<String, dynamic> remote, {
    Map<String, int>? localUpdatedAt,
    Map<String, int>? remoteUpdatedAt,
  }) {
    final l = Map<String, dynamic>.from(local);
    final r = Map<String, dynamic>.from(remote);
    final lu = localUpdatedAt ?? const {};
    final ru = remoteUpdatedAt ?? const {};
    final out = <String, dynamic>{};

    int maxNum(String key) {
      final a = (l[key] as num?) ?? 0;
      final b = (r[key] as num?) ?? 0;
      return (a >= b ? a : b).toInt();
    }

    List<dynamic> unionList(String key) {
      final set = <Object?>{};
      for (final v in (l[key] as List? ?? const [])) {
        set.add(v);
      }
      for (final v in (r[key] as List? ?? const [])) {
        set.add(v);
      }
      final list = set.toList();
      // Sort bila comparable untuk hasil stabil.
      try {
        list.sort((a, b) => '$a'.compareTo('$b'));
      } catch (_) {}
      return list;
    }

    Map<String, dynamic> maxMap(String key) {
      final a = (l[key] as Map?) ?? const {};
      final b = (r[key] as Map?) ?? const {};
      final keys = <String>{...a.keys.map((e) => '$e'), ...b.keys.map((e) => '$e')};
      final merged = <String, dynamic>{};
      for (final k in keys) {
        final av = (a[k] as num?) ?? (a[int.tryParse(k)] as num?);
        final bv = (b[k] as num?) ?? (b[int.tryParse(k)] as num?);
        final best = ((av ?? 0) >= (bv ?? 0) ? av : bv) ?? 0;
        merged[k] = (best as num).toInt();
      }
      return merged;
    }

    dynamic lastWriteWins(String key, dynamic fallback) {
      final lt = lu[key] ?? 0;
      final rt = ru[key] ?? 0;
      if (rt > lt) return r.containsKey(key) ? r[key] : fallback;
      if (lt >= rt && l.containsKey(key)) return l[key];
      return r.containsKey(key) ? r[key] : fallback;
    }

    // Counter: ambil yang terbesar agar XP tidak hilang saat ganti HP.
    for (final k in ['xp', 'dailyXp', 'streak', 'quizCorrect', 'quizAnswered', 'examPoints', 'totalActiveSeconds', 'sessionCount']) {
      out[k] = maxNum(k);
    }

    // Set ID: union.
    for (final k in ['learnedKanji', 'masteredKanji', 'favoriteKanji', 'masteredVocabulary', 'completedGrammar', 'completedLearningSteps', 'completedPhrases', 'completedSentences', 'completedCulture', 'unlockedLevels', 'studyDateKeys']) {
      out[k] = unionList(k);
    }

    // Best score / SRS: max per key.
    for (final k in ['placementBestScores', 'examBestScores', 'kanjiMasteryStreaks', 'kanjiReviewSteps', 'kanjiNextReviewDays']) {
      out[k] = maxMap(k);
    }

    // Config/profil: last-write-wins.
    for (final k in ['profileName', 'profileEmail', 'profilePhotoUrl', 'onboardingComplete', 'studyGoal', 'selfLevel', 'dailyStudyMinutes', 'selectedStudyLevel', 'learningMode', 'appLanguage', 'ttsGender', 'reviewIntervalDays', 'membershipPlan', 'membershipTier', 'activeRoadmapStepId', 'lastStudyDate', 'todayKanjiMode', 'todayKanjiPinnedId']) {
      out[k] = lastWriteWins(k, l[k] ?? r[k]);
    }

    // Journal: gabung unik по id/waktu, cap 2000 terbaru.
    final journal = <String, Map<String, Object?>>{};
    for (final src in [l['activityJournal'], r['activityJournal']]) {
      for (final e in (src as List? ?? const []).whereType<Map>()) {
        final m = Map<String, Object?>.from(e);
        final key = '${m['id'] ?? m['at'] ?? m.hashCode}';
        journal[key] = m;
      }
    }
    final journalList = journal.values.toList()
      ..sort((a, b) => '${b['at'] ?? ''}'.compareTo('${a['at'] ?? ''}'));
    out['activityJournal'] = journalList.take(2000).toList();

    out['updatedAt'] = DateTime.now().toIso8601String();
    return out;
  }

  static Map<String, int> _fieldTimes(Map<String, dynamic>? raw) {
    final out = <String, int>{};
    if (raw == null) return out;
    raw.forEach((k, v) {
      if (v is num) out[k] = v.toInt();
    });
    return out;
  }

  /// Hapus dokumen progress server agar mulai benar-benar dari nol.
  ///
  /// Penting: merge memakai union/max sehingga TIDAK BISA menghapus lewat
  /// push data kosong — dokumen server harus dihapus eksplisit, kalau tidak
  /// sync berikutnya akan mengisi ulang lokal dari data lama.
  Future<bool> deleteRemote(String uid) async {
    if (!isAvailable) {
      lastError = 'Firebase belum dikonfigurasi.';
      return false;
    }
    try {
      await _doc(uid).delete();
      lastError = null;
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  Future<Map<String, dynamic>?> pullRemote(String uid) async {
    if (!isAvailable) return null;
    try {
      final snap = await _doc(uid).get();
      lastError = null;
      return snap.data();
    } catch (e) {
      lastError = e.toString();
      return null;
    }
  }

  Future<bool> pushLocal(String uid, Map<String, dynamic> localData, {Map<String, int>? fieldUpdatedAt}) async {
    if (!isAvailable) {
      syncPending = true;
      return false;
    }
    try {
      final remote = await _doc(uid).get();
      final remoteData = remote.data() ?? {};
      final merged = merge(
        localData,
        (remoteData['data'] as Map?)?.map((k, v) => MapEntry('$k', v)) ?? {},
        localUpdatedAt: fieldUpdatedAt,
        remoteUpdatedAt: _fieldTimes((remoteData['fieldUpdatedAt'] as Map?)?.map((k, v) => MapEntry('$k', v))),
      );
      await _doc(uid).set({
        'data': merged,
        'fieldUpdatedAt': {
          ..._fieldTimes((remoteData['fieldUpdatedAt'] as Map?)?.map((k, v) => MapEntry('$k', v))),
          ...(fieldUpdatedAt ?? {}),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      lastSyncAt = DateTime.now();
      syncPending = false;
      lastError = null;
      return true;
    } catch (e) {
      lastError = e.toString();
      syncPending = true;
      return false;
    }
  }

  /// Jadwalkan push dengan debounce agar tiap ada perubahan lokal tidak
  /// langsung spam Firestore. Cocok untuk "sinkronisasi terus".
  void schedulePush(Future<void> Function() push, {Duration delay = const Duration(seconds: 3)}) {
    _debounce?.cancel();
    _debounce = Timer(delay, () async {
      try {
        await push();
      } catch (e) {
        lastError = e.toString();
        syncPending = true;
      }
    });
  }

  /// Dengarkan perubahan remote agar dua HP online bisa saling update.
  void listenRemote(String uid, void Function(Map<String, dynamic> remoteData) onRemote) {
    if (!isAvailable) return;
    _subscription?.cancel();
    _subscription = _doc(uid).snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final inner = (data['data'] as Map?)?.map((k, v) => MapEntry('$k', v)) ?? {};
      onRemote(Map<String, dynamic>.from(inner));
    }, onError: (Object e) {
      lastError = e.toString();
    });
  }

  Future<void> dispose() async {
    _debounce?.cancel();
    await _subscription?.cancel();
  }
}
