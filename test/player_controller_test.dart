import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tugtog/domain/models/track.dart';
import 'package:tugtog/features/player/models/player_state.dart';

void main() {
  group('CurrentPlayerState tests', () {
    const track1 = Track(
      id: 'track_1',
      title: 'Track One',
      artist: 'Artist One',
      duration: Duration(minutes: 3),
      sourceType: AudioSourceType.local,
      mediaUri: '/storage/track1.mp3',
    );

    const track2 = Track(
      id: 'track_2',
      title: 'Track Two',
      artist: 'Artist Two',
      duration: Duration(minutes: 4),
      sourceType: AudioSourceType.local,
      mediaUri: '/storage/track2.mp3',
    );

    test('Initial player state has correct defaults and progress calculation', () {
      const state = CurrentPlayerState(
        currentTrack: track1,
        position: Duration(seconds: 90),
        totalDuration: Duration(minutes: 3),
        queue: [track1, track2],
        currentIndex: 0,
      );

      expect(state.progress, 0.5);
      expect(state.hasNext, isTrue);
      expect(state.hasPrevious, isFalse);
      expect(state.loopMode, LoopMode.off);
    });

    test('State copyWith properly updates queue and loopMode', () {
      const state = CurrentPlayerState(
        currentTrack: track1,
        queue: [track1],
        currentIndex: 0,
      );

      final updated = state.copyWith(
        queue: [track1, track2],
        loopMode: LoopMode.all,
        isShuffling: true,
      );

      expect(updated.queue.length, 2);
      expect(updated.loopMode, LoopMode.all);
      expect(updated.isShuffling, isTrue);
    });
  });
}
