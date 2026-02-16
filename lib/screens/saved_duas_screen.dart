import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/dua_user_actions_service.dart';
import '../services/firestore_service.dart';

class SavedDuasScreen extends StatelessWidget {
  const SavedDuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = DuaUserActionsService();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2C7B8),
              Color(0xFFE6D3D0),
              Color(0xFFD6E2F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Row(
                  children: [
                    _BackButtonCircle(onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Saved Duas',
                          style: GoogleFonts.patrickHand(
                            fontSize: 40,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<UserDuaMeta>>(
                  stream: actions.savedStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Failed to load saved duas'),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'No saved duas yet',
                          style: GoogleFonts.patrickHand(
                            fontSize: 24,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final title = item.duaTitle?.isNotEmpty == true
                            ? item.duaTitle!
                            : item.title;
                        return _SavedDuaCard(
                          index: index + 1,
                          title: title,
                          onTap: () async {
                            final dua = await FirestoreService()
                                .getDuaById(item.id);
                            if (!context.mounted) return;
                            if (dua == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dua not found'),
                                ),
                              );
                              return;
                            }
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
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButtonCircle extends StatelessWidget {
  const _BackButtonCircle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.arrow_back, color: Color(0xFF1F1F1F)),
        ),
      ),
    );
  }
}

class _SavedDuaCard extends StatefulWidget {
  const _SavedDuaCard({
    required this.index,
    required this.title,
    required this.onTap,
  });

  final int index;
  final String title;
  final VoidCallback onTap;

  @override
  State<_SavedDuaCard> createState() => _SavedDuaCardState();
}

class _SavedDuaCardState extends State<_SavedDuaCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _pressed ? 0.99 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.55),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onHighlightChanged: (value) {
              setState(() => _pressed = value);
            },
            onTap: widget.onTap,
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1F1F1F).withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.index.toString(),
                      style: GoogleFonts.patrickHand(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F1F1F),
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
                        color: const Color(0xFF1F1F1F),
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
