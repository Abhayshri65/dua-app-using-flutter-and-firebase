import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/subcategory.dart';
import '../services/subcategory_service.dart';

class SubcategoriesScreen extends StatefulWidget {
  const SubcategoriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  final _service = SubcategoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF7F7F7),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF3A7BD5),
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.categoryName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.patrickHand(
                        fontSize: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Subcategory>>(
                stream: _service.watchSubcategoriesByCategory(widget.categoryId),
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
                    return const Center(
                      child: Text('Failed to load subcategories'),
                    );
                  }
                  final subcategories = snapshot.data ?? [];
                  if (subcategories.isEmpty) {
                    return const Center(child: Text('No subcategories yet'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                    itemCount: subcategories.length,
                    itemBuilder: (context, index) {
                      final sub = subcategories[index];
                      return _SubcategoryRow(
                        index: index + 1,
                        title: sub.name,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/duaList',
                          arguments: {
                            'subcategoryId': sub.id,
                            'subcategoryName': sub.name,
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              height: 70,
              color: const Color(0xFF3A7BD5),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubcategoryRow extends StatefulWidget {
  const _SubcategoryRow({
    required this.index,
    required this.title,
    required this.onTap,
  });

  final int index;
  final String title;
  final VoidCallback onTap;

  @override
  State<_SubcategoryRow> createState() => _SubcategoryRowState();
}

class _SubcategoryRowState extends State<_SubcategoryRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.99 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            debugPrint('Tapped subcategory: ${widget.title}');
            widget.onTap();
          },
          borderRadius: BorderRadius.circular(26),
          onHighlightChanged: (value) {
            setState(() => _pressed = value);
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              height: 78,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E5E2),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.black.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.index.toString(),
                      style: GoogleFonts.patrickHand(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.patrickHand(
                        fontSize: 24,
                        color: const Color(0xFF2B2B2B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
