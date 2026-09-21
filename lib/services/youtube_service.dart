import 'dart:convert';

import 'package:http/http.dart' as http;

/// A video the parent can play.
class YouTubeVideo {
  final String videoId;
  final String title;
  final String channel;
  final String thumbnailUrl;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.thumbnailUrl,
  });
}

/// Raised when a search could not be completed. Never raised for "no results":
/// an empty list is an answer, this is the absence of one.
class YouTubeUnavailable implements Exception {
  final String message;
  const YouTubeUnavailable(this.message);
  @override
  String toString() => message;
}

/// Finding songs on YouTube, and reading a video id out of a pasted link.
///
/// Search goes through the YouTube Data API rather than scraping results,
/// which is both the supported route and the only one that stays within
/// YouTube's terms. Playback is the embedded IFrame player for the same
/// reason: the audio is never downloaded or extracted, only played in place.
class YouTubeService {
  /// Supplied at build time alongside the Supabase keys:
  ///   flutter build --dart-define=YOUTUBE_API_KEY=...
  ///
  /// Absent, search is simply unavailable and the app falls back to the
  /// built-in song list and pasted links — the same graceful degradation the
  /// rest of the app uses for missing cloud credentials.
  static const String apiKey = String.fromEnvironment('YOUTUBE_API_KEY');

  static bool get isSearchConfigured => apiKey.isNotEmpty;

  final http.Client _client;

  YouTubeService({http.Client? client}) : _client = client ?? http.Client();

  /// Pulls the video id out of any of the link shapes YouTube hands out.
  ///
  /// Accepts a bare id too, so a parent who copied just the id from somewhere
  /// is not told their perfectly good input is wrong.
  static String? videoIdFrom(String input) {
    final text = input.trim();
    if (text.isEmpty) return null;

    // A bare id: 11 characters of the YouTube alphabet.
    final bare = RegExp(r'^[A-Za-z0-9_-]{11}$');
    if (bare.hasMatch(text)) return text;

    final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
    if (uri == null) return null;

    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    const hosts = {
      'youtube.com',
      'm.youtube.com',
      'music.youtube.com',
      'youtube-nocookie.com',
      'youtu.be',
    };
    if (!hosts.contains(host)) return null;

    // youtu.be/<id>
    if (host == 'youtu.be') return _validId(uri.pathSegments.firstOrNull);

    // youtube.com/watch?v=<id>
    final v = uri.queryParameters['v'];
    if (v != null) return _validId(v);

    // youtube.com/embed/<id>, /shorts/<id>, /live/<id>, /v/<id>
    const pathPrefixes = {'embed', 'shorts', 'live', 'v'};
    final segments = uri.pathSegments;
    if (segments.length >= 2 && pathPrefixes.contains(segments.first)) {
      return _validId(segments[1]);
    }
    return null;
  }

  static String? _validId(String? candidate) {
    if (candidate == null) return null;
    return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(candidate)
        ? candidate
        : null;
  }

  /// Searches YouTube for [query].
  ///
  /// [safeSearch] is pinned to strict and the category to Music: this is a
  /// children's app, and the default "moderate" is not a setting worth
  /// choosing when the audience is a toddler.
  Future<List<YouTubeVideo>> search(String query, {int maxResults = 15}) async {
    if (!isSearchConfigured) {
      throw const YouTubeUnavailable('Song search is not configured.');
    }
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'q': trimmed,
      'type': 'video',
      'videoCategoryId': '10', // Music
      'videoEmbeddable': 'true', // Unplayable results are worse than none.
      'safeSearch': 'strict',
      'maxResults': '$maxResults',
      'key': apiKey,
    });

    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      throw YouTubeUnavailable('Could not reach YouTube: $e');
    }

    if (response.statusCode != 200) {
      throw YouTubeUnavailable(
          'YouTube search failed (${response.statusCode}).');
    }

    final body = jsonDecode(response.body);
    if (body is! Map || body['items'] is! List) {
      throw const YouTubeUnavailable('YouTube returned an unreadable answer.');
    }

    final videos = <YouTubeVideo>[];
    for (final item in body['items'] as List) {
      if (item is! Map) continue;
      final id = item['id'];
      final snippet = item['snippet'];
      if (id is! Map || snippet is! Map) continue;
      final videoId = id['videoId'];
      if (videoId is! String || videoId.isEmpty) continue;

      videos.add(YouTubeVideo(
        videoId: videoId,
        title: _text(snippet['title']) ?? 'Untitled',
        channel: _text(snippet['channelTitle']) ?? '',
        thumbnailUrl: _thumbnail(snippet['thumbnails']) ?? '',
      ));
    }
    return videos;
  }

  static String? _text(Object? value) => value is String ? value : null;

  static String? _thumbnail(Object? thumbnails) {
    if (thumbnails is! Map) return null;
    for (final size in ['medium', 'high', 'default']) {
      final entry = thumbnails[size];
      if (entry is Map && entry['url'] is String) return entry['url'] as String;
    }
    return null;
  }

  void dispose() => _client.close();
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
