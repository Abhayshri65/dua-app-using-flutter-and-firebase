import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/dua.dart';
import '../services/firestore_service.dart';
import '../services/dua_user_actions_service.dart';
import '../widgets/dua_audio_player.dart';

class DuaDetailScreen extends StatefulWidget {
  const DuaDetailScreen({super.key});

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  String _selectedLang = 'en';
  final _actions = DuaUserActionsService();
  final _firestore = FirestoreService();
  bool _isFavorite = false;
  bool _isSaved = false;
  bool _loadingFavorite = false;
  bool _loadingSaved = false;
  Dua? _dua;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_dua == null) {
      if (args is Dua) {
        _dua = args;
        _initStateChecks(args.id);
      } else if (args is String) {
        return FutureBuilder<Dua?>(
          future: _firestore.getDuaById(args),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const Scaffold(
                body: Center(child: Text('Dua not found')),
              );
            }
            _dua = data;
            _initStateChecks(data.id);
            return _buildDetail(data);
          },
        );
      } else {
        return const Scaffold(
          body: Center(child: Text('Dua not found')),
        );
      }
    }

    return _buildDetail(_dua!);
  }

  Widget _buildDetail(Dua dua) {
    final meaningText = dua.meanings[_selectedLang] ?? '';
    final meaningStyle = _selectedLang == 'ar'
        ? GoogleFonts.notoNaskhArabic(
            fontSize: 24,
            height: 1.8,
            color: Colors.black,
          )
        : GoogleFonts.inter(
            fontSize: 20,
            height: 1.5,
            color: Colors.black,
          );

    return Scaffold(
      backgroundColor: const Color(0xFF8FA6D8),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        InkWell(
                          onTap: () => _shareDua(context, dua),
                          child: Row(
                            children: [
                              Text(
                                'Share',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.ios_share,
                                  size: 22, color: Colors.black),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF1F6),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Center(
                      child: Text(
                        dua.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 96),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4E7EC),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Dua Title :'),
                          const SizedBox(height: 4),
                          Text(
                            dua.duaTitle ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionLabel('Arabic :'),
                          const SizedBox(height: 6),
                          Text(
                            dua.arabic ?? '',
                            style: GoogleFonts.notoNaskhArabic(
                              fontSize: 24,
                              height: 1.8,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionLabel('Transliteration:'),
                          const SizedBox(height: 4),
                          Text(
                            dua.transliteration ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _sectionLabel('Meanings:'),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _pickLanguage(context, dua),
                                child: const Icon(Icons.language,
                                    size: 22, color: Colors.black),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meaningText.isEmpty
                                ? 'No meaning available'
                                : meaningText,
                            style: meaningStyle,
                          ),
                          const SizedBox(height: 24),
                          if (dua.audioUrl != null &&
                              dua.audioUrl!.trim().isNotEmpty) ...[
                            Row(
                              children: [
                                _sectionLabel('Audio'),
                              ],
                            ),
                            const SizedBox(height: 10),
                            DuaAudioPlayer(audioUrl: dua.audioUrl!.trim()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _bottomBar(dua),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 19,
        color: Colors.black,
      ),
    );
  }

  // Audio player is rendered by DuaAudioPlayer when audioUrl is present.

  Widget _bottomBar(Dua dua) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 68,
        color: const Color(0xFF8FA6D8),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: _loadingSaved ? null : () => _toggleSaved(dua),
              child: Row(
                children: [
                  Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _loadingFavorite ? null : () => _toggleFavorite(dua),
              child: Row(
                children: [
                  Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Favorite',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareDua(BuildContext context, Dua dua) {
    final text = [
      dua.title,
      '',
      dua.duaTitle ?? '',
      '',
      dua.arabic ?? '',
      '',
      dua.transliteration ?? '',
      '',
      dua.meanings['en'] ?? '',
    ].join('\n');

    Share.share(text).catchError((_) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dua copied to clipboard')),
      );
    });
  }

  void _pickLanguage(BuildContext context, Dua dua) {
    final keys = dua.meanings.keys.toList();
    if (keys.isEmpty) {
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: keys.map((key) {
            return ListTile(
              title: Text(key.toUpperCase()),
              onTap: () {
                setState(() => _selectedLang = key);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _initStateChecks(String duaId) async {
    final uid = _actions.currentUser?.uid;
    if (uid == null) return;
    final fav = await _actions.isFavorited(duaId);
    final saved = await _actions.isSaved(duaId);
    if (!mounted) return;
    setState(() {
      _isFavorite = fav;
      _isSaved = saved;
    });
  }

  Future<void> _toggleFavorite(Dua dua) async {
    final user = _actions.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }
    setState(() {
      _loadingFavorite = true;
      _isFavorite = !_isFavorite;
    });
    try {
      if (_isFavorite) {
        await _actions.addFavorite(
          duaId: dua.id,
          title: dua.title,
          duaTitle: dua.duaTitle,
          topic: dua.topic,
        );
        _showSnack('Added to Favorites');
      } else {
        await _actions.removeFavorite(dua.id);
        _showSnack('Removed from Favorites');
      }
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite);
      _showSnack('Failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loadingFavorite = false);
      }
    }
  }

  Future<void> _toggleSaved(Dua dua) async {
    final user = _actions.currentUser;
    if (user == null) {
      _showLoginDialog();
      return;
    }
    setState(() {
      _loadingSaved = true;
      _isSaved = !_isSaved;
    });
    try {
      if (_isSaved) {
        await _actions.addSaved(
          duaId: dua.id,
          title: dua.title,
          duaTitle: dua.duaTitle,
          topic: dua.topic,
        );
        _showSnack('Saved for offline reading');
      } else {
        await _actions.removeSaved(dua.id);
        _showSnack('Removed from Saved');
      }
    } catch (e) {
      setState(() => _isSaved = !_isSaved);
      _showSnack('Failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loadingSaved = false);
      }
    }
  }

  void _showLoginDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login required'),
        content: const Text('Please login to save or favorite duas'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

}
