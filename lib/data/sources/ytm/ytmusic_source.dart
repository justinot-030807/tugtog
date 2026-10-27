import 'package:dio/dio.dart';
import '../../../domain/models/track.dart';
import '../../../domain/sources/music_source.dart';

/// Concrete MusicSource implementation connecting to the local Tugtog FastAPI backend.
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
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
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
    try {
      final response = await _dio.get('/history');
      if (response.statusCode == 200 && response.data is List) {
        final rawList = response.data as List;
        return rawList
            .map((item) => _mapJsonToTrack(item as Map<String, dynamic>))
            .where((t) => t.extraMetadata['videoId'] != null && t.extraMetadata['videoId'] != '')
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final detail = e.response?.data?['detail'] ?? 'YouTube Music session expired.';
        throw Exception(detail);
      }
      throw Exception(
        'Cannot connect to YouTube Music backend at $baseUrl. '
        'Ensure the FastAPI server is running or update the URL in Settings.',
      );
    }
  }

  @override
  Future<List<Track>> search(String query) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200 && response.data is List) {
        final rawList = response.data as List;
        return rawList
            .map((item) => _mapJsonToTrack(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final detail = e.response?.data?['detail'] ?? 'Authentication failed.';
        throw Exception(detail);
      }
      throw Exception('Search error from backend: ${e.message}');
    }
  }

  @override
  Future<List<Track>> getTrending({int page = 1, int limit = 20}) async {
    // Trending songs search via YouTube Music
    return await search('Top trending hits');
  }
}
