import 'package:just_audio/just_audio.dart';
import '../../../domain/models/track.dart';

/// Represents the active audio playback and queue state in Tugtog.
class CurrentPlayerState {
  final Track? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration bufferedPosition;
  final Duration totalDuration;
  final bool isShuffling;
  final LoopMode loopMode;
  final List<Track> queue;
  final int currentIndex;

  const CurrentPlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.isShuffling = false,
    this.loopMode = LoopMode.off,
    this.queue = const [],
    this.currentIndex = -1,
  });

  CurrentPlayerState copyWith({
    Track? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? bufferedPosition,
    Duration? totalDuration,
    bool? isShuffling,
    LoopMode? loopMode,
    List<Track>? queue,
    int? currentIndex,
    bool clearCurrentTrack = false,
  }) {
    return CurrentPlayerState(
      currentTrack:
          clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isShuffling: isShuffling ?? this.isShuffling,
      loopMode: loopMode ?? this.loopMode,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  /// Normalized progress from 0.0 to 1.0.
  double get progress {
    if (totalDuration.inMilliseconds <= 0) return 0.0;
    final val = position.inMilliseconds / totalDuration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }

  /// Check if next track is available in queue.
  bool get hasNext => currentIndex < queue.length - 1;

  /// Check if previous track is available in queue.
  bool get hasPrevious => currentIndex > 0;
}
