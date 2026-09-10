/// Minimal compatibility model for the local notification inbox.
/// Administrative CRUD models were removed from the client; admin operations
/// belong to the protected backend.
class AdminAnnouncement {
  AdminAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'announcement',
    this.active = true,
    this.freeOnly = false,
    this.ctaLabel = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool active;
  final bool freeOnly;
  final String ctaLabel;
  final DateTime? createdAt;
}
