import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server_config.dart';

class AdminAnalyticsData {
  final int totalUsers;
  final int totalAdmins;
  final int totalPosts;
  final int totalComments;
  final int openReports;
  final int totalAnnouncements;
  final int totalVocabularies;
  final int kanji;
  final int vocabularyContent;
  final int grammar;
  final int phrases;
  final int sentences;
  final int culture;
  final int readings;
  final List<ChartPoint> registrations;
  final List<ChartPoint> logins;
  final List<ActionCount> events;
  final List<RoleCount> roles;
  final List<LevelCount> contentByLevel;
  final List<ActivityItem> recentActivities;
  final List<DashboardUser> dashboardUsers;

  AdminAnalyticsData({
    required this.totalUsers,
    required this.totalAdmins,
    required this.totalPosts,
    required this.totalComments,
    required this.openReports,
    required this.totalAnnouncements,
    required this.totalVocabularies,
    required this.kanji,
    required this.vocabularyContent,
    required this.grammar,
    required this.phrases,
    required this.sentences,
    required this.culture,
    required this.readings,
    required this.registrations,
    required this.logins,
    required this.events,
    required this.roles,
    required this.contentByLevel,
    required this.recentActivities,
    required this.dashboardUsers,
  });

  int get totalContent => kanji + vocabularyContent + grammar + phrases + sentences + culture + readings;

  factory AdminAnalyticsData.empty() => AdminAnalyticsData(
    totalUsers: 0, totalAdmins: 0, totalPosts: 0, totalComments: 0,
    openReports: 0, totalAnnouncements: 0, totalVocabularies: 0,
    kanji: 0, vocabularyContent: 0, grammar: 0, phrases: 0,
    sentences: 0, culture: 0, readings: 0,
    registrations: [], logins: [], events: [], roles: [],
    contentByLevel: [], recentActivities: [], dashboardUsers: [],
  );

  factory AdminAnalyticsData.fromJson(Map<String, dynamic> j) {
    final totals = j['totals'] ?? {};
    final series = j['series'] ?? {};
    final contentByType = totals['content'] ?? {};
    return AdminAnalyticsData(
      totalUsers: (totals['users'] as num?)?.toInt() ?? 0,
      totalAdmins: (totals['admins'] as num?)?.toInt() ?? 0,
      totalPosts: (totals['posts'] as num?)?.toInt() ?? 0,
      totalComments: (totals['comments'] as num?)?.toInt() ?? 0,
      openReports: (totals['openReports'] as num?)?.toInt() ?? 0,
      totalAnnouncements: (totals['announcements'] as num?)?.toInt() ?? 0,
      totalVocabularies: (totals['vocabularies'] as num?)?.toInt() ?? 0,
      kanji: (contentByType['kanji'] as num?)?.toInt() ?? 0,
      vocabularyContent: (contentByType['vocabulary'] as num?)?.toInt() ?? 0,
      grammar: (contentByType['grammar'] as num?)?.toInt() ?? 0,
      phrases: (contentByType['phrases'] as num?)?.toInt() ?? 0,
      sentences: (contentByType['sentences'] as num?)?.toInt() ?? 0,
      culture: (contentByType['culture'] as num?)?.toInt() ?? 0,
      readings: (contentByType['readings'] as num?)?.toInt() ?? 0,
      registrations: (series['registrations'] as List? ?? []).map((e) => ChartPoint.fromJson(e)).toList(),
      logins: (series['logins'] as List? ?? []).map((e) => ChartPoint.fromJson(e)).toList(),
      events: (series['events'] as List? ?? []).map((e) => ActionCount.fromJson(e)).toList(),
      roles: (j['roles'] as List? ?? []).map((e) => RoleCount.fromJson(e)).toList(),
      contentByLevel: (j['contentByLevel'] as List? ?? []).map((e) => LevelCount.fromJson(e)).toList(),
      recentActivities: (j['recentActivities'] as List? ?? []).map((e) => ActivityItem.fromJson(e)).toList(),
      dashboardUsers: (j['dashboardUsers'] as List? ?? []).map((e) => DashboardUser.fromJson(e)).toList(),
    );
  }
}

class ChartPoint {
  final String day;
  final int count;
  ChartPoint({required this.day, required this.count});
  factory ChartPoint.fromJson(Map<String, dynamic> j) => ChartPoint(
    day: j['day'] as String? ?? '',
    count: (j['count'] as num?)?.toInt() ?? (j['c'] as num?)?.toInt() ?? 0,
  );
}

class ActionCount {
  final String action;
  final int count;
  ActionCount({required this.action, required this.count});
  factory ActionCount.fromJson(Map<String, dynamic> j) => ActionCount(
    action: j['action'] as String? ?? '',
    count: (j['count'] as num?)?.toInt() ?? (j['c'] as num?)?.toInt() ?? 0,
  );
}

class RoleCount {
  final String role;
  final int count;
  RoleCount({required this.role, required this.count});
  factory RoleCount.fromJson(Map<String, dynamic> j) => RoleCount(
    role: j['role'] as String? ?? '',
    count: (j['count'] as num?)?.toInt() ?? (j['c'] as num?)?.toInt() ?? 0,
  );
}

class LevelCount {
  final String level;
  final int total;
  LevelCount({required this.level, required this.total});
  factory LevelCount.fromJson(Map<String, dynamic> j) => LevelCount(
    level: j['level'] as String? ?? '',
    total: (j['total'] as num?)?.toInt() ?? (j['c'] as num?)?.toInt() ?? 0,
  );
}

class ActivityItem {
  final String id;
  final String label;
  final String type;
  final DateTime? createdAt;
  ActivityItem({required this.id, required this.label, required this.type, this.createdAt});
  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
    id: j['id'] as String? ?? '',
    label: j['label'] as String? ?? '',
    type: j['type'] as String? ?? 'system',
    createdAt: DateTime.tryParse(j['created_at'] as String? ?? j['createdAt'] as String? ?? ''),
  );
}

class DashboardUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool online;
  DashboardUser({required this.id, required this.name, required this.email, required this.role, required this.online});
  factory DashboardUser.fromJson(Map<String, dynamic> j) => DashboardUser(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    email: j['email'] as String? ?? '',
    role: j['role'] as String? ?? 'user',
    online: j['online'] == true,
  );
}

class AdminAnalyticsService {
  AdminAnalyticsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const baseUrl = serverBaseUrl;
  static const token = String.fromEnvironment('API_ADMIN_TOKEN', defaultValue: serverAdminToken);

  bool get configured => baseUrl.trim().isNotEmpty;

  Uri _uri(String path) {
    final root = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$root/$path');
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (token.trim().isNotEmpty) 'Authorization': 'Bearer ${token.trim()}',
  };

  Future<AdminAnalyticsData> fetchAnalytics() async {
    if (!configured) return AdminAnalyticsData.empty();
    try {
      final r = await _client.get(_uri('/api/admin/analytics'), headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return AdminAnalyticsData.empty();
      final body = jsonDecode(r.body);
      if (body is Map<String, dynamic> && body['ok'] == true) {
        return AdminAnalyticsData.fromJson(body);
      }
      return AdminAnalyticsData.empty();
    } catch (_) {
      return AdminAnalyticsData.empty();
    }
  }
}
