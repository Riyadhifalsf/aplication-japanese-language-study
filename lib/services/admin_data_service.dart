import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/server_config.dart';
import '../models/admin_models.dart';

class AdminDataService {
  AdminDataService({http.Client? client}) : _client = client ?? http.Client();

  static const _usersKey = 'admin_users_v1';
  static const _postsKey = 'admin_posts_v1';
  static const _commentsKey = 'admin_comments_v1';
  static const _reportsKey = 'admin_reports_v1';
  static const _activitiesKey = 'admin_activities_v1';
  static const _announcementsKey = 'admin_announcements_v1';
  static const _opTimeout = Duration(seconds: 5);

  final http.Client _client;
  bool _serverSynced = false;

  final List<AdminUser> users = [];
  final List<CommunityPost> posts = [];
  final List<AdminComment> comments = [];
  final List<ComplaintReport> reports = [];
  final List<AdminActivity> activities = [];
  final List<AdminAnnouncement> announcements = [];

  bool get _hasServer => serverAdminToken.isNotEmpty;

  Uri _dataUri([String suffix = '']) {
    final root = serverBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final path = suffix.isEmpty ? '' : '/$suffix';
    return Uri.parse('$root/data$path');
  }

  Map<String, String> _headers({bool json = true}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (serverAdminToken.isNotEmpty)
          'Authorization': 'Bearer $serverAdminToken',
      };

  Future<void> load() async {
    if (!_serverSynced) {
      _serverSynced = await _syncFromServer();
      if (_serverSynced) {
        await _persist(await SharedPreferences.getInstance());
        return;
      }
    }
    final p = await SharedPreferences.getInstance();
    users..clear()..addAll(_read(p, _usersKey, AdminUser.fromJson));
    posts..clear()..addAll(_read(p, _postsKey, CommunityPost.fromJson));
    comments..clear()..addAll(_read(p, _commentsKey, AdminComment.fromJson));
    reports..clear()..addAll(_read(p, _reportsKey, ComplaintReport.fromJson));
    activities..clear()..addAll(_read(p, _activitiesKey, AdminActivity.fromJson));
    announcements
      ..clear()
      ..addAll(_read(p, _announcementsKey, AdminAnnouncement.fromJson));
    if (users.isEmpty) {
      users.add(AdminUser(id: 'u-admin', name: 'Administrator', email: 'admin@example.com', role: 'admin', level: 'N1', online: true, createdAt: DateTime.now()));
      users.add(AdminUser(id: 'u-001', name: 'User Pertama', email: 'user@example.com', role: 'user', level: 'N5', online: false, createdAt: DateTime.now()));
      await _persist(p);
    }
    if (activities.isEmpty) {
      activities.add(AdminActivity(id: _id(), label: 'Dashboard admin dibuat', type: 'system', createdAt: DateTime.now()));
      await _persist(p);
    }
  }

  /// Muat ulang paksa dari server (dipakai saat admin butuh data terbaru).
  Future<void> refresh() async {
    _serverSynced = await _syncFromServer();
    if (_serverSynced) await _persist(await SharedPreferences.getInstance());
  }

  Future<bool> _syncFromServer() async {
    if (!_hasServer) return false;
    try {
      final r = await _client
          .get(_dataUri(), headers: _headers(json: false))
          .timeout(_opTimeout);
      if (r.statusCode != 200) return false;
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      users..clear()..addAll(_map(body['users'], AdminUser.fromJson));
      posts..clear()..addAll(_map(body['posts'], CommunityPost.fromJson));
      comments..clear()..addAll(_map(body['comments'], AdminComment.fromJson));
      reports..clear()..addAll(_map(body['reports'], ComplaintReport.fromJson));
      activities
        ..clear()
        ..addAll(_map(body['activities'], AdminActivity.fromJson));
      announcements
        ..clear()
        ..addAll(_map(body['announcements'], AdminAnnouncement.fromJson));
      return true;
    } catch (_) {
      return false;
    }
  }

  List<T> _map<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw is! List) return <T>[];
    return raw
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);
  }

  T _parse<T>(String s, T Function(Map<String, dynamic>) f) => f(jsonDecode(s) as Map<String, dynamic>);
  List<T> _read<T>(SharedPreferences p, String key, T Function(Map<String, dynamic>) f) => (p.getStringList(key) ?? const []).map((s) => _parse(s, f)).toList();
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _persist(SharedPreferences p) async {
    await p.setStringList(_usersKey, users.map((x) => jsonEncode(x.toJson())).toList());
    await p.setStringList(_postsKey, posts.map((x) => jsonEncode(x.toJson())).toList());
    await p.setStringList(_commentsKey, comments.map((x) => jsonEncode(x.toJson())).toList());
    await p.setStringList(_reportsKey, reports.map((x) => jsonEncode(x.toJson())).toList());
    await p.setStringList(_activitiesKey, activities.map((x) => jsonEncode(x.toJson())).toList());
    await p.setStringList(_announcementsKey, announcements.map((x) => jsonEncode(x.toJson())).toList());
  }

  Future<void> _save() async => _persist(await SharedPreferences.getInstance());

  Future<void> _serverCreate(String collection, Map<String, dynamic> json) =>
      _guard(() => _client.post(_dataUri(collection),
          headers: _headers(), body: jsonEncode({'item': json})));

  Future<void> _serverUpdate(String collection, Map<String, dynamic> json) =>
      _guard(() => _client.put(_dataUri('$collection/${json['id']}'),
          headers: _headers(), body: jsonEncode({'item': json})));

  Future<void> _serverDelete(String collection, String id) => _guard(
      () => _client.delete(_dataUri('$collection/$id'), headers: _headers()));

  Future<void> _guard(Future<http.Response> Function() op) async {
    if (!_hasServer) return;
    try {
      await op().timeout(_opTimeout);
    } catch (_) {
      // Tidak memblokir UI saat server offline; perubahan tetap tersimpan lokal.
    }
  }

  Future<void> logActivity(String label, {String type = 'system'}) async {
    final item = AdminActivity(id: _id(), label: label, type: type, createdAt: DateTime.now());
    activities.insert(0, item);
    if (activities.length > 80) activities.removeLast();
    await _save();
    await _serverCreate('activities', item.toJson());
  }

  int get totalUsers => users.length;
  int get onlineUsers => users.where((u) => u.online).length;
  int get activeUsers => users.where((u) => u.online || u.id == 'u-001').length;
  int get openReports => reports.where((r) => r.status == 'open').length;

  Future<void> setUserOnline(String id, bool value) async { final u = users.where((x) => x.id == id).isEmpty ? null : users.where((x) => x.id == id).first; if (u == null) return; u.online = value; await _save(); await _serverUpdate('users', u.toJson()); }
  Future<void> addUser(AdminUser u) async { users.insert(0, u); await logActivity('User ${u.name} dibuat', type: 'user'); await _serverCreate('users', u.toJson()); }
  Future<void> updateUser(AdminUser u) async { final i = users.indexWhere((x) => x.id == u.id); if (i >= 0) users[i] = u; await logActivity('User ${u.name} diperbarui', type: 'user'); await _serverUpdate('users', u.toJson()); }
  Future<void> deleteUser(String id) async { final i = users.indexWhere((x) => x.id == id); if (i < 0) return; final name = users[i].name; users.removeAt(i); await logActivity('User $name dihapus', type: 'user'); await _serverDelete('users', id); }

  Future<void> addPost(CommunityPost post) async { posts.insert(0, post); await logActivity('Posting komunitas baru dari ${post.author}', type: 'community'); await _serverCreate('posts', post.toJson()); }
  Future<void> updatePost(CommunityPost post) async { final i = posts.indexWhere((x) => x.id == post.id); if (i >= 0) posts[i] = post; await logActivity('Posting ${post.id} diperbarui', type: 'community'); await _serverUpdate('posts', post.toJson()); }
  Future<void> deletePost(String id) async { posts.removeWhere((x) => x.id == id); comments.removeWhere((x) => x.postId == id); await logActivity('Posting komunitas dihapus', type: 'community'); await _serverDelete('posts', id); }

  Future<void> addComment(AdminComment c) async { comments.insert(0, c); final p = posts.where((x) => x.id == c.postId).isEmpty ? null : posts.where((x) => x.id == c.postId).first; if (p != null) p.comments++; await logActivity('Komentar baru dari ${c.author}', type: 'comment'); await _serverCreate('comments', c.toJson()); }
  Future<void> deleteComment(String id) async { comments.removeWhere((x) => x.id == id); await logActivity('Komentar dihapus', type: 'comment'); await _serverDelete('comments', id); }
  Future<void> updateComment(AdminComment c) async { final i = comments.indexWhere((x) => x.id == c.id); if (i >= 0) comments[i] = c; await logActivity('Komentar dimoderasi', type: 'comment'); await _serverUpdate('comments', c.toJson()); }

  Future<void> addReport(ComplaintReport r) async { reports.insert(0, r); await logActivity('Laporan baru: ${r.category}', type: 'report'); await _serverCreate('reports', r.toJson()); }
  Future<void> updateReport(ComplaintReport r) async { final i = reports.indexWhere((x) => x.id == r.id); if (i >= 0) reports[i] = r; await logActivity('Laporan ${r.id} diperbarui', type: 'report'); await _serverUpdate('reports', r.toJson()); }
  Future<void> deleteReport(String id) async { reports.removeWhere((x) => x.id == id); await logActivity('Laporan dihapus', type: 'report'); await _serverDelete('reports', id); }

  List<AdminAnnouncement> get activeAnnouncements => announcements.where((x)=>x.active).toList();
  List<AdminAnnouncement> activeAdsFor(bool premium) => activeAnnouncements.where((x)=>x.type=='ad' && (!x.freeOnly || !premium)).toList();
  List<AdminAnnouncement> activeBannersFor(bool premium) => activeAnnouncements.where((x)=>(x.type=='banner' || x.type=='announcement') && (!x.freeOnly || !premium)).toList();
  Future<void> addAnnouncement(AdminAnnouncement item) async { announcements.insert(0,item); await logActivity('Konten ${item.title} dibuat', type:'system'); await _serverCreate('announcements', item.toJson()); }
  Future<void> updateAnnouncement(AdminAnnouncement item) async { final i=announcements.indexWhere((x)=>x.id==item.id); if(i>=0) announcements[i]=item; await logActivity('Konten ${item.title} diperbarui', type:'system'); await _serverUpdate('announcements', item.toJson()); }
  Future<void> deleteAnnouncement(String id) async { announcements.removeWhere((x)=>x.id==id); await logActivity('Konten pengumuman/iklan dihapus', type:'system'); await _serverDelete('announcements', id); }
}