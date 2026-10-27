import '../models/track.dart';

/// Abstract contract for resolving a playable audio stream URL/URI for a given track.
abstract class StreamResolver {
  /// Matches the sourceId of the corresponding MusicSource.
  String get sourceId;

  /// Resolves the direct audio stream URL or local file path for playback.
  Future<String> resolveStreamUrl(Track track);
}
