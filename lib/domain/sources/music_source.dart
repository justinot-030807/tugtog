import '../models/track.dart';

/// Abstract contract for discovering and fetching tracks.
/// Any music backend (Local on_audio_query, Audius, Jamendo, YTM) implements this contract.
abstract class MusicSource {
  /// Unique identifier of the source (e.g. "local", "audius", "jamendo", "ytm").
  String get sourceId;

  /// User-facing display name.
  String get displayName;

  /// Search for tracks given a user query.
  Future<List<Track>> search(String query);

  /// Fetch trending / popular tracks.
  Future<List<Track>> getTrending({int page = 1, int limit = 20});

  /// Fetch recently played tracks (if supported by source).
  Future<List<Track>> getRecentlyPlayed();
}
