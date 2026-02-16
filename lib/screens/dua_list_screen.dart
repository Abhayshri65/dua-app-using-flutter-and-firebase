import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/dua.dart';
import '../services/firestore_service.dart';

class DuaListScreen extends StatelessWidget {
  const DuaListScreen({
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
                      subcategoryName,
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
              child: StreamBuilder<List<Dua>>(
                stream: service.watchDuasBySubcategory(subcategoryId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load duas'));
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(child: Text('No duas found'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final dua = items[index];
                      return _DuaListCard(
                        index: index + 1,
                        title: dua.title,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/dua-detail',
                            arguments: dua,
                          );
                        },
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

class _DuaListCard extends StatefulWidget {
  const _DuaListCard({
    required this.index,
    required this.title,
    required this.onTap,
  });

  final int index;
  final String title;
  final VoidCallback onTap;

  @override
  State<_DuaListCard> createState() => _DuaListCardState();
}

class _DuaListCardState extends State<_DuaListCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.99 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onHighlightChanged: (value) {
              setState(() => _pressed = value);
            },
            onTap: widget.onTap,
            child: Container(
              height: 78,
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
