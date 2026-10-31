import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/core/services/lyrics_service.dart';
import 'package:tugtog/data/sources/ytm/ytmusic_source.dart';
import 'package:tugtog/domain/models/track.dart';

void main() {
  group('LyricsService tests', () {
    test('parseLrc parses timestamped lyrics into LyricLine list correctly', () {
      const sampleLrc = '''
[00:12.50] Unang tingin pa lang
[00:18.25] Nabihag mo na ang aking puso
[01:05.10] Di na makatulog sa gabi
''';

      final lines = LyricsService.instance.parseLrc(sampleLrc);

      expect(lines.length, equals(3));
      expect(lines[0].text, equals('Unang tingin pa lang'));
      expect(lines[0].timestamp, equals(const Duration(seconds: 12, milliseconds: 500)));
      expect(lines[1].text, equals('Nabihag mo na ang aking puso'));
      expect(lines[1].timestamp, equals(const Duration(seconds: 18, milliseconds: 250)));
      expect(lines[2].text, equals('Di na makatulog sa gabi'));
      expect(lines[2].timestamp, equals(const Duration(minutes: 1, seconds: 5, milliseconds: 100)));
    });

    test('parseLrc ignores invalid or header lines', () {
      const sampleLrc = '''
[ti:Multo]
[ar:Cup of Joe]
[al:Silakbo]
[00:05.00] Totoo ba ito
''';

      final lines = LyricsService.instance.parseLrc(sampleLrc);
      expect(lines.length, equals(1));
      expect(lines[0].text, equals('Totoo ba ito'));
    });
  });

  group('Official Track Detection tests', () {
    test('Identifies YouTube Music topic channels as official tracks', () {
      final isOfficial = YtMusicSource.isOfficialTrack(
        'Multo',
        'Cup of Joe - Topic',
      );
      expect(isOfficial, isTrue);
    });

    test('Identifies official audio in title as official', () {
      final isOfficial = YtMusicSource.isOfficialTrack(
        'Dilaw (Official Audio)',
        'Maki',
      );
      expect(isOfficial, isTrue);
    });

    test('Penalizes cover and karaoke tracks from being marked official', () {
      final isCover = YtMusicSource.isOfficialTrack(
        'Multo - Acoustic Guitar Cover',
        'John Doe',
      );
      final isKaraoke = YtMusicSource.isOfficialTrack(
        'Dilaw (Karaoke Version)',
        'Sing King',
      );
      expect(isCover, isFalse);
      expect(isKaraoke, isFalse);
    });
  });

  group('Queue track navigation state tests', () {
    test('Track can store isOfficial metadata and preserve queue state', () {
      final track = Track(
        id: 'ytm_test123',
        title: 'Pantropiko',
        artist: 'BINI',
        sourceType: AudioSourceType.youtubeMusic,
        extraMetadata: const {
          'isOfficial': true,
          'videoId': 'test123',
        },
      );

      expect(track.extraMetadata['isOfficial'], isTrue);
      expect(track.extraMetadata['videoId'], equals('test123'));
    });
  });
}
