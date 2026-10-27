import '../../../domain/models/track.dart';
import '../../../domain/sources/stream_resolver.dart';

/// Stream resolver for Audius tracks.
class AudiusStreamResolver implements StreamResolver {
  final String appName;

  AudiusStreamResolver({this.appName = 'tugtog'});

  @override
  String get sourceId => 'audius';

  @override
  Future<String> resolveStreamUrl(Track track) async {
    if (track.mediaUri != null && track.mediaUri!.isNotEmpty) {
      return track.mediaUri!;
    }
    // Clean track ID removing prefix
    final cleanId = track.id.replaceFirst('audius_', '');
    return 'https://api.audius.co/v1/tracks/$cleanId/stream?app_name=$appName';
  }
}
