import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';
import 'auth_service.dart';

class CategoryService {
  CategoryService({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  static const List<String> defaultCategories = [
    'Daily Routine Duas',
    'Purification and Cleanliness Duas',
    'Clothing Duas',
    'Home-Related Duas',
    'Mosque-Related Duas',
    'Prayer (Salah) Duas',
    'Food and Provision Duas',
    'Travel Duas',
    'Knowledge, Work, and Worldly Affairs Duas',
    'Health and Protection Duas',
    'Family and Relationship Duas',
    'Hardship, Anxiety, and Distress Duas',
    'Repentance and Forgiveness Duas',
    'Faith and Guidance Duas',
    'Hereafter (Akhirah) Duas',
    'Death and Funeral Duas',
    'Natural Events Duas',
    'Special Times and Occasions Duas',
    'Community and Ummah Duas',
    'Technical / Conceptual Types of Duas',
  ];

  Future<void> seedDefaultCategoriesIfNeeded() async {
    final snapshot = await _firestore.collection('categories').get();
    final existingSlugs = snapshot.docs
        .map((doc) => (doc.data()['slug'] ?? '').toString().toLowerCase())
        .where((slug) => slug.isNotEmpty)
        .toSet();
    final existingNames = snapshot.docs
        .map((doc) => (doc.data()['name'] ?? '').toString().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();

    final batch = _firestore.batch();
    var added = 0;
    for (var i = 0; i < defaultCategories.length; i++) {
      final name = defaultCategories[i];
      final slug = _slugify(name);
      if (existingSlugs.contains(slug) ||
          existingNames.contains(name.toLowerCase())) {
        continue;
      }
      final docRef = _firestore.collection('categories').doc();
      batch.set(docRef, {
        'name': name,
        'slug': slug,
        'order': i + 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': _createdBy(),
      });
      added++;
    }
    if (added > 0) {
      await batch.commit();
    }
  }

  Stream<List<Category>> watchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      final list = snapshot.docs.map(Category.fromDoc).toList();
      list.sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return list;
    });
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Category name is required');
    }
    await _ensureNameUnique(trimmed);
    final slug = _slugify(trimmed);
    await _ensureSlugUnique(slug);

    final order = await _nextOrder();
    await _firestore.collection('categories').add({
      'name': trimmed,
      'slug': slug,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': _createdBy(),
    });
  }

  Future<String> createCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Category name is required');
    }
    await _ensureNameUnique(trimmed);
    final slug = _slugify(trimmed);
    await _ensureSlugUnique(slug);

    final order = await _nextOrder();
    final docRef = _firestore.collection('categories').doc();
    await docRef.set({
      'name': trimmed,
      'slug': slug,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': _createdBy(),
    });
    return docRef.id;
  }

  Future<void> updateCategory(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Category name is required');
    }
    await _ensureNameUnique(trimmed, excludeId: id);
    final slug = _slugify(trimmed);
    await _ensureSlugUnique(slug, excludeId: id);

    await _firestore.collection('categories').doc(id).update({
      'name': trimmed,
      'slug': slug,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }

  Future<int> countSubcategories(String categoryId) async {
    final query = await _firestore
        .collection('subcategories')
        .where('categoryId', isEqualTo: categoryId)
        .get();
    return query.docs.length;
  }

  Future<void> createCategoryWithSubcategories({
    required String name,
    required List<String> subcategoryNames,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw Exception('Category name is required');
    }
    if (subcategoryNames.isEmpty) {
      throw Exception('At least one subcategory is required');
    }

    final normalized = subcategoryNames
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (normalized.isEmpty) {
      throw Exception('At least one subcategory is required');
    }
    final seen = <String>{};
    for (final name in normalized) {
      final key = name.toLowerCase();
      if (seen.contains(key)) {
        throw Exception('Duplicate subcategory name: $name');
      }
      seen.add(key);
    }

    await _ensureNameUnique(trimmed);
    final slug = _slugify(trimmed);
    await _ensureSlugUnique(slug);

    final categoryRef = _firestore.collection('categories').doc();
    final batch = _firestore.batch();
    final order = await _nextOrder();
    batch.set(categoryRef, {
      'name': trimmed,
      'slug': slug,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': _createdBy(),
    });

    var subOrder = 1;
    for (final sub in normalized) {
      final subRef = _firestore.collection('subcategories').doc();
      batch.set(subRef, {
        'categoryId': categoryRef.id,
        'name': sub,
        'slug': _slugify(sub),
        'order': subOrder++,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  String _createdBy() {
    final user = _authService.currentUser;
    return user?.email ?? user?.uid ?? '';
  }

  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    final replaced = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final collapsed = replaced.replaceAll(RegExp(r'-{2,}'), '-');
    return collapsed.replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _ensureSlugUnique(String slug, {String? excludeId}) async {
    final query = await _firestore
        .collection('categories')
        .where('slug', isEqualTo: slug)
        .get();

    if (query.docs.isEmpty) {
      return;
    }

    if (excludeId != null &&
        query.docs.every((doc) => doc.id == excludeId)) {
      return;
    }
    throw Exception('Category already exists');
  }

  Future<void> _ensureNameUnique(String name, {String? excludeId}) async {
    final snapshot = await _firestore.collection('categories').get();
    final target = name.trim().toLowerCase();
    for (final doc in snapshot.docs) {
      if (excludeId != null && doc.id == excludeId) {
        continue;
      }
      final existing = (doc.data()['name'] ?? '').toString().trim().toLowerCase();
      if (existing == target) {
        throw Exception('Category already exists');
      }
    }
  }

  Future<int> _nextOrder() async {
    final query = await _firestore
        .collection('categories')
        .orderBy('order', descending: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      return 1;
    }
    final value = query.docs.first.data()['order'];
    if (value is num) {
      return value.toInt() + 1;
    }
    return 1;
  }
}
