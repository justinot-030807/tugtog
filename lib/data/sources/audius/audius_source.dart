import 'package:dio/dio.dart';
import '../../../domain/models/song.dart';
import '../../../domain/models/track.dart';
import '../../../domain/sources/music_source.dart';

/// Concrete MusicSource implementation for the Audius decentralized streaming API.
class AudiusSource implements MusicSource {
  final Dio _dio;
  final String appName;
  String? _cachedHost;

  static const String _defaultHost = 'https://discoveryprovider.audius.co';

  AudiusSource({
    Dio? dio,
    this.appName = 'tugtog',
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
              ),
            );

  @override
  String get sourceId => 'audius';

  @override
  String get displayName => 'Audius';

  /// Dynamically selects an active Audius Discovery Node.
  Future<String> getHost() async {
    if (_cachedHost != null) return _cachedHost!;

    try {
      final response = await _dio.get('https://api.audius.co');
      if (response.statusCode == 200 && response.data is Map) {
        final hosts = response.data['data'] as List?;
        if (hosts != null && hosts.isNotEmpty) {
          _cachedHost = hosts.first as String;
          return _cachedHost!;
        }
      }
    } catch (_) {
      // Fallback if discovery endpoint is slow or unreachable
    }

    _cachedHost = _defaultHost;
    return _cachedHost!;
  }

  /// Construct the playable audio stream URL for an Audius track.
  String getStreamUrl(String trackId) {
    return 'https://api.audius.co/v1/tracks/$trackId/stream?app_name=$appName';
  }

  /// Maps an Audius JSON track object to Song and Track models.
  Song mapJsonToSong(Map<String, dynamic> item) {
    final trackIdStr = item['id']?.toString() ?? '0';
    final intId = int.tryParse(trackIdStr) ?? trackIdStr.hashCode;
    final title = (item['title'] as String?)?.trim() ?? 'Untitled Track';

    // Artist name from user object
    final user = item['user'];
    final artist = (user is Map ? user['name'] as String? : null)?.trim() ??
        'Unknown Artist';

    // Duration in seconds
    final durationSec = item['duration'] as int? ?? 0;

    // Artwork thumbnail
    final artwork = item['artwork'];
    String? artworkUrl;
    if (artwork is Map) {
      artworkUrl = (artwork['480x480'] ?? artwork['150x150'] ?? artwork['1000x1000'])
          as String?;
    }

    final streamUrl = getStreamUrl(trackIdStr);

    return Song(
      id: intId,
      title: title,
      artist: artist,
      album: (item['genre'] as String?) ?? 'Audius Track',
      duration: Duration(seconds: durationSec),
      data: streamUrl,
      artworkUrl: artworkUrl,
      sourceType: AudioSourceType.audius,
    );
  }

  @override
  Future<List<Track>> search(String query) async {
    final host = await getHost();
    try {
      final response = await _dio.get(
        '$host/v1/tracks/search',
        queryParameters: {
          'query': query,
          'app_name': appName,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as List? ?? [];
        return data
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
    final host = await getHost();
    try {
      final queryParams = <String, dynamic>{
        'app_name': appName,
        'limit': limit,
        'offset': (page - 1) * limit,
      };
      if (genre != null && genre.isNotEmpty && genre.toLowerCase() != 'all') {
        queryParams['genre'] = genre;
      }

      final response = await _dio.get(
        '$host/v1/tracks/trending',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data['data'] as List? ?? [];
        return data
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
