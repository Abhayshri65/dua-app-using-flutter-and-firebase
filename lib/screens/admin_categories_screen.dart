import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/admin_access_service.dart';
import '../services/category_service.dart';
import '../services/subcategory_service.dart';
import 'access_denied_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _access = AdminAccessService();

  @override
  Widget build(BuildContext context) {
    debugPrint('AdminCategoriesScreen loaded');
    return FutureBuilder<AdminAccessResult>(
      future: _access.checkAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final result = snapshot.data;
        if (result == null || !result.isConfigured || !result.isAdmin) {
          return const AccessDeniedScreen();
        }
        debugPrint('isAdmin = true');
        return Scaffold(
          appBar: AppBar(title: const Text('Manage Categories')),
          body: const AdminCategoriesBody(),
          floatingActionButton: const _AddCategoryButton(),
        );
      },
    );
  }
}

class AdminCategoriesBody extends StatefulWidget {
  const AdminCategoriesBody({super.key});

  @override
  State<AdminCategoriesBody> createState() => _AdminCategoriesBodyState();
}

class _AdminCategoriesBodyState extends State<AdminCategoriesBody> {
  final _service = CategoryService();
  final _subService = SubcategoryService();

  @override
  void initState() {
    super.initState();
    _service.seedDefaultCategoriesIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const _AddCategoryButton(),
      body: StreamBuilder<List<Category>>(
        stream: _service.watchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load categories'));
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(category.name),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _showCategoryDialog(
                        context,
                        title: 'Edit Category',
                        initialValue: category.name,
                        successMessage: 'Category updated',
                        onSave: (name) async {
                          await _service.updateCategory(category.id, name);
                        },
                      );
                    } else if (value == 'delete') {
                      await _confirmDelete(context, category);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/admin-subcategories',
                  arguments: {
                    'categoryId': category.id,
                    'categoryName': category.name,
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final subCount = await _subService.countSubcategories(category.id);
    if (subCount > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: category has subcategories'),
        ),
      );
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"?',
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
      await _service.deleteCategory(category.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted')),
      );
    }
  }
}

class _AddCategoryButton extends StatelessWidget {
  const _AddCategoryButton();

  @override
  Widget build(BuildContext context) {
    debugPrint('FAB rendered');
    return FloatingActionButton(
      onPressed: () => _showCreateCategorySheet(context),
      child: const Icon(Icons.add),
    );
  }
}

Future<void> _showCreateCategorySheet(BuildContext context) async {
  final categoryController = TextEditingController();
  final subControllers = <TextEditingController>[
    TextEditingController(),
  ];
  final formKey = GlobalKey<FormState>();
  final service = CategoryService();

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    final subs = subControllers.map((c) => c.text).toList();
    try {
      await service.createCategoryWithSubcategories(
        name: categoryController.text,
        subcategoryNames: subs,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category + subcategories saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Category',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Category title required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Subcategories',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(subControllers.length, (index) {
                      final controller = subControllers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Subcategory name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Subcategory required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: subControllers.length == 1
                                  ? null
                                  : () {
                                      setModalState(() {
                                        subControllers.removeAt(index);
                                      });
                                    },
                            ),
                          ],
                        ),
                      );
                    }),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            subControllers.add(TextEditingController());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Subcategory'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submit,
                        child: const Text('Save Category'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> _showCategoryDialog(
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
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successMessage ??
                  (title.toLowerCase().contains('edit')
                      ? 'Category updated'
                      : 'Category added'),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
            labelText: 'Category title',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Category name required';
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

