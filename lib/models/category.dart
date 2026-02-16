import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  final String id;
  final String name;
  final String slug;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  factory Category.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Category(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      slug: (data['slug'] ?? '').toString(),
      order: (data['order'] is num) ? (data['order'] as num).toInt() : 0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'order': order,
      'createdBy': createdBy,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? slug,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
