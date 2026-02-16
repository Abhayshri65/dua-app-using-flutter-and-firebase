import 'package:flutter/material.dart';
import '../models/dua.dart';
import '../services/firestore_service.dart';

class AdminNotificationFormScreen extends StatefulWidget {
  const AdminNotificationFormScreen({super.key});

  @override
  State<AdminNotificationFormScreen> createState() =>
      _AdminNotificationFormScreenState();
}

class _AdminNotificationFormScreenState
    extends State<AdminNotificationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _title = TextEditingController();
  final _message = TextEditingController();
  String? _selectedDuaId;
  List<Dua> _duas = [];

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    final docs = await _service.fetchRecentDuas(limit: 200);
    if (!mounted) return;
    setState(() {
      _duas = docs;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _service.addNotification(
      title: _title.text.trim(),
      message: _message.text.trim(),
      duaId: _selectedDuaId,
      active: true,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification created')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Notification')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDuaId,
              decoration: const InputDecoration(
                labelText: 'Link Dua (optional)',
                border: OutlineInputBorder(),
              ),
              items: _duas
                  .map(
                    (dua) => DropdownMenuItem(
                      value: dua.id,
                      child: Text(
                        dua.displayTitle(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedDuaId = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
