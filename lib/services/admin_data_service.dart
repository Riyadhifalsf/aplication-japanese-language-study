import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_models.dart';

class AdminDataService {
  static const _usersKey = 'admin_users_v1';
  static const _postsKey = 'admin_posts_v1';
  static const _commentsKey = 'admin_comments_v1';
  static const _reportsKey = 'admin_reports_v1';
  static const _activitiesKey = 'admin_activities_v1';
  static const _announcementsKey = 'admin_announcements_v1';

  final List<AdminUser> users = [];
  final List<CommunityPost> posts = [];
  final List<AdminComment> comments = [];
  final List<ComplaintReport> reports = [];
  final List<AdminActivity> activities = [];
  final List<AdminAnnouncement> announcements = [];

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    users..clear()..addAll(_read(p, _usersKey, AdminUser.fromJson));
    posts..clear()..addAll(_read(p, _postsKey, CommunityPost.fromJson));
    comments..clear()..addAll(_read(p, _commentsKey, AdminComment.fromJson));
    reports..clear()..addAll(_read(p, _reportsKey, ComplaintReport.fromJson));
    activities..clear()..addAll(_read(p, _activitiesKey, AdminActivity.fromJson));
    announcements..clear()..addAll(_read(p, _announcementsKey, AdminAnnouncement.fromJson));
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
  Future<void> logActivity(String label, {String type = 'system'}) async { activities.insert(0, AdminActivity(id: _id(), label: label, type: type, createdAt: DateTime.now())); if (activities.length > 80) activities.removeLast(); await _save(); }

  int get totalUsers => users.length;
  int get onlineUsers => users.where((u) => u.online).length;
  int get activeUsers => users.where((u) => u.online || u.id == 'u-001').length;
  int get openReports => reports.where((r) => r.status == 'open').length;

  Future<void> setUserOnline(String id, bool value) async { final u = users.where((x) => x.id == id).isEmpty ? null : users.where((x) => x.id == id).first; if (u == null) return; u.online = value; await _save(); }
  Future<void> addUser(AdminUser u) async { users.insert(0, u); await logActivity('User ${u.name} dibuat', type: 'user'); }
  Future<void> updateUser(AdminUser u) async { final i = users.indexWhere((x) => x.id == u.id); if (i >= 0) users[i] = u; await logActivity('User ${u.name} diperbarui', type: 'user'); }
  Future<void> deleteUser(String id) async { final i = users.indexWhere((x) => x.id == id); if (i < 0) return; final name = users[i].name; users.removeAt(i); await logActivity('User $name dihapus', type: 'user'); }

  Future<void> addPost(CommunityPost post) async { posts.insert(0, post); await logActivity('Posting komunitas baru dari ${post.author}', type: 'community'); }
  Future<void> updatePost(CommunityPost post) async { final i = posts.indexWhere((x) => x.id == post.id); if (i >= 0) posts[i] = post; await logActivity('Posting ${post.id} diperbarui', type: 'community'); }
  Future<void> deletePost(String id) async { posts.removeWhere((x) => x.id == id); comments.removeWhere((x) => x.postId == id); await logActivity('Posting komunitas dihapus', type: 'community'); }

  Future<void> addComment(AdminComment c) async { comments.insert(0, c); final p = posts.where((x) => x.id == c.postId).isEmpty ? null : posts.where((x) => x.id == c.postId).first; if (p != null) p.comments++; await logActivity('Komentar baru dari ${c.author}', type: 'comment'); }
  Future<void> deleteComment(String id) async { comments.removeWhere((x) => x.id == id); await logActivity('Komentar dihapus', type: 'comment'); }
  Future<void> updateComment(AdminComment c) async { final i = comments.indexWhere((x) => x.id == c.id); if (i >= 0) comments[i] = c; await logActivity('Komentar dimoderasi', type: 'comment'); }

  Future<void> addReport(ComplaintReport r) async { reports.insert(0, r); await logActivity('Laporan baru: ${r.category}', type: 'report'); }
  Future<void> updateReport(ComplaintReport r) async { final i = reports.indexWhere((x) => x.id == r.id); if (i >= 0) reports[i] = r; await logActivity('Laporan ${r.id} diperbarui', type: 'report'); }
  Future<void> deleteReport(String id) async { reports.removeWhere((x) => x.id == id); await logActivity('Laporan dihapus', type: 'report'); }

  List<AdminAnnouncement> get activeAnnouncements => announcements.where((x)=>x.active).toList();
  List<AdminAnnouncement> activeAdsFor(bool premium) => activeAnnouncements.where((x)=>x.type=='ad' && (!x.freeOnly || !premium)).toList();
  List<AdminAnnouncement> activeBannersFor(bool premium) => activeAnnouncements.where((x)=>(x.type=='banner' || x.type=='announcement') && (!x.freeOnly || !premium)).toList();
  Future<void> addAnnouncement(AdminAnnouncement item) async { announcements.insert(0,item); await logActivity('Konten ${item.title} dibuat', type:'system'); }
  Future<void> updateAnnouncement(AdminAnnouncement item) async { final i=announcements.indexWhere((x)=>x.id==item.id); if(i>=0) announcements[i]=item; await logActivity('Konten ${item.title} diperbarui', type:'system'); }
  Future<void> deleteAnnouncement(String id) async { announcements.removeWhere((x)=>x.id==id); await logActivity('Konten pengumuman/iklan dihapus', type:'system'); }

}
