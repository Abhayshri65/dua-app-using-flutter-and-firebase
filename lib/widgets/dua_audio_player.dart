import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class DuaAudioPlayer extends StatefulWidget {
  const DuaAudioPlayer({super.key, required this.audioUrl});

  final String audioUrl;

  @override
  State<DuaAudioPlayer> createState() => _DuaAudioPlayerState();
}

class _DuaAudioPlayerState extends State<DuaAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = true;
  String? _error;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _init();
    _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DuaAudioPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _reloadUrl();
    }
  }

  Future<void> _reloadUrl() async {
    try {
      await _player.stop();
      await _player.setUrl(widget.audioUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load audio';
      });
    }
  }

  Future<void> _init() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setVolume(_volume);
      await _player.setUrl(widget.audioUrl);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load audio';
      });
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _seekRelative(Duration offset) async {
    final position = _player.position;
    final target = position + offset;
    final duration = _player.duration ?? Duration.zero;
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > duration
            ? duration
            : target;
    await _player.seek(clamped);
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Text('Loading audio...');
    }
    if (_error != null) {
      return Row(
        children: [
          const Text('Audio error'),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              setState(() => _loading = true);
              _init();
            },
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<Duration>(
          stream: _player.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final duration = _player.duration ?? Duration.zero;
            return Column(
              children: [
                Slider(
                  min: 0,
                  max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                  value: position.inMilliseconds.toDouble().clamp(
                        0,
                        duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      ),
                  onChanged: (value) {
                    _player.seek(Duration(milliseconds: value.toInt()));
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position)),
                    Text(_formatDuration(duration)),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => _seekRelative(const Duration(seconds: -10)),
              icon: const Icon(Icons.replay_10),
            ),
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                return IconButton(
                  iconSize: 32,
                  onPressed: () {
                    if (playing) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                  },
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                );
              },
            ),
            IconButton(
              onPressed: () => _seekRelative(const Duration(seconds: 10)),
              icon: const Icon(Icons.forward_10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.volume_down),
            Expanded(
              child: Slider(
                min: 0.0,
                max: 1.0,
                value: _volume,
                onChanged: (value) {
                  setState(() => _volume = value);
                  _player.setVolume(value);
                },
              ),
            ),
            const Icon(Icons.volume_up),
          ],
        ),
      ],
    );
  }
}
