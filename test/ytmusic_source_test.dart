import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/data/sources/ytm/strategies/youtube_iframe_strategy.dart';
import 'package:tugtog/data/sources/ytm/ytm_stream_resolver.dart';
import 'package:tugtog/data/sources/ytm/ytmusic_source.dart';
import 'package:tugtog/domain/models/track.dart';

void main() {
  group('YtMusicSource and YtStreamResolver tests', () {
    test('parseDuration correctly converts mm:ss and hh:mm:ss strings', () {
      expect(
        YtMusicSource.parseDuration('3:45'),
        const Duration(minutes: 3, seconds: 45),
      );
      expect(
        YtMusicSource.parseDuration('1:12:30'),
        const Duration(hours: 1, minutes: 12, seconds: 30),
      );
      expect(YtMusicSource.parseDuration(''), isNull);
      expect(YtMusicSource.parseDuration(null), isNull);
      expect(YtMusicSource.parseDuration('invalid'), isNull);
    });

    test('YtStreamResolver resolves using registered strategy and matches sourceId', () async {
      final resolver = YtStreamResolver(
        initialStrategies: [YouTubeIFrameStrategy()],
        activeStrategyId: 'iframe_webview',
      );
      const track = Track(
        id: 'ytm_dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        artist: 'Rick Astley',
        sourceType: AudioSourceType.youtubeMusic,
      );

      final result = await resolver.resolveStreamUrl(track);
      expect(result, contains('YouTube IFrame Player'));
      expect(resolver.sourceId, 'youtubeMusic');
    });
  });
}
