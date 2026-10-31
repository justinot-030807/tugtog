import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/lyrics_service.dart';
import '../../../domain/models/track.dart';
import 'player_controller.dart';

class LyricsState {
  final bool isLoading;
  final LyricsData? lyrics;
  final int currentLineIndex;
  final String? error;
  final String? trackId;

  const LyricsState({
    this.isLoading = false,
    this.lyrics,
    this.currentLineIndex = -1,
    this.error,
    this.trackId,
  });

  LyricsState copyWith({
    bool? isLoading,
    LyricsData? lyrics,
    int? currentLineIndex,
    String? error,
    String? trackId,
  }) {
    return LyricsState(
      isLoading: isLoading ?? this.isLoading,
      lyrics: lyrics ?? this.lyrics,
      currentLineIndex: currentLineIndex ?? this.currentLineIndex,
      error: error,
      trackId: trackId ?? this.trackId,
    );
  }
}

class LyricsNotifier extends Notifier<LyricsState> {
  @override
  LyricsState build() {
    // Listen to playerController to fetch lyrics when track changes
    ref.listen(playerControllerProvider.select((s) => s.currentTrack),
        (previous, next) {
      if (next != null && (previous == null || previous.id != next.id)) {
        fetchLyricsForTrack(next);
      }
    });

    // Listen to position stream to sync line index
    ref.listen(playerControllerProvider.select((s) => s.position),
        (previous, position) {
      _syncPosition(position);
    });

    final currentTrack = ref.read(playerControllerProvider).currentTrack;
    if (currentTrack != null) {
      Future.microtask(() => fetchLyricsForTrack(currentTrack));
    }

    return const LyricsState();
  }

  Future<void> fetchLyricsForTrack(Track track) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      trackId: track.id,
      currentLineIndex: -1,
    );

    try {
      final data = await LyricsService.instance.getLyrics(track);
      if (data != null && data.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          lyrics: data,
          error: null,
        );
        _syncPosition(ref.read(playerControllerProvider).position);
      } else {
        state = state.copyWith(
          isLoading: false,
          lyrics: null,
          error: 'No lyrics available for this song.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lyrics: null,
        error: 'Failed to load lyrics.',
      );
    }
  }

  void _syncPosition(Duration position) {
    final lyrics = state.lyrics;
    if (lyrics == null || !lyrics.isSynced || lyrics.syncedLyrics.isEmpty) {
      return;
    }

    int activeIndex = -1;
    for (int i = 0; i < lyrics.syncedLyrics.length; i++) {
      if (position >= lyrics.syncedLyrics[i].timestamp) {
        activeIndex = i;
      } else {
        break;
      }
    }

    if (activeIndex != state.currentLineIndex) {
      state = state.copyWith(currentLineIndex: activeIndex);
    }
  }
}

final lyricsProvider = NotifierProvider<LyricsNotifier, LyricsState>(
  LyricsNotifier.new,
);
