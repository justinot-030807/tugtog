import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../domain/models/song.dart';
import '../../../domain/models/track.dart';
import '../../../domain/sources/music_source.dart';

/// Concrete MusicSource implementation for the Jamendo v3.0 royalty-free music API.
class JamendoSource implements MusicSource {
  final Dio _dio;
  final String? _clientIdOverride;

  static const String _defaultClientId = '56d30c95';
  static const String _baseUrl = 'https://api.jamendo.com/v3.0/tracks/';

  JamendoSource({
    Dio? dio,
    String? clientId,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
              ),
            ),
        _clientIdOverride = clientId;

  @override
  String get sourceId => 'jamendo';

  @override
  String get displayName => 'Jamendo';

  /// Resolves the Jamendo API client ID from .env with fallback.
  String get clientId {
    final overrideId = _clientIdOverride;
    if (overrideId != null && overrideId.isNotEmpty) {
      return overrideId;
    }
    final envId = dotenv.env['JAMENDO_CLIENT_ID'];
    if (envId != null && envId.trim().isNotEmpty) {
      return envId.trim();
    }
    return _defaultClientId;
  }

  /// Maps a Jamendo JSON track to Song and Track domain entities.
  Song mapJsonToSong(Map<String, dynamic> item) {
    final rawId = item['id']?.toString() ?? '0';
    final intId = int.tryParse(rawId) ?? rawId.hashCode;
    final title = (item['name'] as String?)?.trim() ?? 'Untitled Track';
    final artist = (item['artist_name'] as String?)?.trim() ?? 'Unknown Artist';
    final album = (item['album_name'] as String?)?.trim() ?? 'Jamendo Release';
    final durationSec = item['duration'] as int? ?? 0;
    final audioStreamUrl = item['audio'] as String? ?? '';
    final artworkUrl = (item['image'] ?? item['album_image']) as String?;

    return Song(
      id: intId,
      title: title,
      artist: artist,
      album: album,
      duration: Duration(seconds: durationSec),
      data: audioStreamUrl,
      artworkUrl: artworkUrl,
      sourceType: AudioSourceType.jamendo,
    );
  }

  @override
  Future<List<Track>> search(String query) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'client_id': clientId,
          'format': 'jsonpretty',
          'limit': 20,
          'namesearch': query,
          'order': 'popularity_total',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final results = response.data['results'] as List? ?? [];
        return results
            .map((item) => mapJsonToSong(item as Map<String, dynamic>).toTrack())
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<Track>> getTrending({
    int page = 1,
    int limit = 20,
    String? genre,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'client_id': clientId,
        'format': 'jsonpretty',
        'limit': limit,
        'offset': (page - 1) * limit,
        'order': 'popularity_week',
      };

      if (genre != null && genre.isNotEmpty && genre.toLowerCase() != 'all') {
        queryParams['tags'] = genre;
      }

      final response = await _dio.get(
        _baseUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final results = response.data['results'] as List? ?? [];
        return results
            .map((item) => mapJsonToSong(item as Map<String, dynamic>).toTrack())
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<Track>> getRecentlyPlayed() async {
    return await getTrending(limit: 15);
  }
}
