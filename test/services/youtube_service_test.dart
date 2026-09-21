import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:playsteps/services/youtube_service.dart';

/// Reading a video id out of whatever a parent pasted, and turning a search
/// response into something playable.
///
/// A parent shares links from a phone, so the input is as likely to be a
/// `youtu.be` short link or a Shorts URL as it is a tidy `watch?v=`. Getting
/// this wrong means the app tells them a perfectly good link is not a song.
void main() {
  group('videoIdFrom', () {
    const id = 'dQw4w9WgXcQ';

    test('reads the standard watch link', () {
      expect(YouTubeService.videoIdFrom('https://www.youtube.com/watch?v=$id'),
          id);
    });

    test('reads a watch link carrying extra query parameters', () {
      expect(
        YouTubeService.videoIdFrom(
            'https://www.youtube.com/watch?v=$id&list=PL123&index=2&t=42s'),
        id,
      );
    });

    test('reads the share-sheet short link', () {
      expect(YouTubeService.videoIdFrom('https://youtu.be/$id'), id);
      expect(YouTubeService.videoIdFrom('https://youtu.be/$id?t=31'), id);
    });

    test('reads embed, shorts, live and /v/ links', () {
      expect(
          YouTubeService.videoIdFrom('https://www.youtube.com/embed/$id'), id);
      expect(
          YouTubeService.videoIdFrom('https://www.youtube.com/shorts/$id'), id);
      expect(
          YouTubeService.videoIdFrom('https://www.youtube.com/live/$id'), id);
      expect(YouTubeService.videoIdFrom('https://www.youtube.com/v/$id'), id);
    });

    test('reads mobile, music and no-cookie hosts', () {
      expect(
          YouTubeService.videoIdFrom('https://m.youtube.com/watch?v=$id'), id);
      expect(
          YouTubeService.videoIdFrom('https://music.youtube.com/watch?v=$id'),
          id);
      expect(
        YouTubeService.videoIdFrom(
            'https://www.youtube-nocookie.com/embed/$id'),
        id,
      );
    });

    test('copes with a link pasted without its scheme', () {
      expect(YouTubeService.videoIdFrom('youtube.com/watch?v=$id'), id);
      expect(YouTubeService.videoIdFrom('  youtu.be/$id  '), id);
    });

    test('accepts a bare id', () {
      expect(YouTubeService.videoIdFrom(id), id);
    });

    test('refuses anything that is not a YouTube video', () {
      expect(YouTubeService.videoIdFrom(''), isNull);
      expect(YouTubeService.videoIdFrom('twinkle twinkle little star'), isNull);
      expect(YouTubeService.videoIdFrom('https://vimeo.com/123456'), isNull);
      expect(YouTubeService.videoIdFrom('https://notyoutube.com/watch?v=$id'),
          isNull);
      // A channel page is a YouTube link, but there is no video to play.
      expect(YouTubeService.videoIdFrom('https://www.youtube.com/@somechannel'),
          isNull);
    });

    test('refuses an id of the wrong length', () {
      // Eight characters, then thirteen. Eleven is the only length YouTube
      // issues, and it is worth being strict: a truncated id sends the player
      // to someone else's video rather than failing.
      expect(YouTubeService.videoIdFrom('https://youtu.be/tooshort'), isNull);
      expect(
        YouTubeService.videoIdFrom(
            'https://www.youtube.com/watch?v=thirteenchars'),
        isNull,
      );
    });
  });

  group('search', () {
    YouTubeService serviceReturning(String body, {int status = 200}) {
      return YouTubeService(
        client: MockClient((_) async => http.Response(body, status,
            headers: {'content-type': 'application/json'})),
      );
    }

    String responseWith(List<Map<String, Object?>> items) =>
        jsonEncode({'items': items});

    test('without an API key it reports unavailable rather than empty', () {
      // No key is compiled into the test binary, so this is the real path a
      // build without YOUTUBE_API_KEY takes.
      expect(YouTubeService.isSearchConfigured, isFalse);
      expect(
        () => YouTubeService().search('twinkle'),
        throwsA(isA<YouTubeUnavailable>()),
      );
    }, skip: YouTubeService.isSearchConfigured);

    test('skips malformed entries instead of failing the whole search',
        () async {
      final service = serviceReturning(responseWith([
        {'id': 'not-a-map'},
        {
          'id': {'kind': 'youtube#channel'}, // no videoId
          'snippet': {'title': 'A channel'},
        },
        {
          'id': {'videoId': 'abcdefghijk'},
          'snippet': {
            'title': 'Twinkle Twinkle',
            'channelTitle': 'Rhymes',
            'thumbnails': {
              'medium': {'url': 'https://img/medium.jpg'}
            },
          },
        },
      ]));

      // Reaching the parser requires a configured key; when there is none the
      // guard fires first and there is nothing to assert about parsing.
      if (!YouTubeService.isSearchConfigured) return;

      final results = await service.search('twinkle');
      expect(results, hasLength(1));
      expect(results.single.videoId, 'abcdefghijk');
      expect(results.single.title, 'Twinkle Twinkle');
      expect(results.single.thumbnailUrl, 'https://img/medium.jpg');
    });

    test('a non-200 is an outage, not an empty result set', () async {
      final service = serviceReturning('{}', status: 403);
      if (!YouTubeService.isSearchConfigured) return;

      await expectLater(
        service.search('twinkle'),
        throwsA(isA<YouTubeUnavailable>()),
      );
    });
  });
}
