import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../core/utils/music_classifier.dart';
import '../../../domain/models/track.dart';
import '../../../domain/sources/music_source.dart';
import 'yt_music_auth_service.dart';

/// Concrete MusicSource implementation for YouTube Music.
///
/// Supports direct client-side searching and streaming via [YoutubeExplode],
/// optional direct in-app account login with history extraction, and optional
/// fallback to a local Tugtog FastAPI companion backend.
class YtMusicSource implements MusicSource {
  final Dio _dio;
  final String baseUrl;

  YtMusicSource({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 6),
              ),
            );

  @override
  String get sourceId => 'youtubeMusic';

  @override
  String get displayName => 'YouTube Music';

  /// Parses duration strings like "3:45" or "1:02:15" into a Dart Duration.
  static Duration? parseDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return null;
    try {
      final parts = durationStr.split(':').map((e) => int.parse(e.trim())).toList();
      if (parts.length == 2) {
        return Duration(minutes: parts[0], seconds: parts[1]);
      } else if (parts.length == 3) {
        return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
      }
    } catch (_) {}
    return null;
  }

  /// Map raw API JSON object to unified Track domain model.
  Track _mapJsonToTrack(Map<String, dynamic> item) {
    final videoId = item['videoId'] as String? ?? '';
    final durationStr = item['duration'] as String?;
    final title = (item['title'] as String?) ?? 'Unknown Title';
    final artist = (item['artists'] as String?) ?? 'Unknown Artist';
    final isOriginal = MusicClassifier.isOriginalArtist(artist: artist, author: artist);
    final isAudio = MusicClassifier.isAudioOnly(title: title, author: artist);
    final isMV = MusicClassifier.isMusicVideo(title: title);
    final genre = MusicClassifier.detectGenre(title: title, artist: artist);

    return Track(
      id: 'ytm_$videoId',
      title: title,
      artist: artist,
      album: item['album'] as String?,
      duration: parseDuration(durationStr),
      artworkUrl: item['thumbnail'] as String?,
      sourceType: AudioSourceType.youtubeMusic,
      extraMetadata: {
        'videoId': videoId,
        'played': item['played'],
        'durationText': durationStr,
        'isOfficial': isOriginal,
        'isOriginalArtist': isOriginal,
        'isAudio': isAudio,
        'isMusicVideo': isMV,
        'genre': genre,
      },
    );
  }

  @override
  Future<List<Track>> getRecentlyPlayed() async {
    // 1. Try fetching directly via in-app login cookies first
    final cookies = await YtMusicAuthService.getCookies();
    if (cookies != null && cookies.isNotEmpty) {
      final directHistory = await YtMusicAuthService.fetchHistoryDirect(cookies);
      if (directHistory.isNotEmpty) {
        return directHistory;
      }
    }

    // 2. Fall back to companion FastAPI backend if available
    try {
      final response = await _dio.get('/history');
      if (response.statusCode == 200 && response.data is List) {
        final rawList = response.data as List;
        return rawList
            .map((item) => _mapJsonToTrack(item as Map<String, dynamic>))
            .where((t) => t.extraMetadata['videoId'] != null && t.extraMetadata['videoId'] != '')
            .toList();
      }
    } catch (_) {
      // Backend unavailable; return empty without breaking UI
    }

    return [];
  }

  /// Evaluates whether a video is likely the official/original studio release.
  static bool isOfficialTrack(String title, String author) {
    final lowerTitle = title.toLowerCase();
    final lowerAuthor = author.toLowerCase();

    // 1. YouTube Music auto-generated Topic channels are ALWAYS the official studio releases
    if (lowerAuthor.endsWith(' - topic')) return true;

    // 2. VEVO or verified record label channels
    if (lowerAuthor.contains('vevo') || lowerAuthor.contains('records')) return true;

    // 3. Official indicators in title
    if (lowerTitle.contains('(official audio)') ||
        lowerTitle.contains('[official audio]') ||
        lowerTitle.contains('(official video)') ||
        lowerTitle.contains('[official video]') ||
        lowerTitle.contains('(official music video)') ||
        lowerTitle.contains('[official music video]') ||
        lowerTitle.contains('(visualizer)') ||
        lowerTitle.contains('(audio)')) {
      return true;
    }

    // 4. Penalize if title is an unofficial cover, karaoke, or fan edit
    if (lowerTitle.contains('cover') ||
        lowerTitle.contains('karaoke') ||
        lowerTitle.contains('instrumental') ||
        lowerTitle.contains('remix') ||
        lowerTitle.contains('slowed') ||
        lowerTitle.contains('reverb') ||
        lowerTitle.contains('1 hour') ||
        lowerTitle.contains('bass boosted') ||
        lowerTitle.contains('nightcore') ||
        lowerTitle.contains('mashup') ||
        lowerTitle.contains('reaction')) {
      return false;
    }

    return false;
  }

  static int _computeScore(Video video, String query) {
    final lowerTitle = video.title.toLowerCase();
    final lowerAuthor = video.author.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int score = 0;

    // Keyword match
    if (lowerTitle.contains(lowerQuery)) score += 50;
    if (lowerAuthor.contains(lowerQuery)) score += 30;

    // Official status bonuses
    if (lowerAuthor.endsWith(' - topic')) score += 100;
    if (lowerAuthor.contains('vevo')) score += 80;
    if (lowerTitle.contains('official audio') ||
        lowerTitle.contains('official music video')) {
      score += 60;
    }
    if (lowerTitle.contains('(audio)') || lowerTitle.contains('[audio]')) {
      score += 40;
    }

    // Penalties for covers, karaoke, slowed/reverb when not searched
    if (!lowerQuery.contains('cover') && lowerTitle.contains('cover')) score -= 70;
    if (!lowerQuery.contains('karaoke') && lowerTitle.contains('karaoke')) score -= 80;
    if (!lowerQuery.contains('remix') && lowerTitle.contains('remix')) score -= 50;
    if (!lowerQuery.contains('slowed') &&
        (lowerTitle.contains('slowed') || lowerTitle.contains('reverb'))) {
      score -= 90;
    }
    if (lowerTitle.contains('1 hour') || lowerTitle.contains('10 hour')) score -= 100;
    if (lowerTitle.contains('reaction')) score -= 90;

    return score;
  }

  @override
  Future<List<Track>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // 0. Check for YouTube / YouTube Music Playlist URL or Playlist ID
    final playlistRegex = RegExp(r'[?&]list=([a-zA-Z0-9_-]+)');
    final match = playlistRegex.firstMatch(cleanQuery);
    if (match != null) {
      final playlistId = match.group(1)!;
      try {
        final yt = YoutubeExplode();
        try {
          final playlist = await yt.playlists.get(playlistId);
          final videos =
              await yt.playlists.getVideos(playlistId).take(50).toList();
          return videos.map((video) {
            final cleanArtist = video.author.endsWith(' - Topic')
                ? video.author.replaceAll(' - Topic', '')
                : video.author;
            final isOriginal = MusicClassifier.isOriginalArtist(
                artist: cleanArtist, author: video.author);
            final isAudio = MusicClassifier.isAudioOnly(
                title: video.title, author: video.author);
            final isMV = MusicClassifier.isMusicVideo(title: video.title);
            final genre = MusicClassifier.detectGenre(
                title: video.title, artist: cleanArtist, query: playlist.title);

            return Track(
              id: 'ytm_${video.id.value}',
              title: video.title,
              artist: cleanArtist,
              album: playlist.title,
              duration: video.duration,
              artworkUrl: video.thumbnails.highResUrl,
              sourceType: AudioSourceType.youtubeMusic,
              extraMetadata: {
                'videoId': video.id.value,
                'channelId': video.channelId.value,
                'isOfficial': isOriginal,
                'isOriginalArtist': isOriginal,
                'isAudio': isAudio,
                'isMusicVideo': isMV,
                'genre': genre,
                'playlistTitle': playlist.title,
              },
            );
          }).toList();
        } finally {
          yt.close();
        }
      } catch (_) {}
    }

    // 1. Primary: Direct YouTube search with intelligent official ranking
    try {
      final yt = YoutubeExplode();
      try {
        final searchResults = await yt.search.search(cleanQuery);
        if (searchResults.isNotEmpty) {
          final sortedVideos = searchResults.toList()
            ..sort((a, b) => _computeScore(b, cleanQuery)
                .compareTo(_computeScore(a, cleanQuery)));

          return sortedVideos.map((video) {
            final cleanArtist = video.author.endsWith(' - Topic')
                ? video.author.replaceAll(' - Topic', '')
                : video.author;
            final isOriginal = MusicClassifier.isOriginalArtist(
                artist: cleanArtist, author: video.author);
            final isAudio = MusicClassifier.isAudioOnly(
                title: video.title, author: video.author);
            final isMV = MusicClassifier.isMusicVideo(title: video.title);
            final genre = MusicClassifier.detectGenre(
                title: video.title, artist: cleanArtist, query: cleanQuery);

            return Track(
              id: 'ytm_${video.id.value}',
              title: video.title,
              artist: cleanArtist,
              duration: video.duration,
              artworkUrl: video.thumbnails.highResUrl,
              sourceType: AudioSourceType.youtubeMusic,
              extraMetadata: {
                'videoId': video.id.value,
                'channelId': video.channelId.value,
                'uploadDate': video.uploadDate?.toIso8601String(),
                'isOfficial': isOriginal,
                'isOriginalArtist': isOriginal,
                'isAudio': isAudio,
                'isMusicVideo': isMV,
                'genre': genre,
              },
            );
          }).toList();
        }
      } finally {
        yt.close();
      }
    } catch (_) {
      // Fall through to backend search if available
    }

    // 2. Secondary: Fall back to companion backend if running
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {'q': cleanQuery},
      );
      if (response.statusCode == 200 && response.data is List) {
        final rawList = response.data as List;
        return rawList
            .map((item) => _mapJsonToTrack(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  @override
  Future<List<Track>> getTrending({int page = 1, int limit = 20}) async {
    try {
      final yt = YoutubeExplode();
      try {
        final searchResults = await yt.search.search('OPM and billboard trending music hits');
        return searchResults.take(limit).map((video) {
          final cleanArtist = video.author.endsWith(' - Topic')
              ? video.author.replaceAll(' - Topic', '')
              : video.author;
          final isOriginal = MusicClassifier.isOriginalArtist(
              artist: cleanArtist, author: video.author);
          final isAudio = MusicClassifier.isAudioOnly(
              title: video.title, author: video.author);
          final isMV = MusicClassifier.isMusicVideo(title: video.title);
          final genre = MusicClassifier.detectGenre(
              title: video.title, artist: cleanArtist, query: 'OPM trending');

          return Track(
            id: 'ytm_${video.id.value}',
            title: video.title,
            artist: cleanArtist,
            duration: video.duration,
            artworkUrl: video.thumbnails.highResUrl,
            sourceType: AudioSourceType.youtubeMusic,
            extraMetadata: {
              'videoId': video.id.value,
              'channelId': video.channelId.value,
              'uploadDate': video.uploadDate?.toIso8601String(),
              'isOfficial': isOriginal,
              'isOriginalArtist': isOriginal,
              'isAudio': isAudio,
              'isMusicVideo': isMV,
              'genre': genre,
            },
          );
        }).toList();
      } finally {
        yt.close();
      }
    } catch (_) {
      return [];
    }
  }
}
