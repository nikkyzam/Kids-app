import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../models/song.dart';
import '../../theme/app_theme.dart';

/// Plays one song from YouTube, a section at a time.
///
/// The parts come from [SongSegmenter], which lays the song's known structure
/// over whatever duration the player reports for the recording the parent
/// picked. Nothing is downloaded and no audio is analysed — the segmenting is
/// arithmetic over one number the player already gives us, which is what keeps
/// this inside YouTube's terms.
class SongPlayerScreen extends StatefulWidget {
  /// The song whose structure labels the sections. Null for a video the parent
  /// pasted in, where the sections are just 'Part 1', 'Part 2'…
  final Song? song;

  final String videoId;

  /// Shown as the title when there is no [song].
  final String? videoTitle;

  const SongPlayerScreen({
    super.key,
    required this.videoId,
    this.song,
    this.videoTitle,
  });

  @override
  State<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends State<SongPlayerScreen> {
  late final YoutubePlayerController _controller;
  StreamSubscription<YoutubeVideoState>? _stateSub;

  List<TimedPart> _parts = const [];
  int? _activePart;
  bool _loop = true;
  bool _ready = false;

  /// How many sections to cut an unknown video into.
  static const int _defaultPartCount = 4;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        // youtube-nocookie.com. It does not make an embed private, but it is
        // the least-tracking option YouTube offers, and this is a children's
        // app.
        privacyEnhancedMode: true,
        // Keeps "up next" to the same channel rather than opening the whole
        // recommendation engine to a toddler.
        strictRelatedVideos: true,
        enableCaption: false,
        playsInline: true,
      ),
    );

    _stateSub = _controller.videoStateStream.listen(_onPosition);
    _controller.listen((value) {
      if (value.playerState == PlayerState.cued ||
          value.playerState == PlayerState.playing) {
        _loadParts();
      }
    });
  }

  /// Asks the player how long the recording is and lays the sections over it.
  ///
  /// Called on cue and again on first play: the IFrame API reports 0 until the
  /// video's metadata has actually arrived, so one attempt is not enough.
  Future<void> _loadParts() async {
    if (_ready) return;
    final seconds = await _controller.duration;
    if (!mounted || seconds <= 0) return;

    final total = Duration(milliseconds: (seconds * 1000).round());
    final parts = widget.song != null
        ? SongSegmenter.split(total, widget.song!.parts)
        : SongSegmenter.splitEvenly(total, _defaultPartCount);

    setState(() {
      _parts = parts;
      _ready = parts.isNotEmpty;
    });
  }

  /// Keeps playback inside the selected section.
  void _onPosition(YoutubeVideoState state) {
    final index = _activePart;
    if (index == null || index >= _parts.length) return;

    final part = _parts[index];
    if (state.position < part.end) return;

    if (_loop) {
      _controller.seekTo(
          seconds: part.start.inMilliseconds / 1000, allowSeekAhead: true);
    } else {
      _controller.pauseVideo();
      if (mounted) setState(() => _activePart = null);
    }
  }

  Future<void> _playPart(int index) async {
    final part = _parts[index];
    setState(() => _activePart = index);
    await _controller.seekTo(
        seconds: part.start.inMilliseconds / 1000, allowSeekAhead: true);
    await _controller.playVideo();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.song?.title ?? widget.videoTitle ?? 'Song';

    // YoutubePlayer handles fullscreen itself through an OverlayPortal, so the
    // old scaffold wrapper is neither needed nor supported any more.
    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              child: YoutubePlayer(controller: _controller),
            ),
            const SizedBox(height: 16),
            _buildPartsHeader(context),
            const SizedBox(height: 8),
            _buildPartChips(context),
            const SizedBox(height: 20),
            _buildLyrics(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPartsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text('Sing it in parts',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Row(
            children: [
              const Text('Repeat',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600)),
              Switch.adaptive(
                value: _loop,
                onChanged: (v) => setState(() => _loop = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPartChips(BuildContext context) {
    if (!_ready) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Text(
          'Press play once and the song will split into sections.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _parts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final part = _parts[i];
          final selected = _activePart == i;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => _playPart(i),
            avatar: Icon(
              selected ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
              size: 18,
              color: selected ? Colors.white : AppTheme.primary,
            ),
            label: Text(
              '${part.part.label}  ·  ${_mmss(part.start)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textDark,
              ),
            ),
            selectedColor: AppTheme.primary,
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildLyrics(BuildContext context) {
    final song = widget.song;
    if (song == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'This one came from a link you pasted, so there are no words to '
          'follow — the sections are equal slices of the recording.',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < song.parts.length; i++)
            _LyricBlock(
              part: song.parts[i],
              highlighted: _activePart == i,
              onTap: _ready && i < _parts.length ? () => _playPart(i) : null,
            ),
        ],
      ),
    );
  }

  static String _mmss(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _LyricBlock extends StatelessWidget {
  final SongPart part;
  final bool highlighted;
  final VoidCallback? onTap;

  const _LyricBlock({
    required this.part,
    required this.highlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: highlighted ? AppTheme.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: highlighted ? AppTheme.primary : AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: highlighted ? AppTheme.primary : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                part.text,
                style: const TextStyle(
                    fontSize: 15, height: 1.5, color: AppTheme.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
