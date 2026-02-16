import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/emotion.dart';
import '../services/emotion_service.dart';

class EmotionsScreen extends StatefulWidget {
  const EmotionsScreen({super.key});

  @override
  State<EmotionsScreen> createState() => _EmotionsScreenState();
}

class _EmotionsScreenState extends State<EmotionsScreen> {
  final _service = EmotionService();

  @override
  void initState() {
    super.initState();
    _service.seedDefaultEmotionsIfNeeded();
  }

  static const _headerColor = Color(0xFF7C8FC6);
  static const _backgroundColor = Color(0xFFDDDDDD);
  static const _subtitleColor = Color(0xFF2B2B2B);
  static const _cardColors = [
    Color(0xFFE07C7C),
    Color(0xFFBFA55A),
    Color(0xFFA2D86F),
    Color(0xFF74D67A),
    Color(0xFF78DFC9),
    Color(0xFF7CCDE2),
    Color(0xFFD2E24E),
    Color(0xFF9CDA75),
    Color(0xFF7B8FDF),
    Color(0xFF9A7BE0),
    Color(0xFFF3A6A6),
    Color(0xFFE07BA7),
    Color(0xFFB5D7F2),
    Color(0xFF9ED8D4),
    Color(0xFFE6C27A),
    Color(0xFFB0E08D),
    Color(0xFFF2A97B),
    Color(0xFFB8A2E4),
    Color(0xFF9FD3C7),
    Color(0xFFF2C2D6),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: _headerColor,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Emotions',
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
          Container(
            color: _backgroundColor,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                "I'm Feeling...",
                style: GoogleFonts.patrickHand(
                  fontSize: 24,
                  color: _subtitleColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: _backgroundColor,
              child: StreamBuilder<List<Emotion>>(
                stream: _service.watchEmotions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load emotions'));
                  }
                  final emotions = snapshot.data ?? [];
                  if (emotions.isEmpty) {
                    return const Center(child: Text('No emotions yet'));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    itemCount: emotions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 1.4,
                    ),
                    itemBuilder: (context, index) {
                      final emotion = emotions[index];
                      final color = _cardColors[index % _cardColors.length];
                      return _EmotionCard(
                        title: emotion.name,
                        color: color,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/emotion-duas',
                            arguments: {'emotionName': emotion.name},
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionCard extends StatefulWidget {
  const _EmotionCard({
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_EmotionCard> createState() => _EmotionCardState();
}

class _EmotionCardState extends State<_EmotionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.99 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.patrickHand(
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
