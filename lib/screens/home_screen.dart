import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category.dart';
import '../services/admin_access_service.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/notification_service.dart';
import '../widgets/category_row.dart';
import '../widgets/emotions_carousel.dart';
import '../widgets/glass_search_bar.dart';
import '../widgets/home_background.dart';
// Old hover/particle effects removed. No fog/particle widgets are referenced.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _searchFocus;
  final _categoryService = CategoryService();
  final _notificationService = NotificationService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _searchFocus = FocusNode();
    _categoryService.seedDefaultCategoriesIfNeeded();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  void _submitSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }
    Navigator.pushNamed(context, '/search', arguments: trimmed);
  }

  void _openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  void _openCategory(BuildContext context, Category category) {
    Navigator.pushNamed(
      context,
      '/subcategories',
      arguments: {'categoryId': category.id, 'categoryName': category.name},
    );
  }

  void _openEmotionDuas(BuildContext context, String emotionName) {
    Navigator.pushNamed(
      context,
      '/emotion-duas',
      arguments: {'emotionName': emotionName},
    );
  }

  @override
  Widget build(BuildContext context) {
    const pagePadding = 16.0;
    const topSpacingBeforeSearch = 22.0;
    const iconBoxSize = 54.0;
    const iconRadius = 15.0;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A3C),
      drawer: _GlassDrawer(
        currentRoute: currentRoute,
        onNavigate: _navigate,
        notificationService: _notificationService,
        authService: _authService,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: HomeBackground()),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: topSpacingBeforeSearch),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) => _TopIconTile(
                          icon: Icons.menu_rounded,
                          size: iconBoxSize,
                          radius: iconRadius,
                          onTap: () => _openDrawer(context),
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: _notificationService.watchUnreadCount(
                          _authService.currentUser?.uid,
                        ),
                        builder: (context, notificationSnapshot) {
                          final count = notificationSnapshot.data ?? 0;
                          return _TopIconTile(
                            icon: Icons.notifications_none_rounded,
                            size: iconBoxSize,
                            radius: iconRadius,
                            badgeCount: count,
                            onTap: () => _navigate(context, '/notifications'),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GlassSearchBar(
                    controller: _controller,
                    focusNode: _searchFocus,
                    onSubmit: _submitSearch,
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'For Everything',
                      style: GoogleFonts.caveat(
                        fontSize: 45,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  EmotionsCarousel(
                    onEmotionTap: (emotionName) =>
                        _openEmotionDuas(context, emotionName),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Category>>(
                      stream: _categoryService.watchCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Failed to load categories'),
                          );
                        }
                        final categories = snapshot.data ?? [];
                        if (categories.isEmpty) {
                          return const Center(
                            child: Text('No categories available'),
                          );
                        }
                        return ListView.separated(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(bottom: 18),
                          itemCount: categories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            return CategoryRow(
                              index: index + 1,
                              title: category.name,
                              onTap: () => _openCategory(context, category),
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
        ],
      ),
    );
  }
}

class _TopIconTile extends StatelessWidget {
  const _TopIconTile({
    required this.icon,
    required this.size,
    required this.radius,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final double size;
  final double radius;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: const Color(0xFF111D44),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: _DrawerBadge(count: badgeCount),
          ),
      ],
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF768ABF),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _HomeHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

class _GlassDrawer extends StatelessWidget {
  const _GlassDrawer({
    required this.currentRoute,
    required this.onNavigate,
    required this.notificationService,
    required this.authService,
  });

  final String currentRoute;
  final void Function(BuildContext, String) onNavigate;
  final NotificationService notificationService;
  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.78;
    const drawerRadius = Radius.circular(32);
    const drawerBorderRadius = BorderRadius.only(
      topLeft: Radius.zero,
      bottomLeft: Radius.zero,
      topRight: drawerRadius,
      bottomRight: drawerRadius,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: drawerBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6F7FA6).withOpacity(0.45),
                borderRadius: drawerBorderRadius,
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(6, 8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _GlassDrawerHeader(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        children: [
                          _GlassDrawerItem(
                            icon: Icons.home_outlined,
                            label: 'Home',
                            selected: currentRoute == '/',
                            onTap: () => onNavigate(context, '/'),
                          ),
                          _GlassDrawerItem(
                            icon: Icons.favorite_border_rounded,
                            label: 'Favorites',
                            selected: currentRoute == '/favorites',
                            onTap: () => onNavigate(context, '/favorites'),
                          ),
                          _GlassDrawerItem(
                            icon: Icons.category_outlined,
                            label: 'Categories',
                            selected: currentRoute == '/categories',
                            onTap: () => onNavigate(context, '/categories'),
                          ),
                          _GlassDrawerItem(
                            icon: Icons.wb_sunny_outlined,
                            label: 'Daily Dua',
                            selected: currentRoute == '/notifications',
                            onTap: () => onNavigate(context, '/notifications'),
                            trailing: StreamBuilder<int>(
                              stream: notificationService.watchUnreadCount(
                                authService.currentUser?.uid,
                              ),
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                if (count <= 0) return const SizedBox.shrink();
                                return _DrawerBadge(count: count);
                              },
                            ),
                          ),
                          _GlassDrawerItem(
                            icon: Icons.bookmark_border_rounded,
                            label: 'Saved Duas',
                            selected: currentRoute == '/saved_duas',
                            onTap: () => onNavigate(context, '/saved_duas'),
                          ),
                          _GlassDrawerItem(
                            icon: Icons.mood,
                            label: 'Emotions',
                            selected: currentRoute == '/emotions',
                            onTap: () => onNavigate(context, '/emotions'),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0x26FFFFFF),
                            ),
                          ),
                          _GlassDrawerItem(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            selected: currentRoute == '/settings',
                            onTap: () => onNavigate(context, '/settings'),
                          ),
                          _AdminDrawerItem(
                            onNavigate: onNavigate,
                            currentRoute: currentRoute,
                            glass: true,
                          ),
                          _GlassDrawerItem(
                            icon: Icons.info_outline_rounded,
                            label: 'About',
                            selected: currentRoute == '/about',
                            onTap: () => onNavigate(context, '/about'),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassDrawerHeader extends StatelessWidget {
  const _GlassDrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            Positioned(
              right: -8,
              top: -8,
              child: Icon(
                Icons.brightness_2_outlined,
                size: 60,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            Text(
              'Dua App',
              style: GoogleFonts.notoSans(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassDrawerItem extends StatefulWidget {
  const _GlassDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.selected,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Widget? trailing;

  @override
  State<_GlassDrawerItem> createState() => _GlassDrawerItemState();
}

class _GlassDrawerItemState extends State<_GlassDrawerItem> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;
    final baseOpacity = widget.selected ? 0.28 : 0.2;
    final opacity = active ? baseOpacity + 0.06 : baseOpacity;
    final borderOpacity = active ? 0.22 : 0.14;
    final scale = active ? 1.02 : 1.0;
    final translateY = active ? -2.0 : 0.0;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          Navigator.pop(context);
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, translateY, 0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: scale,
            child: Container(
              height: 58,
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(borderOpacity),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.notoSans(
                        fontSize: 19,
                        fontWeight:
                            widget.selected ? FontWeight.w600 : FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    required this.size,
    required this.radius,
    required this.color,
    this.badgeCount = 0,
  });

  final IconData icon;
  final double size;
  final double radius;
  final Color color;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.black,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: _DrawerBadge(count: badgeCount),
          ),
      ],
    );
  }
}

class _IconBoxInteractive extends StatefulWidget {
  const _IconBoxInteractive({
    required this.icon,
    required this.size,
    required this.radius,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final double size;
  final double radius;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_IconBoxInteractive> createState() => _IconBoxInteractiveState();
}

class _IconBoxInteractiveState extends State<_IconBoxInteractive> {
  bool _hovered = false;
  bool _pressed = false;

  void _setHovered(bool value) {
    setState(() => _hovered = value);
  }

  void _setPressed(bool value) {
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: active ? 1.03 : 1.0,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 140),
            turns: active ? 2 / 360 : 0,
            child: _IconBox(
              icon: widget.icon,
              size: widget.size,
              radius: widget.radius,
              color: widget.color,
              badgeCount: widget.badgeCount,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBarInteractive extends StatelessWidget {
  const _SearchBarInteractive({
    required this.focused,
    required this.shimmer,
    required this.pulse,
    required this.height,
    required this.radius,
    required this.color,
    required this.borderColor,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final bool focused;
  final AnimationController shimmer;
  final Animation<double> pulse;
  final double height;
  final double radius;
  final Color color;
  final Color borderColor;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final baseColor = focused ? color.withOpacity(0.98) : color;
    return AnimatedBuilder(
      animation: Listenable.merge([pulse, shimmer]),
      builder: (context, child) {
        final translateY = focused ? -2.0 : 0.0;
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scale: pulse.value,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: focused
                      ? borderColor.withOpacity(0.7)
                      : borderColor.withOpacity(0.45),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: shimmer.value,
                        child: Transform.translate(
                          offset: Offset(
                            (1.0 - shimmer.value) * -120,
                            0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.35),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onSubmitted: onSubmit,
                          style: GoogleFonts.notoSans(
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search Dua',
                            hintStyle: GoogleFonts.notoSans(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => onSubmit(controller.text),
                        icon: const Icon(
                          Icons.search,
                          size: 24,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryTileInteractive extends StatefulWidget {
  const _CategoryTileInteractive({
    required this.index,
    required this.title,
    required this.height,
    required this.borderColor,
    required this.numberBoxSize,
    required this.onTap,
  });

  final int index;
  final String title;
  final double height;
  final Color borderColor;
  final double numberBoxSize;
  final VoidCallback onTap;

  @override
  State<_CategoryTileInteractive> createState() =>
      _CategoryTileInteractiveState();
}

class _CategoryTileInteractiveState extends State<_CategoryTileInteractive> {
  bool _pressed = false;

  void _setPressed(bool value) {
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        splashColor: Colors.black.withOpacity(0.02),
        highlightColor: Colors.black.withOpacity(0.03),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _pressed ? 0.99 : 1.0,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFF8B9CCB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.borderColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                AnimatedPadding(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.only(left: _pressed ? 2 : 0),
                  child: Container(
                    width: widget.numberBoxSize,
                    height: widget.numberBoxSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.index + 1}',
                      style: GoogleFonts.notoSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerBadge extends StatelessWidget {
  const _DrawerBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminDrawerItem extends StatelessWidget {
  const _AdminDrawerItem({
    required this.onNavigate,
    required this.currentRoute,
    this.glass = false,
  });

  final void Function(BuildContext, String) onNavigate;
  final String currentRoute;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminAccessService().checkAccess().then((r) => r.isAdmin),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        if (isAdmin) {
          return _GlassDrawerItem(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin Panel',
            selected: currentRoute == '/admin',
            onTap: () => onNavigate(context, '/admin'),
          );
        }
        return _GlassDrawerItem(
          icon: Icons.lock_rounded,
          label: 'Admin Panel',
          selected: currentRoute == '/admin-login',
          onTap: () => onNavigate(context, '/admin-login'),
        );
      },
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDEE4F5), Color(0xFFE7ECF7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: -4,
            child: Icon(
              Icons.brightness_2_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Dua App',
                style: GoogleFonts.notoSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E2A4A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Peaceful duas for daily life',
                style: GoogleFonts.notoSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1E2A4A).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        text,
        style: GoogleFonts.notoSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF2C3140).withOpacity(0.55),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        'Made with care',
        style: GoogleFonts.notoSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF2C3140).withOpacity(0.45),
        ),
      ),
    );
  }
}
