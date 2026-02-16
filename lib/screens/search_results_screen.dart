import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/dua.dart';
import '../services/firestore_service.dart';
import '../widgets/flicker_loading_overlay.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _service = FirestoreService();
  late final TextEditingController _controller;
  late final AnimationController _flickerController;
  late final Animation<double> _opacityAnimation;

  bool _isLoading = false;
  String? _error;
  List<Dua> _results = [];
  String? _info;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.35)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.35, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_flickerController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _controller.text.isEmpty) {
      _controller.text = args;
      _info = null;
      _runSearch(args);
    }
  }

  Future<void> _playFlicker() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      await _flickerController.forward(from: 0);
    }
  }

  Future<void> _runSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _info = 'Type something to search';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
      _results = [];
    });

    try {
      final resultsFuture = _service.searchDuas(trimmed);
      await _playFlicker();
      final results = await resultsFuture;
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong';
        _isLoading = false;
      });
    }
  }

  void _submitSearch(String query) {
    _runSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C8FC6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const SizedBox.shrink(),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          const _SearchResultsBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: _QueryCard(
                    controller: _controller,
                    onSearchTap: () => _submitSearch(_controller.text),
                    onSubmitted: _submitSearch,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Search Results',
                      style: GoogleFonts.notoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Stack(
                    children: [
                      _buildResultsArea(),
                      AnimatedBuilder(
                        animation: _opacityAnimation,
                        builder: (context, child) {
                          return FlickerLoadingOverlay(
                            opacity: _isLoading ? _opacityAnimation.value : 0,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const _ResultCard(
            index: -1,
            title: '',
            onTap: null,
            placeholder: true,
          );
        },
      );
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_info != null) {
      return Center(
        child: Text(
          _info!,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            color: const Color(0xFF1C1C1C).withOpacity(0.65),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No duas found for this search.',
          style: GoogleFonts.notoSans(
            fontSize: 16,
            color: const Color(0xFF1C1C1C).withOpacity(0.65),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final dua = _results[index];
        return _ResultCard(
          index: index,
          title: dua.displayTitle(),
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
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.index,
    required this.title,
    required this.onTap,
    this.placeholder = false,
  });

  final int index;
  final String title;
  final VoidCallback? onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final number = (index + 1).toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: _GlassCard(
        height: 70,
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              if (!placeholder)
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E0E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    number,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: placeholder
                    ? Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    : Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1C1C1C),
                        ),
                      ),
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _QueryCard extends StatelessWidget {
  const _QueryCard({
    required this.controller,
    required this.onSearchTap,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final VoidCallback onSearchTap;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF8EA0D0),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFC7D0E8).withOpacity(0.45),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: onSubmitted,
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
            onPressed: onSearchTap,
            icon: const Icon(
              Icons.search,
              size: 24,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.height,
    required this.child,
    this.onTap,
    this.color,
  });

  final double height;
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.black.withOpacity(0.03),
        highlightColor: Colors.black.withOpacity(0.02),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color ?? const Color(0xFF8EA0D0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFB7C3E6).withOpacity(0.6),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SearchResultsBackground extends StatelessWidget {
  const _SearchResultsBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF7C8FC6),
    );
  }
}
