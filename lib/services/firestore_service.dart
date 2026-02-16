import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dua.dart';
import '../models/notification_item.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<Dua>> fetchRecentDuas({int limit = 200}) async {
    final snapshot =
        await _firestore.collection('duas').limit(limit).get();
    return snapshot.docs.map(Dua.fromDoc).toList();
  }

  Future<List<Dua>> searchDuas(String query) async {
    final tokens = _buildQueryTokens(query);
    if (tokens.isEmpty) {
      return [];
    }

    final limited = tokens.take(10).toList();
    try {
      final snapshot = await _firestore
          .collection('duas')
          .where('searchTokens', arrayContainsAny: limited)
          .get();
      final docs = snapshot.docs.map(Dua.fromDoc).toList();
      return _filterByTagsOnly(docs, tokens);
    } catch (_) {
      // Fallback for legacy docs without searchTokens or query limitations.
      final docs = await fetchRecentDuas(limit: 400);
      return _filterByTagsOnly(docs, tokens);
    }
  }

  List<Dua> _filterByTagsOnly(List<Dua> docs, List<String> tokens) {
    return docs.where((dua) {
      final tags = Dua.normalizeTagList(dua.tags);
      if (tags.isEmpty) return false;
      for (final token in tokens) {
        for (final tag in tags) {
          if (_tagMatchesToken(tag, token)) {
            return true;
          }
        }
      }
      return false;
    }).toList();
  }

  bool _tagMatchesToken(String tag, String token) {
    if (tag == token) return true;
    if (tag.startsWith(token)) return true;
    final words = tag.split(' ');
    for (final word in words) {
      if (word == token || word.startsWith(token)) {
        return true;
      }
    }
    return false;
  }

  List<String> _buildQueryTokens(String query) {
    final normalized = _normalizeText(query);
    if (normalized.isEmpty) return const [];
    final parts = normalized.split(' ').where((part) => part.isNotEmpty);
    final stopwords = <String>{
      'dua',
      'for',
      'the',
      'a',
      'an',
      'to',
      'in',
      'of',
      'and',
      'or',
      'is',
      'are',
      'me',
      'my',
    };
    final tokens = <String>[];
    final seen = <String>{};
    for (final part in parts) {
      if (stopwords.contains(part)) continue;
      if (seen.add(part)) tokens.add(part);
    }
    return tokens;
  }

  String _normalizeText(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.isEmpty) return '';
    final noPunct = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return noPunct.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Stream<List<Dua>> watchAllDuas() {
    return _firestore
        .collection('duas')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Dua.fromDoc).toList());
  }

  Future<void> addDua(Dua dua) async {
    await _firestore.collection('duas').add(
          {
            ...dua.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
  }

  Future<void> updateDua(String id, Dua dua) async {
    await _firestore.collection('duas').doc(id).update(
          {
            ...dua.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
  }

  Future<void> deleteDua(String id) async {
    await _firestore.collection('duas').doc(id).delete();
  }

  Future<Dua?> getDuaById(String id) async {
    final doc = await _firestore.collection('duas').doc(id).get();
    if (!doc.exists) return null;
    return Dua.fromDoc(doc);
  }

  Stream<List<Dua>> watchDuasByCategory(String categoryId) {
    // NOTE: avoid orderBy to prevent composite index errors with arrayContains.
    return _firestore
        .collection('duas')
        .where('categoryIds', arrayContains: categoryId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Dua.fromDoc).toList());
  }

  Stream<List<Dua>> watchDuasBySubcategory(String subcategoryId) {
    return _firestore
        .collection('duas')
        .where('subcategoryId', isEqualTo: subcategoryId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Dua.fromDoc).toList());
  }

  Stream<List<Dua>> watchDuasByEmotion(String emotionName) {
    return _firestore
        .collection('duas')
        .where('emotions', arrayContains: emotionName)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Dua.fromDoc).toList());
  }

  Future<int> countDuasInSubcategory(String subcategoryId) async {
    final query = await _firestore
        .collection('duas')
        .where('subcategoryId', isEqualTo: subcategoryId)
        .get();
    return query.docs.length;
  }

  Stream<List<NotificationItem>> watchNotifications({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('notifications').orderBy('createdAt', descending: true);
    if (activeOnly) {
      query = query.where('active', isEqualTo: true);
    }
    return query.snapshots().map(
          (snapshot) =>
              snapshot.docs.map(NotificationItem.fromDoc).toList(),
        );
  }

  Future<void> addNotification({
    required String title,
    required String message,
    String? duaId,
    bool active = true,
  }) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'message': message,
      'duaId': duaId,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateNotificationActive(String id, bool active) async {
    await _firestore.collection('notifications').doc(id).update({
      'active': active,
    });
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('notifications').doc(id).delete();
  }
}
