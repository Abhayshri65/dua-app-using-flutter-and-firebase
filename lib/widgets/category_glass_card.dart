import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category.dart';

class CategoryGlassCard extends StatelessWidget {
  const CategoryGlassCard({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  final List<Category> categories;
  final ValueChanged<Category> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    const cardRadius = 28.0;
    const blurCard = 24.0;
    const cardBgOpacity = 0.26;
    const borderOpacityCard = 0.16;
    const categoryRowHeight = 52.0;
    const categoryRowGap = 10.0;
    const badgeSize = 28.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurCard, sigmaY: blurCard),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(cardBgOpacity),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacityCard),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1C22).withOpacity(0.55),
                const Color(0xFF0F1015).withOpacity(0.35),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: categoryRowGap),
            itemBuilder: (context, index) {
              final title = categories[index];
              return InkWell(
                onTap: () => onCategoryTap(title),
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: categoryRowHeight,
                  child: Row(
                    children: [
                      Container(
                        width: badgeSize,
                        height: badgeSize,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.notoSans(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title.name,
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
