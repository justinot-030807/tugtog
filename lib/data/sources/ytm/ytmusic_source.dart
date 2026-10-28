import 'package:dio/dio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
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

    return Track(
      id: 'ytm_$videoId',
      title: (item['title'] as String?) ?? 'Unknown Title',
      artist: (item['artists'] as String?) ?? 'Unknown Artist',
      album: item['album'] as String?,
      duration: parseDuration(durationStr),
      artworkUrl: item['thumbnail'] as String?,
      sourceType: AudioSourceType.youtubeMusic,
      extraMetadata: {
        'videoId': videoId,
        'played': item['played'],
        'durationText': durationStr,
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

  @override
  Future<List<Track>> search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    // 1. Primary: Direct YouTube search via YoutubeExplode (Works everywhere without backend)
    try {
      final yt = YoutubeExplode();
      try {
        final searchResults = await yt.search.search(cleanQuery);
        if (searchResults.isNotEmpty) {
          return searchResults.map((video) {
            return Track(
              id: 'ytm_${video.id.value}',
              title: video.title,
              artist: video.author,
              duration: video.duration,
              artworkUrl: video.thumbnails.highResUrl,
              sourceType: AudioSourceType.youtubeMusic,
              extraMetadata: {
                'videoId': video.id.value,
                'channelId': video.channelId.value,
                'uploadDate': video.uploadDate?.toIso8601String(),
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
          return Track(
            id: 'ytm_${video.id.value}',
            title: video.title,
            artist: video.author,
            duration: video.duration,
            artworkUrl: video.thumbnails.highResUrl,
            sourceType: AudioSourceType.youtubeMusic,
            extraMetadata: {'videoId': video.id.value},
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
