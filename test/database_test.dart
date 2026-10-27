import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/data/db/app_database.dart';
import 'package:tugtog/domain/models/playlist.dart';
import 'package:tugtog/domain/models/track.dart';

void main() {
  group('Track Serialization and Database Models Tests', () {
    test('Track converts to JSON and restores accurately from JSON', () {
      const originalTrack = Track(
        id: 'track_123',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        duration: Duration(minutes: 3, seconds: 50),
        artworkUrl: 'https://example.com/art.jpg',
        sourceType: AudioSourceType.audius,
        mediaUri: 'https://audius.co/stream/123.mp3',
        extraMetadata: {'bitrate': 320, 'genre': 'R&B'},
      );

      final jsonMap = originalTrack.toJson();
      expect(jsonMap['id'], 'track_123');
      expect(jsonMap['title'], 'Starboy');
      expect(jsonMap['durationMs'], 230000);
      expect(jsonMap['sourceType'], 'audius');

      final restoredTrack = Track.fromJson(jsonMap);
      expect(restoredTrack.id, originalTrack.id);
      expect(restoredTrack.title, originalTrack.title);
      expect(restoredTrack.artist, originalTrack.artist);
      expect(restoredTrack.album, originalTrack.album);
      expect(restoredTrack.duration, originalTrack.duration);
      expect(restoredTrack.artworkUrl, originalTrack.artworkUrl);
      expect(restoredTrack.sourceType, AudioSourceType.audius);
      expect(restoredTrack.mediaUri, originalTrack.mediaUri);
      expect(restoredTrack.extraMetadata['bitrate'], 320);
    });

    test('Playlist model copyWith updates attributes properly', () {
      final now = DateTime.now();
      final playlist = Playlist(
        id: 1,
        name: 'Roadtrip Beats',
        createdAt: now,
        trackCount: 5,
      );

      final updated = playlist.copyWith(name: 'Summer Roadtrip', trackCount: 6);
      expect(updated.id, 1);
      expect(updated.name, 'Summer Roadtrip');
      expect(updated.trackCount, 6);
      expect(updated.createdAt, now);
    });

    test('SavedPlaybackSession stores queue and index accurately', () {
      const track = Track(
        id: '1',
        title: 'Demo Song',
        artist: 'Demo Artist',
        sourceType: AudioSourceType.local,
      );

      const session = SavedPlaybackSession(
        queue: [track],
        currentIndex: 0,
        position: Duration(seconds: 45),
      );

      expect(session.queue.length, 1);
      expect(session.currentIndex, 0);
      expect(session.position.inSeconds, 45);
    });
  });
}
