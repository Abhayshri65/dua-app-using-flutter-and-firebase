import 'package:cloud_firestore/cloud_firestore.dart';

class DuaNotification {
  const DuaNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.duaId,
    required this.categoryId,
    required this.subcategoryId,
    required this.createdAt,
    required this.active,
  });

  final String id;
  final String title;
  final String message;
  final String? duaId;
  final String? categoryId;
  final String? subcategoryId;
  final DateTime? createdAt;
  final bool active;

  factory DuaNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DuaNotification(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      duaId: data['duaId']?.toString(),
      categoryId: data['categoryId']?.toString(),
      subcategoryId: data['subcategoryId']?.toString(),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      active: data['active'] == true,
    );
  }
}
