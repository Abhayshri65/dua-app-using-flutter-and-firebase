import 'package:flutter/material.dart';
import '../models/dua.dart';
import '../services/auth_service.dart';
import 'admin_categories_screen.dart';
import 'admin_notification_send_screen.dart';
import '../services/firestore_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AdminPanel();
  }
}

class _AdminPanel extends StatelessWidget {
  const _AdminPanel();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Manage Categories',
              onPressed: () =>
                  Navigator.pushNamed(context, '/admin-categories'),
            ),
            IconButton(
              icon: const Icon(Icons.mood),
              tooltip: 'Manage Emotions',
              onPressed: () =>
                  Navigator.pushNamed(context, '/admin-emotions'),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/admin-login');
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Duas'),
              Tab(text: 'Notifications'),
              Tab(text: 'Categories'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DuasTab(),
            AdminNotificationsTab(),
            AdminCategoriesBody(),
          ],
        ),
      ),
    );
  }
}


class _DuasTab extends StatelessWidget {
  const _DuasTab();

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/admin-dua-form'),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Dua>>(
        stream: service.watchAllDuas(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load duas'));
          }
          final duas = snapshot.data ?? [];
          if (duas.isEmpty) {
            return const Center(child: Text('No duas found'));
          }
          return ListView.separated(
            itemCount: duas.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dua = duas[index];
              return ListTile(
                title: Text(dua.title),
                subtitle: Text(
                  dua.displayTitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.pushNamed(
                        context,
                        '/admin-dua-form',
                        arguments: dua,
                      );
                    } else if (value == 'delete') {
                      final confirm = await _confirmDelete(context);
                      if (confirm) {
                        await service.deleteDua(dua.id);
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/admin-dua-form',
                  arguments: dua,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dua'),
        content: const Text('Are you sure you want to delete this dua?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// Notifications tab now lives in admin_notification_send_screen.dart.
