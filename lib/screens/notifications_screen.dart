import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/dua_notification.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _service.markAllSeen(_auth.currentUser?.uid);
  }

  @override
  Widget build(BuildContext context) {
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
                          'Notifications',
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
                child: StreamBuilder<List<DuaNotification>>(
                  stream: _service.watchActiveNotifications(),
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
                        child: Text('Failed to load notifications'),
                      );
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications yet',
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
                        return _NotificationCard(
                          title: item.title,
                          message: item.message,
                          onTap: () {
                            if (item.duaId != null && item.duaId!.isNotEmpty) {
                              Navigator.pushNamed(
                                context,
                                '/dua-detail',
                                arguments: item.duaId,
                              );
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/notification-detail',
                                arguments: item,
                              );
                            }
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

class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    required this.title,
    required this.message,
    required this.onTap,
  });

  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
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
              height: 78,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                widget.message.isNotEmpty ? widget.message : widget.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.patrickHand(
                  fontSize: 24,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
