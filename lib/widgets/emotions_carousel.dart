import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/emotion.dart';
import '../services/emotion_service.dart';

class EmotionsCarousel extends StatelessWidget {
  const EmotionsCarousel({
    super.key,
    required this.onEmotionTap,
  });

  final ValueChanged<String> onEmotionTap;

  @override
  Widget build(BuildContext context) {
    final service = EmotionService();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emotions',
          style: GoogleFonts.notoSans(
            fontSize: 50,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "I'm Feeling...",
          style: GoogleFonts.notoSans(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.86),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 82,
          child: StreamBuilder<List<Emotion>>(
            stream: service.watchEmotions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _EmotionSkeletonRow();
              }
              if (snapshot.hasError) {
                return _EmotionList(
                  labels: EmotionService.defaultEmotions,
                  onTap: onEmotionTap,
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No emotions yet',
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                );
              }
              return _EmotionList(
                labels: items.map((e) => e.name).toList(),
                onTap: onEmotionTap,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmotionList extends StatelessWidget {
  const _EmotionList({
    required this.labels,
    required this.onTap,
  });

  final List<String> labels;
  final ValueChanged<String> onTap;

  static const List<List<Color>> _gradients = [
    [Color(0xFFF6D8CF), Color(0xFFE5C6BB)],
    [Color(0xFFE6DDFE), Color(0xFFD9E0FF)],
    [Color(0xFFD2F4E8), Color(0xFFC6F0E1)],
    [Color(0xFFFCE2CF), Color(0xFFF3D3BD)],
    [Color(0xFFDEE7FF), Color(0xFFD3DAF2)],
    [Color(0xFFDDF7F0), Color(0xFFD1EEDF)],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      primary: false,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: labels.length,
      itemBuilder: (context, index) {
        final gradient = _gradients[index % _gradients.length];
        return Padding(
          padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onTap(labels[index]),
            child: Container(
              width: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                labels[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmotionSkeletonRow extends StatelessWidget {
  const _EmotionSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 12),
          child: Container(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
