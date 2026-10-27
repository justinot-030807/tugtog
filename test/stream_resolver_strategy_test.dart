import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/core/utils/song_matcher.dart';
import 'package:tugtog/data/sources/audius/audius_source.dart';
import 'package:tugtog/data/sources/jamendo/jamendo_source.dart';
import 'package:tugtog/data/sources/ytm/strategies/match_audio_strategy.dart';
import 'package:tugtog/data/sources/ytm/strategies/youtube_iframe_strategy.dart';
import 'package:tugtog/data/sources/ytm/ytm_stream_resolver.dart';
import 'package:tugtog/domain/models/track.dart';
import 'package:tugtog/domain/sources/stream_resolver_strategy.dart';

// Fake Audius Source for testing Strategy A
class FakeAudiusSource extends AudiusSource {
  final List<Track> candidates;
  FakeAudiusSource({this.candidates = const []});

  @override
  Future<List<Track>> search(String query) async {
    return candidates;
  }
}

// Fake Jamendo Source for testing Strategy A
class FakeJamendoSource extends JamendoSource {
  final List<Track> candidates;
  FakeJamendoSource({this.candidates = const []});

  @override
  Future<List<Track>> search(String query) async {
    return candidates;
  }
}

void main() {
  group('SongMatcher normalization and similarity tests', () {
    test('normalizeTitle strips music video decorations, feat artists, and punctuation', () {
      expect(
        SongMatcher.normalizeTitle('Midnight City (Official Music Video)'),
        equals('midnight city'),
      );
      expect(
        SongMatcher.normalizeTitle('Starboy [Official Audio] feat. Daft Punk'),
        equals('starboy'),
      );
      expect(
        SongMatcher.normalizeTitle('Bohemian Rhapsody - Remastered 2011 (Live)'),
        equals('bohemian rhapsody'),
      );
      expect(
        SongMatcher.normalizeTitle('Payphone (feat. Wiz Khalifa) [Lyric Video]'),
        equals('payphone'),
      );
    });

    test('normalizeArtist cleans and collapses artist tokens', () {
      expect(SongMatcher.normalizeArtist('M83 VEVO'), equals('m83'));
      expect(SongMatcher.normalizeArtist('The Weeknd - Topic'), equals('the weeknd'));
      expect(SongMatcher.normalizeArtist('Maroon 5 feat. Wiz Khalifa'), equals('maroon 5 wiz khalifa'));
    });

    test('matchConfidence computes high confidence for matches and 0 for mismatches', () {
      final highConfidence = SongMatcher.matchConfidence(
        queryTitle: 'Midnight City (Official Video)',
        queryArtist: 'M83',
        candidateTitle: 'Midnight City',
        candidateArtist: 'M83',
      );
      expect(highConfidence, greaterThanOrEqualTo(0.85));

      final mismatch = SongMatcher.matchConfidence(
        queryTitle: 'Midnight City',
        queryArtist: 'M83',
        candidateTitle: 'Completely Different Song',
        candidateArtist: 'Unrelated Band',
      );
      expect(mismatch, lessThan(0.3));
    });
  });

  group('Strategy A: MatchAudioStrategy tests', () {
    test('resolves to playable when a confident match is found in candidate sources', () async {
      final matchedCandidate = const Track(
        id: 'aud_123',
        title: 'Midnight City',
        artist: 'M83',
        sourceType: AudioSourceType.audius,
        mediaUri: 'https://audius.co/stream/123.mp3',
      );

      final strategy = MatchAudioStrategy(
        audiusSource: FakeAudiusSource(candidates: [matchedCandidate]),
        jamendoSource: FakeJamendoSource(candidates: []),
      );

      final ytmTrack = const Track(
        id: 'ytm_video_99',
        title: 'Midnight City (Official Music Video)',
        artist: 'M83',
        sourceType: AudioSourceType.youtubeMusic,
      );

      final result = await strategy.resolve(ytmTrack);
      expect(result.type, equals(ResolutionType.playable));
      expect(result.track?.id, equals('aud_123'));
      expect(result.sourceName, equals('Audius'));
      expect(result.matchScore, greaterThanOrEqualTo(0.75));
    });

    test('resolves to notFound when candidates do not meet confidence threshold', () async {
      final dissimilarCandidate = const Track(
        id: 'jam_999',
        title: 'Electronic Beats',
        artist: 'Random Producer',
        sourceType: AudioSourceType.jamendo,
        mediaUri: 'https://jamendo.com/stream/999.mp3',
      );

      final strategy = MatchAudioStrategy(
        audiusSource: FakeAudiusSource(candidates: []),
        jamendoSource: FakeJamendoSource(candidates: [dissimilarCandidate]),
      );

      final ytmTrack = const Track(
        id: 'ytm_video_88',
        title: 'Hotel California',
        artist: 'Eagles',
        sourceType: AudioSourceType.youtubeMusic,
      );

      final result = await strategy.resolve(ytmTrack);
      expect(result.type, equals(ResolutionType.notFound));
      expect(result.track, isNull);
    });
  });

  group('Strategy B: YouTubeIFrameStrategy tests', () {
    final strategy = YouTubeIFrameStrategy();

    test('resolves to webView with extracted video ID', () async {
      final trackWithMeta = const Track(
        id: 'ytm_dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        artist: 'Rick Astley',
        sourceType: AudioSourceType.youtubeMusic,
        extraMetadata: {'videoId': 'dQw4w9WgXcQ'},
      );

      final result = await strategy.resolve(trackWithMeta);
      expect(result.type, equals(ResolutionType.webView));
      expect(result.videoId, equals('dQw4w9WgXcQ'));
    });

    test('extracts videoId from track ID if metadata is absent', () async {
      final trackWithId = const Track(
        id: 'ytm_abc123xyz',
        title: 'Some Video',
        artist: 'Artist',
        sourceType: AudioSourceType.youtubeMusic,
      );

      final result = await strategy.resolve(trackWithId);
      expect(result.type, equals(ResolutionType.webView));
      expect(result.videoId, equals('abc123xyz'));
    });
  });

  group('YtStreamResolver strategy orchestration tests', () {
    test('switches between Strategy A and Strategy B according to activeStrategyId', () {
      final strategyA = MatchAudioStrategy(
        audiusSource: FakeAudiusSource(),
        jamendoSource: FakeJamendoSource(),
      );
      final strategyB = YouTubeIFrameStrategy();

      final resolver = YtStreamResolver(
        initialStrategies: [strategyA, strategyB],
        activeStrategyId: 'match_audio',
      );

      expect(resolver.activeStrategy?.id, equals('match_audio'));

      // Switch to Strategy B
      resolver.activeStrategyId = 'iframe_webview';
      expect(resolver.activeStrategy?.id, equals('iframe_webview'));
      expect(resolver.activeStrategy?.displayName, equals('In-App YouTube IFrame Player'));
    });

    test('supports registering new custom strategies dynamically', () {
      final resolver = YtStreamResolver();
      expect(resolver.availableStrategies, isEmpty);

      final strategyB = YouTubeIFrameStrategy();
      resolver.registerStrategy(strategyB);

      expect(resolver.availableStrategies.length, equals(1));
      expect(resolver.activeStrategy?.id, equals('iframe_webview'));
    });
  });
}
