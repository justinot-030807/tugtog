import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player_state.dart';
import 'player_controller.dart';

/// State representation for the Sleep Timer feature.
class SleepTimerState {
  final bool isActive;
  final int remainingSeconds;
  final String? activeLabel;
  final bool isEndOfTrack;

  const SleepTimerState({
    this.isActive = false,
    this.remainingSeconds = 0,
    this.activeLabel,
    this.isEndOfTrack = false,
  });

  /// Formatted remaining countdown (e.g. "14:59").
  String get formattedRemaining {
    if (isEndOfTrack) return 'End of track';
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  SleepTimerState copyWith({
    bool? isActive,
    int? remainingSeconds,
    String? activeLabel,
    bool? isEndOfTrack,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      activeLabel: activeLabel ?? this.activeLabel,
      isEndOfTrack: isEndOfTrack ?? this.isEndOfTrack,
    );
  }
}

/// Riverpod Notifier controlling sleep timer countdown and automatic playback pause.
class SleepTimerNotifier extends Notifier<SleepTimerState> {
  Timer? _countdownTimer;
  ProviderSubscription? _playerSub;

  @override
  SleepTimerState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
      _playerSub?.close();
    });
    return const SleepTimerState();
  }

  /// Sets a countdown timer for a specific duration.
  void setTimer(Duration duration, String label) {
    _countdownTimer?.cancel();
    _playerSub?.close();

    state = SleepTimerState(
      isActive: true,
      remainingSeconds: duration.inSeconds,
      activeLabel: label,
      isEndOfTrack: false,
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds <= 1) {
        _triggerSleepPause();
      } else {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      }
    });
  }

  /// Sets sleep timer to pause playback when the current track finishes.
  void setEndOfTrack() {
    _countdownTimer?.cancel();
    _playerSub?.close();

    state = const SleepTimerState(
      isActive: true,
      activeLabel: 'End of track',
      isEndOfTrack: true,
    );

    // Watch position / track end from player
    final playerState = ref.read(playerControllerProvider);
    final currentTrackId = playerState.currentTrack?.id;

    _playerSub = ref.listen<CurrentPlayerState>(playerControllerProvider, (prev, next) {
      // If song changed or stopped playing at the end
      if (next.currentTrack?.id != currentTrackId ||
          (next.position >= (next.totalDuration - const Duration(seconds: 1)) &&
              next.totalDuration > Duration.zero)) {
        _triggerSleepPause();
      }
    });
  }

  /// Cancels any active sleep timer.
  void cancelTimer() {
    _countdownTimer?.cancel();
    _playerSub?.close();
    state = const SleepTimerState();
  }

  void _triggerSleepPause() {
    _countdownTimer?.cancel();
    _playerSub?.close();
    state = const SleepTimerState();
    ref.read(playerControllerProvider.notifier).pause();
  }
}

/// Global provider for the sleep timer.
final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, SleepTimerState>(
  SleepTimerNotifier.new,
);
