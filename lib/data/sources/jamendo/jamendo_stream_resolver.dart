import '../../../domain/models/track.dart';
import '../../../domain/sources/stream_resolver.dart';

/// Stream resolver for Jamendo tracks.
class JamendoStreamResolver implements StreamResolver {
  @override
  String get sourceId => 'jamendo';

  @override
  Future<String> resolveStreamUrl(Track track) async {
    if (track.mediaUri != null && track.mediaUri!.isNotEmpty) {
      return track.mediaUri!;
    }
    throw ArgumentError('Jamendo track is missing stream audio URL: ${track.id}');
  }
}
