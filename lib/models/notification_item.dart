import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.duaId,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String? duaId;
  final bool active;
  final DateTime? createdAt;

  factory NotificationItem.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NotificationItem(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      duaId: data['duaId']?.toString(),
      active: (data['active'] ?? true) as bool,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
