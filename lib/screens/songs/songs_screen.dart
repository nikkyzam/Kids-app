import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/songs_data.dart';
import '../../models/song.dart';
import '../../providers/profile_provider.dart';
import '../../services/youtube_service.dart';
import '../../theme/app_theme.dart';
import 'song_player_screen.dart';

/// The song list: what to sing today, and a way to find the tune.
///
/// The words ship with the app and work with no network at all. YouTube is the
/// optional half — a parent who wants the melody searches for it, or pastes a
/// link to a recording they already like.
class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> {
  final _searchController = TextEditingController();
  final _service = YouTubeService();

  String _query = '';
  bool _onlineMode = false;
  bool _searching = false;
  String? _error;
  List<YouTubeVideo> _results = const [];

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  /// Handles whatever the parent typed: a pasted YouTube link opens straight
  /// away, anything else is either a filter over the built-in songs or a
  /// YouTube search.
  Future<void> _submit(String raw) async {
    final pastedId = YouTubeService.videoIdFrom(raw);
    if (pastedId != null) {
      _openVideo(pastedId, title: 'Pasted link');
      return;
    }
    if (!_onlineMode) return;

    setState(() {
      _searching = true;
      _error = null;
      _results = const [];
    });
    try {
      final videos = await _service.search(raw);
      if (!mounted) return;
      setState(() => _results = videos);
    } on YouTubeUnavailable catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _openVideo(String videoId, {Song? song, String? title}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SongPlayerScreen(
        videoId: videoId,
        song: song,
        videoTitle: title,
      ),
    ));
  }

  /// Opens a built-in song by searching YouTube for its recommended query.
  ///
  /// With no API key the search cannot run, so the parent is offered the words
  /// alone — which is the part that matters most anyway.
  Future<void> _findTune(Song song) async {
    if (!YouTubeService.isSearchConfigured) {
      _openLyricsOnly(song);
      return;
    }
    setState(() => _searching = true);
    try {
      final videos = await _service.search(song.searchQuery, maxResults: 1);
      if (!mounted) return;
      if (videos.isEmpty) {
        _openLyricsOnly(song);
      } else {
        _openVideo(videos.first.videoId, song: song);
      }
    } on YouTubeUnavailable {
      if (mounted) _openLyricsOnly(song);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _openLyricsOnly(Song song) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LyricsOnlyScreen(song: song),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().activeProfile;
    final ageWeeks = profile?.contentAgeInWeeks ?? 0;

    final songs =
        _query.isEmpty ? SongsData.forAge(ageWeeks) : SongsData.search(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Songs')),
      body: Column(
        children: [
          _buildSearchBar(context),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _onlineMode
                ? _buildOnlineResults(context)
                : _buildCatalogue(context, songs, ageWeeks),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: _onlineMode
                  ? 'Search YouTube, or paste a link'
                  : 'Find a song, or paste a YouTube link',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _query = '';
                          _results = const [];
                          _error = null;
                        });
                      },
                    ),
            ),
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: _submit,
          ),
          const SizedBox(height: 8),
          // Said plainly and before anything plays: the rest of the app has no
          // ads and no tracking, and the moment a song starts that stops being
          // true, because the player is Google's.
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppTheme.textMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Songs play in YouTube’s player, which shows ads and tracks '
                  'viewing. The words below work offline, with neither.',
                  style: TextStyle(
                      fontSize: 11, height: 1.35, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Our songs'),
                selected: !_onlineMode,
                onSelected: (_) => setState(() => _onlineMode = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Search YouTube'),
                selected: _onlineMode,
                onSelected: (_) => setState(() => _onlineMode = true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogue(BuildContext context, List<Song> songs, int ageWeeks) {
    if (songs.isEmpty) {
      return const _Empty(
        icon: Icons.music_note_rounded,
        message: 'No songs match that. Try the YouTube tab, or paste a link.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _SongTile(
        song: songs[i],
        onPlay: () => _findTune(songs[i]),
        onWords: () => _openLyricsOnly(songs[i]),
      ),
    );
  }

  Widget _buildOnlineResults(BuildContext context) {
    if (_error != null) {
      return _Empty(icon: Icons.cloud_off_rounded, message: _error!);
    }
    if (!YouTubeService.isSearchConfigured) {
      return const _Empty(
        icon: Icons.key_off_rounded,
        message: 'Song search is not set up in this build.\n'
            'You can still paste a YouTube link into the box above.',
      );
    }
    if (_results.isEmpty) {
      return const _Empty(
        icon: Icons.search_rounded,
        message: 'Search for a song, or paste a link to one you already like.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final video = _results[i];
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: video.thumbnailUrl.isEmpty
                ? const Icon(Icons.music_video_rounded)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(video.thumbnailUrl,
                        width: 72,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.music_video_rounded)),
                  ),
            title:
                Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(video.channel,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _openVideo(video.videoId, title: video.title),
          ),
        );
      },
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onPlay;
  final VoidCallback onWords;

  const _SongTile({
    required this.song,
    required this.onPlay,
    required this.onWords,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${song.skillCategory.label} · '
                        '${song.parts.length} part'
                        '${song.parts.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(song.why,
                style: const TextStyle(
                    fontSize: 13, height: 1.45, color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWords,
                    icon: const Icon(Icons.lyrics_outlined, size: 18),
                    label: const Text('Words'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Play'),
                    style:
                        FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The song with no player at all — the offline half of the feature.
class _LyricsOnlyScreen extends StatelessWidget {
  final Song song;
  const _LyricsOnlyScreen({required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(song.why,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: AppTheme.textMuted)),
          const SizedBox(height: 20),
          for (final part in song.parts)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(part.label.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    Text(part.text,
                        style: const TextStyle(fontSize: 15, height: 1.5)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String message;
  const _Empty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
