import 'package:flutter/material.dart';

import '../models/dua.dart';
import '../models/dua_notification.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AdminNotificationSendScreen extends StatefulWidget {
  const AdminNotificationSendScreen({super.key});

  @override
  State<AdminNotificationSendScreen> createState() =>
      _AdminNotificationSendScreenState();
}

class _AdminNotificationSendScreenState
    extends State<AdminNotificationSendScreen> {
  final _title = TextEditingController();
  final _message = TextEditingController();
  final _service = NotificationService();
  final _duaService = FirestoreService();
  bool _saving = false;
  String? _selectedDuaId;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final message = _message.text.trim();
    if (title.isEmpty || message.isEmpty) {
      _showSnack('Title and message are required');
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.createNotification(
        title: title,
        message: message,
        duaId: _selectedDuaId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Notification sent');
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Dua Notification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _message,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Dua>>(
              stream: _duaService.watchAllDuas(),
              builder: (context, snapshot) {
                final duas = snapshot.data ?? [];
                return DropdownButtonFormField<String>(
                  value: _selectedDuaId,
                  decoration: const InputDecoration(
                    labelText: 'Link to Dua (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: duas
                      .map(
                        (dua) => DropdownMenuItem<String>(
                          value: dua.id,
                          child: Text(dua.displayTitle()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedDuaId = value);
                  },
                );
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminNotificationsTab extends StatelessWidget {
  const AdminNotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NotificationService();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/admin-send-notification'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<DuaNotification>>(
        stream: service.watchAllNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load notifications'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(item.message),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: item.active,
                      onChanged: (value) async {
                        await service.updateActive(item.id, value);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await service.deleteNotification(item.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
