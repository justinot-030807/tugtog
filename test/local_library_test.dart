import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/domain/models/song.dart';
import 'package:tugtog/domain/models/track.dart';

void main() {
  group('Song model and Track conversion tests', () {
    test('Song model correctly formats duration and converts to Track', () {
      const song = Song(
        id: 101,
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: Duration(minutes: 5, seconds: 55),
        albumId: 42,
        data: '/storage/emulated/0/Music/Queen - Bohemian Rhapsody.mp3',
        size: 8500000,
      );

      expect(song.formattedDuration, '5:55');

      final track = song.toTrack();
      expect(track.id, 'local_101');
      expect(track.title, 'Bohemian Rhapsody');
      expect(track.artist, 'Queen');
      expect(track.album, 'A Night at the Opera');
      expect(track.duration, const Duration(minutes: 5, seconds: 55));
      expect(track.sourceType, AudioSourceType.local);
      expect(track.mediaUri, '/storage/emulated/0/Music/Queen - Bohemian Rhapsody.mp3');
      expect(track.extraMetadata['songId'], 101);
      expect(track.extraMetadata['albumId'], 42);
    });

    test('Song with null duration formats properly as placeholder', () {
      const song = Song(
        id: 102,
        title: 'Unknown Track',
        artist: 'Unknown Artist',
        data: '/storage/emulated/0/Music/sample.mp3',
      );

      expect(song.formattedDuration, '--:--');
    });
  });
}
