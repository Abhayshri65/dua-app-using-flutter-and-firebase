import 'package:flutter/material.dart';

import '../models/dua.dart';
import '../services/firestore_service.dart';

class SubcategoryDuasScreen extends StatelessWidget {
  const SubcategoryDuasScreen({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  final String subcategoryId;
  final String subcategoryName;

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: Text(subcategoryName)),
      body: StreamBuilder<List<Dua>>(
        stream: service.watchDuasBySubcategory(subcategoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(snapshot.error.toString())),
              );
            });
            return const Center(child: Text('Failed to load duas'));
          }
          final duas = snapshot.data ?? [];
          if (duas.isEmpty) {
            return const Center(child: Text('No duas yet in this subcategory'));
          }
          return ListView.separated(
            itemCount: duas.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dua = duas[index];
              return ListTile(
                title: Text(dua.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/dua-detail',
                  arguments: dua.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
