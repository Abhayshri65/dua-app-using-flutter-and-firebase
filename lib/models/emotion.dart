import 'package:cloud_firestore/cloud_firestore.dart';

class Emotion {
  Emotion({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory Emotion.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Emotion(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
