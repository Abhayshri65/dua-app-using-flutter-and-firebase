import 'package:flutter/material.dart';

import '../models/subcategory.dart';
import '../services/admin_access_service.dart';
import '../services/firestore_service.dart';
import '../services/subcategory_service.dart';
import 'access_denied_screen.dart';

class AdminSubcategoriesScreen extends StatefulWidget {
  const AdminSubcategoriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  State<AdminSubcategoriesScreen> createState() => _AdminSubcategoriesScreenState();
}

class _AdminSubcategoriesScreenState extends State<AdminSubcategoriesScreen> {
  final _service = SubcategoryService();
  final _duaService = FirestoreService();
  final _access = AdminAccessService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAccessResult>(
      future: _access.checkAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final access = snapshot.data;
        if (access == null || !access.isConfigured || !access.isAdmin) {
          return const AccessDeniedScreen();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Subcategories - ${widget.categoryName}'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showSubcategoryDialog(
              context,
              title: 'Add Subcategory',
              successMessage: 'Subcategory added',
              onSave: (name) async {
                await _service.addSubcategory(
                  categoryId: widget.categoryId,
                  name: name,
                );
              },
            ),
            child: const Icon(Icons.add),
          ),
          body: StreamBuilder<List<Subcategory>>(
            stream: _service.watchSubcategoriesByCategory(widget.categoryId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load subcategories'));
              }
              final subcategories = snapshot.data ?? [];
              if (subcategories.isEmpty) {
                return const Center(child: Text('No subcategories yet'));
              }
              return ListView.separated(
                itemCount: subcategories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sub = subcategories[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(sub.name),
                    subtitle: const Text('Admin can edit or delete'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit subcategory',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showSubcategoryDialog(
                            context,
                            title: 'Edit Subcategory',
                            initialValue: sub.name,
                            successMessage: 'Subcategory updated',
                            onSave: (name) async {
                              await _service.updateSubcategory(sub.id, name);
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete subcategory',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, sub),
                        ),
                      ],
                    ),
                    onTap: () => _showSubcategoryDialog(
                      context,
                      title: 'Edit Subcategory',
                      initialValue: sub.name,
                      successMessage: 'Subcategory updated',
                      onSave: (name) async {
                        await _service.updateSubcategory(sub.id, name);
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Subcategory sub) async {
    final count = await _duaService.countDuasInSubcategory(sub.id);
    if (!context.mounted) return;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: subcategory has duas'),
        ),
      );
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subcategory'),
        content: Text(
          'Delete "${sub.name}"?',
        ),
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

    if (result == true) {
      await _service.deleteSubcategory(sub.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subcategory deleted')),
      );
    }
  }
}

Future<void> _showSubcategoryDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
  String? successMessage,
  required Future<void> Function(String name) onSave,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  final formKey = GlobalKey<FormState>();

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    try {
      await onSave(controller.text);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successMessage ??
                (title.toLowerCase().contains('edit')
                    ? 'Subcategory updated'
                    : 'Subcategory added'),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subcategory title',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Subcategory name required';
            }
            return null;
          },
          onFieldSubmitted: (_) => submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: submit,
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

