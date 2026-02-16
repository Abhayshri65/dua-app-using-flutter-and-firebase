import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/category.dart';
import '../models/subcategory.dart';
import '../models/dua.dart';
import '../models/emotion.dart';
import '../services/category_service.dart';
import '../services/subcategory_service.dart';
import '../services/firestore_service.dart';
import '../services/emotion_service.dart';

class AdminDuaFormScreen extends StatefulWidget {
  const AdminDuaFormScreen({super.key});

  @override
  State<AdminDuaFormScreen> createState() => _AdminDuaFormScreenState();
}

class _AdminDuaFormScreenState extends State<AdminDuaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();

  final _title = TextEditingController();
  final _duaTitle = TextEditingController();
  final _arabic = TextEditingController();
  final _transliteration = TextEditingController();
  final _tags = TextEditingController();
  final _topic = TextEditingController();
  final _audioUrl = TextEditingController();
  final List<_MeaningField> _meaningFields = [];
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  List<Category> _availableCategories = [];
  final List<String> _selectedEmotions = [];

  Dua? _editing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ensureEnglishMeaning();
    CategoryService().seedDefaultCategoriesIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Dua && _editing == null) {
      _editing = args;
      _title.text = args.title;
      _duaTitle.text = args.duaTitle ?? '';
      _arabic.text = args.arabic ?? '';
      _transliteration.text = args.transliteration ?? '';
      _tags.text = args.tags.join(', ');
      _selectedEmotions
        ..clear()
        ..addAll(args.emotions);
      _topic.text = args.topic ?? '';
      _audioUrl.text = args.audioUrl ?? '';
      _selectedCategoryId = args.categoryId;
      _selectedSubcategoryId = args.subcategoryId;
      if (_selectedCategoryId == null &&
          _selectedSubcategoryId != null &&
          _selectedSubcategoryId!.isNotEmpty) {
        _prefillCategoryFromSubcategory(_selectedSubcategoryId!);
      }

      _meaningFields.clear();
      args.meanings.forEach((key, value) {
        _meaningFields.add(
          _MeaningField(
            langController: TextEditingController(text: key),
            meaningController: TextEditingController(text: value),
            locked: key.toLowerCase() == 'en',
          ),
        );
      });
      _ensureEnglishMeaning();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _duaTitle.dispose();
    _arabic.dispose();
    _transliteration.dispose();
    _tags.dispose();
    _topic.dispose();
    _audioUrl.dispose();
    for (final field in _meaningFields) {
      field.dispose();
    }
    super.dispose();
  }

  void _ensureEnglishMeaning() {
    final hasEn = _meaningFields.any(
      (f) => f.langController.text.trim().toLowerCase() == 'en',
    );
    if (!hasEn) {
      _meaningFields.insert(
        0,
        _MeaningField(
          langController: TextEditingController(text: 'en'),
          meaningController: TextEditingController(),
          locked: true,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hasEmotion = _selectedEmotions.isNotEmpty;
    final hasCategory = _selectedCategoryId != null && _selectedCategoryId!.isNotEmpty;
    final hasSubcategory =
        _selectedSubcategoryId != null && _selectedSubcategoryId!.isNotEmpty;

    if (!hasEmotion && !hasCategory && !hasSubcategory) {
      _showSnack(
        'Select at least one: emotion, category, or subcategory',
      );
      return;
    }

    final meaningsResult = _buildMeaningsMap();
    if (meaningsResult == null) return;

    final tags = Dua.normalizeTagsFromInput(_tags.text);
    if (tags.isEmpty) {
      _showSnack('Please add at least one tag');
      return;
    }

    String? selectedCategoryName;
    for (final category in _availableCategories) {
      if (category.id == _selectedCategoryId) {
        selectedCategoryName = category.name;
        break;
      }
    }

    final categoryIds = (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)
        ? <String>[]
        : <String>[_selectedCategoryId!];
    final categoryNames = (selectedCategoryName == null || selectedCategoryName.isEmpty)
        ? <String>[]
        : <String>[selectedCategoryName];

    final data = Dua(
      id: _editing?.id ?? '',
      title: _title.text.trim(),
      duaTitle: _duaTitle.text.trim(),
      topic: _topic.text.trim().isEmpty ? null : _topic.text.trim(),
      tags: tags,
      emotions: List<String>.from(_selectedEmotions),
      categoryId: _selectedCategoryId,
      subcategoryId: _selectedSubcategoryId,
      categoryIds: categoryIds,
      categoryNames: categoryNames,
      arabic: _arabic.text.trim(),
      transliteration: _transliteration.text.trim(),
      meanings: meaningsResult,
      audioUrl: _audioUrl.text.trim().isEmpty ? null : _audioUrl.text.trim(),
      createdAt: _editing?.createdAt,
      updatedAt: _editing?.updatedAt,
    );
    debugPrint(
      'Saving dua with emotions=${data.emotions}, categoryIds=${data.categoryIds}',
    );

    setState(() => _saving = true);
    try {
      if (_editing == null) {
        await _service.addDua(data);
        if (!mounted) return;
        Navigator.pop(context);
        _showSnack('Dua saved successfully');
      } else {
        await _service.updateDua(_editing!.id, data);
        if (!mounted) return;
        Navigator.pop(context);
        _showSnack('Dua updated successfully');
      }
    } catch (e) {
      _showSnack('Failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Map<String, String>? _buildMeaningsMap() {
    final map = <String, String>{};
    for (final field in _meaningFields) {
      final key = field.langController.text.trim().toLowerCase();
      final value = field.meaningController.text.trim();
      if (key.isEmpty || value.isEmpty) {
        _showSnack('Please fill all language fields');
        return null;
      }
      final valid = RegExp(r'^[a-z]{2,5}(-[a-z]{2,5})?$').hasMatch(key);
      if (!valid) {
        _showSnack('Invalid language code: $key');
        return null;
      }
      if (map.containsKey(key)) {
        _showSnack('Duplicate language code: $key');
        return null;
      }
      map[key] = value;
    }
    if (!map.containsKey('en')) {
      _showSnack('English (en) meaning is required');
      return null;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _editing != null;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Dua' : 'Add Dua'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirm = await _confirmDelete(context);
                if (!confirm) return;
                try {
                  await _service.deleteDua(_editing!.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showSnack('Dua deleted');
                } catch (e) {
                  _showSnack('Failed: ${e.toString()}');
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom + 90,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(icon: Icons.info_outline, title: 'Basic'),
                _field(
                  _title,
                  label: 'Title',
                  hint: 'Dua For Stress relief',
                  required: true,
                ),
                _field(
                  _duaTitle,
                  label: 'Dua Title',
                  hint: 'Duʿāʾ of Prophet Mūsā...',
                  required: true,
                ),
                _field(
                  _topic,
                  label: 'Topic (optional)',
                  hint: 'stress relief',
                ),
                _field(
                  _tags,
                  label: 'Tags (comma separated)',
                  hint: 'stress, anxiety, calm',
                  helper: 'Comma separated: stress, anxiety, calm',
                  required: true,
                ),
                const SizedBox(height: 12),
                const _SectionHeader(
                  icon: Icons.category_outlined,
                  title: 'Category',
                ),
                StreamBuilder<List<Category>>(
                  stream: CategoryService().watchCategories(),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    _availableCategories = categories;

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Failed to load categories'),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Optional'),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                          _selectedSubcategoryId = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                const _SectionHeader(
                  icon: Icons.folder_outlined,
                  title: 'Subcategory',
                ),
                StreamBuilder<List<Subcategory>>(
                  stream: _selectedCategoryId == null
                      ? const Stream.empty()
                      : SubcategoryService()
                          .watchSubcategoriesByCategory(_selectedCategoryId!),
                  builder: (context, snapshot) {
                    final subcategories = snapshot.data ?? [];

                    if (_selectedCategoryId == null) {
                      return const Text(
                        'Category is optional. Select category first to choose subcategory.',
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Failed to load subcategories'),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedSubcategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory',
                        border: OutlineInputBorder(),
                      ),
                      items: subcategories
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubcategoryId = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                const _SectionHeader(
                  icon: Icons.menu_book_outlined,
                  title: 'Content',
                ),
                const _SectionHeader(
                  icon: Icons.mood,
                  title: 'Emotions',
                ),
                StreamBuilder<List<Emotion>>(
                  stream: EmotionService().watchEmotions(),
                  builder: (context, snapshot) {
                    final emotions = snapshot.data ?? [];

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Failed to load emotions'),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: emotions.map((emotion) {
                        final selected =
                            _selectedEmotions.contains(emotion.name);
                        return FilterChip(
                          label: Text(emotion.name),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedEmotions.add(emotion.name);
                              } else {
                                _selectedEmotions.remove(emotion.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
                if (_selectedEmotions.isEmpty &&
                    (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) &&
                    (_selectedSubcategoryId == null ||
                        _selectedSubcategoryId!.isEmpty))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Choose emotion, category, or subcategory',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                const SizedBox(height: 12),
                _field(
                  _arabic,
                  label: 'Arabic',
                  hint: 'Arabic text',
                  required: true,
                  minLines: 4,
                  maxLines: 8,
                ),
                _field(
                  _transliteration,
                  label: 'Transliteration',
                  hint: 'Rabbi shrah li sadri...',
                  required: true,
                  minLines: 4,
                  maxLines: 8,
                ),
                const SizedBox(height: 12),
                const _SectionHeader(icon: Icons.translate, title: 'Meanings'),
                ..._meaningFields.map(_meaningRow),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addLanguageField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Language'),
                  ),
                ),
                const SizedBox(height: 12),
                const _SectionHeader(
                  icon: Icons.volume_up_outlined,
                  title: 'Audio',
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _audioUrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Audio URL (optional)',
                      hintText: 'Paste GitHub RAW mp3 link',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black87),
                      ),
                    ),
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.isEmpty) return null;
                      if (!trimmed.startsWith('http://') &&
                          !trimmed.startsWith('https://')) {
                        return 'Must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _audioUrl.text.trim().isNotEmpty
                        ? 'Audio attached ✅'
                        : 'No audio attached',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Update Dua' : 'Save Dua'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _meaningRow(_MeaningField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: TextFormField(
              controller: field.langController,
              enabled: !field.locked,
              maxLength: 5,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z-]')),
              ],
              decoration: InputDecoration(
                labelText: 'Code',
                counterText: '',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: field.meaningController,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Meaning',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: field.locked
                ? null
                : () {
                    setState(() {
                      _meaningFields.remove(field);
                      field.dispose();
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller, {
    required String label,
    String? hint,
    String? helper,
    bool required = false,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black87),
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  void _addLanguageField() {
    setState(() {
      _meaningFields.add(
        _MeaningField(
          langController: TextEditingController(),
          meaningController: TextEditingController(),
        ),
      );
    });
  }

  Future<void> _prefillCategoryFromSubcategory(String subcategoryId) async {
    final sub = await SubcategoryService().getSubcategoryById(subcategoryId);
    if (sub == null) return;
    if (!mounted) return;
    setState(() {
      _selectedCategoryId = sub.categoryId;
    });
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MeaningField {
  _MeaningField({
    required this.langController,
    required this.meaningController,
    this.locked = false,
  });

  final TextEditingController langController;
  final TextEditingController meaningController;
  final bool locked;

  void dispose() {
    langController.dispose();
    meaningController.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

