import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDuaMeta {
  UserDuaMeta({
    required this.id,
    required this.title,
    required this.duaTitle,
    required this.topic,
  });

  final String id;
  final String title;
  final String? duaTitle;
  final String? topic;

  factory UserDuaMeta.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserDuaMeta(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      duaTitle: data['duaTitle']?.toString(),
      topic: data['topic']?.toString(),
    );
  }
}

class DuaUserActionsService {
  DuaUserActionsService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> _userCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  CollectionReference<Map<String, dynamic>> _savedCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('saved_duas');
  }

  Stream<List<UserDuaMeta>> favoritesStream() {
    final uid = currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _userCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserDuaMeta.fromDoc).toList());
  }

  Stream<List<UserDuaMeta>> savedStream() {
    final uid = currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _savedCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserDuaMeta.fromDoc).toList());
  }

  Future<bool> isFavorited(String duaId) async {
    final uid = currentUser?.uid;
    if (uid == null) return false;
    final doc = await _userCollection(uid).doc(duaId).get();
    return doc.exists;
  }

  Future<bool> isSaved(String duaId) async {
    final uid = currentUser?.uid;
    if (uid == null) return false;
    final doc = await _savedCollection(uid).doc(duaId).get();
    return doc.exists;
  }

  Future<void> addFavorite({
    required String duaId,
    required String title,
    String? duaTitle,
    String? topic,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _userCollection(uid).doc(duaId).set({
      'title': title,
      'duaTitle': duaTitle ?? '',
      'topic': topic ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFavorite(String duaId) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _userCollection(uid).doc(duaId).delete();
  }

  Future<void> addSaved({
    required String duaId,
    required String title,
    String? duaTitle,
    String? topic,
  }) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _savedCollection(uid).doc(duaId).set({
      'title': title,
      'duaTitle': duaTitle ?? '',
      'topic': topic ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeSaved(String duaId) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    await _savedCollection(uid).doc(duaId).delete();
  }
}
