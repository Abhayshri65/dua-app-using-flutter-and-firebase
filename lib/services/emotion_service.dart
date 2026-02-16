import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emotion.dart';

class EmotionService {
  EmotionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<String> defaultEmotions = [
    'Happiness',
    'Sadness',
    'Stress',
    'Anxiety',
    'Fear',
    'Anger',
    'Love',
    'Worry',
    'Peace',
    'Loneliness',
    'Depression',
    'Frustration',
    'Hope',
    'Trust',
    'Guilt',
    'Confidence',
    'Gratitude',
    'Calmness',
    'Jealousy',
    'Relief',
  ];

  Stream<List<Emotion>> watchEmotions() {
    return _firestore
        .collection('emotions')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Emotion.fromDoc).toList());
  }

  Future<void> addEmotion(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _firestore.collection('emotions').add({
      'name': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> seedDefaultEmotionsIfNeeded() async {
    final snapshot = await _firestore.collection('emotions').get();
    if (snapshot.docs.isNotEmpty) return;
    final batch = _firestore.batch();
    for (final name in defaultEmotions) {
      final ref = _firestore.collection('emotions').doc();
      batch.set(ref, {
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
