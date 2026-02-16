import 'package:flutter/material.dart';

import '../models/emotion.dart';
import '../services/emotion_service.dart';

class AdminEmotionsScreen extends StatefulWidget {
  const AdminEmotionsScreen({super.key});

  @override
  State<AdminEmotionsScreen> createState() => _AdminEmotionsScreenState();
}

class _AdminEmotionsScreenState extends State<AdminEmotionsScreen> {
  final _service = EmotionService();

  @override
  void initState() {
    super.initState();
    _service.seedDefaultEmotionsIfNeeded();
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Emotion'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Emotion name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.trim().isEmpty) return;
    await _service.addEmotion(result.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Emotions'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Emotion>>(
        stream: _service.watchEmotions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load emotions'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No emotions found'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final emotion = items[index];
              return ListTile(
                title: Text(emotion.name),
              );
            },
          );
        },
      ),
    );
  }
}
