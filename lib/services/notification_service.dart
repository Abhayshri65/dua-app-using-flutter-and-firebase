import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dua_notification.dart';
import 'auth_service.dart';

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthService _authService;

  Stream<List<DuaNotification>> watchActiveNotifications() {
    return _firestore
        .collection('dua_notifications')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DuaNotification.fromDoc(doc))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<List<DuaNotification>> watchAllNotifications() {
    return _firestore
        .collection('dua_notifications')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DuaNotification.fromDoc(doc))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Stream<int> watchUnreadCount(String? uid) {
    if (uid == null || uid.isEmpty) {
      return watchActiveNotifications().map((items) => items.length);
    }

    final lastSeenStream = _firestore
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('notifications')
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final ts = data['lastSeenAt'];
      if (ts is Timestamp) return ts.toDate();
      return null;
    });

    return Stream<int>.multi((controller) {
      DateTime? lastSeen;
      List<DuaNotification> items = const [];

      void emit() {
        final count = items.where((item) {
          if (lastSeen == null) return true;
          final created = item.createdAt;
          if (created == null) return true;
          return created.isAfter(lastSeen!);
        }).length;
        controller.add(count);
      }

      final sub1 = lastSeenStream.listen((value) {
        lastSeen = value;
        emit();
      });
      final sub2 = watchActiveNotifications().listen((value) {
        items = value;
        emit();
      });

      controller.onCancel = () {
        sub1.cancel();
        sub2.cancel();
      };
    });
  }

  Future<void> markAllSeen(String? uid) async {
    if (uid == null || uid.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('notifications')
        .set({'lastSeenAt': FieldValue.serverTimestamp()});
  }

  Future<void> createNotification({
    required String title,
    required String message,
    String? duaId,
    String? categoryId,
    String? subcategoryId,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedMessage = message.trim();
    if (trimmedTitle.isEmpty || trimmedMessage.isEmpty) {
      throw Exception('Title and message are required');
    }
    await _firestore.collection('dua_notifications').add({
      'title': trimmedTitle,
      'message': trimmedMessage,
      'duaId': duaId,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });
  }

  Future<void> deleteNotification(String id) async {
    await _firestore.collection('dua_notifications').doc(id).delete();
  }

  Future<void> updateActive(String id, bool active) async {
    await _firestore.collection('dua_notifications').doc(id).update({
      'active': active,
    });
  }

  String? currentUid() => _authService.currentUser?.uid;
}
