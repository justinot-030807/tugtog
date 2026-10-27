import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/data/sources/audius/audius_source.dart';
import 'package:tugtog/data/sources/audius/audius_stream_resolver.dart';
import 'package:tugtog/data/sources/jamendo/jamendo_source.dart';
import 'package:tugtog/data/sources/jamendo/jamendo_stream_resolver.dart';
import 'package:tugtog/domain/models/track.dart';
import 'package:tugtog/features/home/presentation/discover_notifier.dart';

void main() {
  group('AudiusSource mapping and stream resolution', () {
    late AudiusSource audiusSource;
    late AudiusStreamResolver audiusResolver;

    setUp(() {
      audiusSource = AudiusSource(appName: 'tugtog_test');
      audiusResolver = AudiusStreamResolver(appName: 'tugtog_test');
    });

    test('getStreamUrl returns valid Audius stream URI', () {
      final streamUrl = audiusSource.getStreamUrl('track123');
      expect(streamUrl, contains('https://api.audius.co/v1/tracks/track123/stream'));
      expect(streamUrl, contains('app_name=tugtog_test'));
    });

    test('mapJsonToSong maps Audius JSON payload correctly to Song and Track', () {
      final sampleJson = {
        'id': 'audius_999',
        'title': 'Midnight Vibes',
        'user': {'name': 'Audius Producer'},
        'duration': 185,
        'artwork': {
          '150x150': 'https://audius.co/art_150.jpg',
          '480x480': 'https://audius.co/art_480.jpg',
        },
      };

      final song = audiusSource.mapJsonToSong(sampleJson);
      expect(song.title, equals('Midnight Vibes'));
      expect(song.artist, equals('Audius Producer'));
      expect(song.duration?.inSeconds, equals(185));
      expect(song.artworkUrl, equals('https://audius.co/art_480.jpg'));
      expect(song.sourceType, equals(AudioSourceType.audius));

      final track = song.toTrack();
      expect(track.sourceType, equals(AudioSourceType.audius));
      expect(track.mediaUri, contains('tracks/audius_999/stream'));
    });

    test('AudiusStreamResolver resolves existing or synthesized mediaUri', () async {
      final trackWithUri = Track(
        id: 'audius_1',
        title: 'Song',
        artist: 'Artist',
        sourceType: AudioSourceType.audius,
        mediaUri: 'https://example.com/stream.mp3',
      );
      final resolved1 = await audiusResolver.resolveStreamUrl(trackWithUri);
      expect(resolved1, equals('https://example.com/stream.mp3'));

      final trackWithoutUri = Track(
        id: 'audius_2',
        title: 'Song 2',
        artist: 'Artist',
        sourceType: AudioSourceType.audius,
      );
      final resolved2 = await audiusResolver.resolveStreamUrl(trackWithoutUri);
      expect(resolved2, contains('tracks/2/stream'));
    });
  });

  group('JamendoSource mapping and stream resolution', () {
    late JamendoSource jamendoSource;
    late JamendoStreamResolver jamendoResolver;

    setUp(() {
      jamendoSource = JamendoSource(clientId: 'test_client_id');
      jamendoResolver = JamendoStreamResolver();
    });

    test('clientId returns configured override or default', () {
      expect(jamendoSource.clientId, equals('test_client_id'));
    });

    test('mapJsonToSong maps Jamendo JSON payload correctly to Song and Track', () {
      final sampleJson = {
        'id': '1049281',
        'name': 'Electric Journey',
        'artist_name': 'Jamendo Star',
        'album_name': 'Future Album',
        'duration': 210,
        'image': 'https://jamendo.com/cover.jpg',
        'audio': 'https://prod-1.storage.jamendo.com/download/track/1049281/mp32/',
      };

      final song = jamendoSource.mapJsonToSong(sampleJson);
      expect(song.title, equals('Electric Journey'));
      expect(song.artist, equals('Jamendo Star'));
      expect(song.album, equals('Future Album'));
      expect(song.duration?.inSeconds, equals(210));
      expect(song.artworkUrl, equals('https://jamendo.com/cover.jpg'));
      expect(song.sourceType, equals(AudioSourceType.jamendo));
      expect(song.data, equals(sampleJson['audio']));

      final track = song.toTrack();
      expect(track.sourceType, equals(AudioSourceType.jamendo));
      expect(track.mediaUri, equals(sampleJson['audio']));
    });

    test('JamendoStreamResolver resolves mediaUri directly', () async {
      final track = Track(
        id: '123',
        title: 'Track',
        artist: 'Artist',
        sourceType: AudioSourceType.jamendo,
        mediaUri: 'https://stream.jamendo.com/track.mp3',
      );
      final resolved = await jamendoResolver.resolveStreamUrl(track);
      expect(resolved, equals('https://stream.jamendo.com/track.mp3'));
    });
  });

  group('DiscoverGenres mappings', () {
    test('all 6 genre chips map to appropriate Audius and Jamendo parameters', () {
      for (final chip in DiscoverGenres.list) {
        final audiusGenre = DiscoverGenres.mapToAudiusGenre(chip);
        final jamendoTag = DiscoverGenres.mapToJamendoTag(chip);

        // Every genre chip must have a non-empty mapping
        expect(audiusGenre, isNotEmpty, reason: 'Audius genre for $chip should not be empty');
        expect(jamendoTag, isNotEmpty, reason: 'Jamendo tag for $chip should not be empty');
      }
    });
  });
}
