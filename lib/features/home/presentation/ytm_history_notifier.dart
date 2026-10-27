import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/sources/ytm/strategies/match_audio_strategy.dart';
import '../../../data/sources/ytm/strategies/youtube_iframe_strategy.dart';
import '../../../data/sources/ytm/ytm_stream_resolver.dart';
import '../../../data/sources/ytm/ytmusic_source.dart';
import '../../../domain/models/track.dart';
import '../../settings/presentation/settings_notifier.dart';
import 'discover_notifier.dart';

/// State representation for YouTube Music recently played history.
class YtmHistoryState {
  final List<Track> tracks;
  final bool isLoading;
  final String? errorMessage;

  const YtmHistoryState({
    this.tracks = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  YtmHistoryState copyWith({
    List<Track>? tracks,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return YtmHistoryState(
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for YtMusicSource configured with the current backend URL.
final ytMusicSourceProvider = Provider<YtMusicSource>((ref) {
  final settings = ref.watch(settingsProvider);
  return YtMusicSource(baseUrl: settings.backendBaseUrl);
});

/// Provider for YtStreamResolver configured with registered strategies and user settings.
final ytStreamResolverProvider = Provider<YtStreamResolver>((ref) {
  final settings = ref.watch(settingsProvider);
  final audius = ref.watch(audiusSourceProvider);
  final jamendo = ref.watch(jamendoSourceProvider);

  return YtStreamResolver(
    initialStrategies: [
      MatchAudioStrategy(audiusSource: audius, jamendoSource: jamendo),
      YouTubeIFrameStrategy(),
    ],
    activeStrategyId: settings.streamResolutionStrategyId,
  );
});

/// Riverpod Notifier managing YouTube Music history fetching and error states.
class YtmHistoryNotifier extends Notifier<YtmHistoryState> {
  @override
  YtmHistoryState build() {
    // Automatically trigger initial fetch when settings are ready
    final settings = ref.watch(settingsProvider);
    if (settings.isLoaded) {
      Future.microtask(() => fetchHistory());
    }
    return const YtmHistoryState(isLoading: true);
  }

  /// Fetch recently played tracks from YouTube Music companion backend.
  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final source = ref.read(ytMusicSourceProvider);
      final tracks = await source.getRecentlyPlayed();
      state = state.copyWith(
        isLoading: false,
        tracks: tracks,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

/// Global provider for YouTube Music history state.
final ytmHistoryProvider =
    NotifierProvider<YtmHistoryNotifier, YtmHistoryState>(
  YtmHistoryNotifier.new,
);
