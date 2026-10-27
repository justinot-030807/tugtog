import '../../../domain/models/track.dart';
import '../../../domain/sources/stream_resolver.dart';

/// Stream resolver for local device audio files.
class LocalStreamResolver implements StreamResolver {
  @override
  String get sourceId => 'local';

  @override
  Future<String> resolveStreamUrl(Track track) async {
    // For local storage, the mediaUri contains the absolute device path
    if (track.mediaUri != null && track.mediaUri!.isNotEmpty) {
      return track.mediaUri!;
    }
    throw ArgumentError('Local track does not contain a valid file path: ${track.id}');
  }
}
