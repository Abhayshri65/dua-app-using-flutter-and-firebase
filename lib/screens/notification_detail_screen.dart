import 'package:flutter/material.dart';

import '../models/dua_notification.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! DuaNotification) {
      return const Scaffold(
        body: Center(child: Text('Notification not found')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(args.message),
      ),
    );
  }
}
