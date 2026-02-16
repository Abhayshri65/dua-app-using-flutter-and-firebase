import 'package:cloud_firestore/cloud_firestore.dart';

class Subcategory {
  const Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String name;
  final String slug;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Subcategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Subcategory(
      id: doc.id,
      categoryId: (data['categoryId'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      slug: (data['slug'] ?? '').toString(),
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
