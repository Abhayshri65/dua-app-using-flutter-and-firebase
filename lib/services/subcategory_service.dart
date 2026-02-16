import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/subcategory.dart';

class SubcategoryService {
  SubcategoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Subcategory>> watchSubcategoriesByCategory(String categoryId) {
    return _firestore
        .collection('subcategories')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(Subcategory.fromDoc).toList();
      list.sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return list;
    });
  }

  Future<Subcategory?> getSubcategoryById(String id) async {
    final doc = await _firestore.collection('subcategories').doc(id).get();
    if (!doc.exists) return null;
    return Subcategory.fromDoc(doc);
  }

  Future<void> addSubcategory({
    required String categoryId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Subcategory name is required');
    }
    await _ensureNameUnique(categoryId, trimmed);
    final order = await _nextOrder(categoryId);
    await _firestore.collection('subcategories').add({
      'categoryId': categoryId,
      'name': trimmed,
      'slug': _slugify(trimmed),
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSubcategory(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Subcategory name is required');
    }
    final doc = await _firestore.collection('subcategories').doc(id).get();
    final categoryId = (doc.data()?['categoryId'] ?? '').toString();
    if (categoryId.isNotEmpty) {
      await _ensureNameUnique(categoryId, trimmed, excludeId: id);
    }
    await _firestore.collection('subcategories').doc(id).update({
      'name': trimmed,
      'slug': _slugify(trimmed),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSubcategory(String id) async {
    await _firestore.collection('subcategories').doc(id).delete();
  }

  Future<int> countSubcategories(String categoryId) async {
    final query = await _firestore
        .collection('subcategories')
        .where('categoryId', isEqualTo: categoryId)
        .get();
    return query.docs.length;
  }

  Future<int> _nextOrder(String categoryId) async {
    final query = await _firestore
        .collection('subcategories')
        .where('categoryId', isEqualTo: categoryId)
        .get();
    if (query.docs.isEmpty) return 1;
    int maxOrder = 0;
    for (final doc in query.docs) {
      final value = doc.data()['order'];
      if (value is num && value.toInt() > maxOrder) {
        maxOrder = value.toInt();
      }
    }
    return maxOrder + 1;
  }

  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final collapsed = replaced.replaceAll(RegExp(r'-{2,}'), '-');
    return collapsed.replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _ensureNameUnique(
    String categoryId,
    String name, {
    String? excludeId,
  }) async {
    final snapshot = await _firestore
        .collection('subcategories')
        .where('categoryId', isEqualTo: categoryId)
        .get();
    final target = name.trim().toLowerCase();
    for (final doc in snapshot.docs) {
      if (excludeId != null && doc.id == excludeId) {
        continue;
      }
      final existing = (doc.data()['name'] ?? '').toString().trim().toLowerCase();
      if (existing == target) {
        throw Exception('Subcategory already exists');
      }
    }
  }
}
