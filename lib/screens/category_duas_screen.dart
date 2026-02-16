import 'package:flutter/material.dart';

import '../models/dua.dart';
import '../services/firestore_service.dart';

class CategoryDuasScreen extends StatelessWidget {
  const CategoryDuasScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    // Debug: verify categoryId/name and query field.
    debugPrint(
      'CategoryDuasScreen: categoryId=$categoryId, categoryName=$categoryName, field=categoryIds',
    );
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: StreamBuilder<List<Dua>>(
        stream: service.watchDuasByCategory(categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            // Debug: surface the real Firestore error.
            debugPrint('CategoryDuasScreen error: $error');
            return Center(
              child: Text('Failed to load duas: ${error.toString()}'),
            );
          }
          final duas = snapshot.data ?? [];
          if (duas.isEmpty) {
            return const Center(child: Text('No duas in this category yet'));
          }
          return ListView.separated(
            itemCount: duas.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dua = duas[index];
              return ListTile(
                title: Text(dua.displayTitle()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/dua-detail',
                  arguments: dua,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
