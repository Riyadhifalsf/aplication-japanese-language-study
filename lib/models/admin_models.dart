class AdminUser {
  AdminUser({required this.id, required this.name, required this.email, required this.role, required this.level, this.online = false, this.createdAt});
  final String id;
  String name;
  String email;
  String role;
  String level;
  bool online;
  DateTime? createdAt;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role, 'level': level, 'online': online, 'createdAt': createdAt?.toIso8601String()};
  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(id: j['id'] as String? ?? '', name: j['name'] as String? ?? '', email: j['email'] as String? ?? '', role: j['role'] as String? ?? 'user', level: j['level'] as String? ?? 'N5', online: j['online'] == true, createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''));
}

class CommunityPost {
  CommunityPost({required this.id, required this.author, required this.text, this.likes = 0, this.comments = 0, this.status = 'published', this.createdAt});
  final String id;
  String author;
  String text;
  int likes;
  int comments;
  String status;
  DateTime? createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'author': author, 'text': text, 'likes': likes, 'comments': comments, 'status': status, 'createdAt': createdAt?.toIso8601String()};
  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(id: j['id'] as String? ?? '', author: j['author'] as String? ?? '', text: j['text'] as String? ?? '', likes: (j['likes'] as num?)?.toInt() ?? 0, comments: (j['comments'] as num?)?.toInt() ?? 0, status: j['status'] as String? ?? 'published', createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''));
}

class AdminComment {
  AdminComment({required this.id, required this.postId, required this.author, required this.text, this.status = 'published', this.createdAt});
  final String id;
  String postId;
  String author;
  String text;
  String status;
  DateTime? createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'postId': postId, 'author': author, 'text': text, 'status': status, 'createdAt': createdAt?.toIso8601String()};
  factory AdminComment.fromJson(Map<String, dynamic> j) => AdminComment(id: j['id'] as String? ?? '', postId: j['postId'] as String? ?? '', author: j['author'] as String? ?? '', text: j['text'] as String? ?? '', status: j['status'] as String? ?? 'published', createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''));
}

class ComplaintReport {
  ComplaintReport({required this.id, required this.reporter, required this.category, required this.message, this.status = 'open', this.createdAt});
  final String id;
  String reporter;
  String category;
  String message;
  String status;
  DateTime? createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'reporter': reporter, 'category': category, 'message': message, 'status': status, 'createdAt': createdAt?.toIso8601String()};
  factory ComplaintReport.fromJson(Map<String, dynamic> j) => ComplaintReport(id: j['id'] as String? ?? '', reporter: j['reporter'] as String? ?? '', category: j['category'] as String? ?? 'Lainnya', message: j['message'] as String? ?? '', status: j['status'] as String? ?? 'open', createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''));
}

class AdminActivity {
  AdminActivity({required this.id, required this.label, required this.type, this.createdAt});
  final String id;
  final String label;
  final String type;
  final DateTime? createdAt;
  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'type': type, 'createdAt': createdAt?.toIso8601String()};
  factory AdminActivity.fromJson(Map<String, dynamic> j) => AdminActivity(id: j['id'] as String? ?? '', label: j['label'] as String? ?? '', type: j['type'] as String? ?? 'system', createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''));
}


class AdminAnnouncement {
  AdminAnnouncement({required this.id, required this.title, required this.body, this.type='announcement', this.active=true, this.freeOnly=false, this.ctaLabel='', this.createdAt});
  final String id;
  String title;
  String body;
  String type;
  bool active;
  bool freeOnly;
  String ctaLabel;
  DateTime? createdAt;
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'body':body,'type':type,'active':active,'freeOnly':freeOnly,'ctaLabel':ctaLabel,'createdAt':createdAt?.toIso8601String()};
  factory AdminAnnouncement.fromJson(Map<String,dynamic> j)=>AdminAnnouncement(id:j['id'] as String? ?? '',title:j['title'] as String? ?? '',body:j['body'] as String? ?? '',type:j['type'] as String? ?? 'announcement',active:j['active'] != false,freeOnly:j['freeOnly']==true,ctaLabel:j['ctaLabel'] as String? ?? '',createdAt:DateTime.tryParse(j['createdAt'] as String? ?? ''));
}
