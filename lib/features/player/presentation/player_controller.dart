import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/models/track.dart';
import '../models/player_state.dart';

/// Riverpod Notifier controlling audio playback, background service, queue, and persistence.
class PlayerController extends Notifier<CurrentPlayerState> {
  late AudioPlayer _player;
  AndroidEqualizer? _equalizer;
  final List<StreamSubscription> _subscriptions = [];
  List<Track> _queueTracks = [];
  int _currentIndex = 0;
  Duration _currentPosition = Duration.zero;
  final AppDatabase _db = AppDatabase.instance;
  Timer? _sessionSaveDebounce;

  @override
  CurrentPlayerState build() {
    try {
      _equalizer = AndroidEqualizer();
      _player = AudioPlayer(
        audioPipeline: AudioPipeline(
          androidAudioEffects: [_equalizer!],
        ),
      );
    } catch (_) {
      _player = AudioPlayer();
    }

    _initAudioSession();
    _listenToPlayerEvents();

    // Restore saved playback session from SQLite on startup
    Future.microtask(() => _restoreSavedPlaybackSession());

    ref.onDispose(() {
      _sessionSaveDebounce?.cancel();
      _saveCurrentSession();
      for (final sub in _subscriptions) {
        sub.cancel();
      }
      _player.dispose();
    });

    const fallbackTrack = Track(
      id: 'demo_1',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: Duration(minutes: 4, seconds: 3),
      sourceType: AudioSourceType.audius,
    );

    _queueTracks = [fallbackTrack];
    _currentIndex = 0;
    _currentPosition = const Duration(minutes: 1, seconds: 24);

    return const CurrentPlayerState(
      currentTrack: fallbackTrack,
      totalDuration: Duration(minutes: 4, seconds: 3),
      position: Duration(minutes: 1, seconds: 24),
      queue: [fallbackTrack],
      currentIndex: 0,
    );
  }

  /// Restore last played queue and position from SQLite database.
  Future<void> _restoreSavedPlaybackSession() async {
    try {
      final session = await _db.getPlaybackSession();
      if (session != null && session.queue.isNotEmpty) {
        _queueTracks = List.from(session.queue);
        final validIndex =
            session.currentIndex.clamp(0, _queueTracks.length - 1);
        final restoredTrack = _queueTracks[validIndex];
        _currentIndex = validIndex;
        _currentPosition = session.position;

        state = state.copyWith(
          queue: List.unmodifiable(_queueTracks),
          currentIndex: validIndex,
          currentTrack: restoredTrack,
          position: session.position,
          totalDuration: restoredTrack.duration ?? Duration.zero,
          isPlaying: false,
        );

        try {
          await _player.setAudioSources(
            _queueTracks.map(_buildAudioSource).toList(),
            initialIndex: validIndex,
            initialPosition: session.position,
          );
        } catch (_) {
          // Fallback silently if cached local file paths moved
        }
      }
    } catch (_) {
      // Ignored in test environments or before DB initialized
    }
  }

  /// Save active playback queue and progress to SQLite.
  void _saveCurrentSession() {
    try {
      if (_queueTracks.isNotEmpty && _currentIndex >= 0) {
        _db.savePlaybackSession(
          queue: _queueTracks,
          currentIndex: _currentIndex,
          position: _currentPosition,
        );
      }
    } catch (_) {
      // Ignored during testing
    }
  }

  void _scheduleSessionSave() {
    _sessionSaveDebounce?.cancel();
    _sessionSaveDebounce = Timer(const Duration(seconds: 2), () {
      _saveCurrentSession();
    });
  }

  /// Configure AudioSession for music playback and interruption handling.
  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      _subscriptions.add(
        session.interruptionEventStream.listen((event) {
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _player.setVolume(0.4);
                break;
              case AudioInterruptionType.pause:
              case AudioInterruptionType.unknown:
                _player.pause();
                break;
            }
          } else {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _player.setVolume(1.0);
                break;
              case AudioInterruptionType.pause:
                break;
              case AudioInterruptionType.unknown:
                break;
            }
          }
        }),
      );

      _subscriptions.add(
        session.becomingNoisyEventStream.listen((_) {
          _player.pause();
        }),
      );
    } catch (_) {
      // Ignored in headless testing environments
    }
  }

  /// Listen to just_audio state streams and synchronize with Riverpod state.
  void _listenToPlayerEvents() {
    // 1. Play / Pause & Buffering State
    _subscriptions.add(
      _player.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final isBuffering =
            playerState.processingState == ProcessingState.buffering ||
                playerState.processingState == ProcessingState.loading;

        state = state.copyWith(
          isPlaying: isPlaying,
          isBuffering: isBuffering,
        );

        if (!isPlaying) {
          _saveCurrentSession();
        }
      }),
    );

    // 1b. Catch playback errors and clear buffering spinner
    _subscriptions.add(
      _player.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          state = state.copyWith(isBuffering: false, isPlaying: false);
        },
      ),
    );

    // 2. Playback Position
    _subscriptions.add(
      _player.positionStream.listen((pos) {
        _currentPosition = pos;
        state = state.copyWith(position: pos);
        _scheduleSessionSave();
      }),
    );

    // 3. Buffered Position
    _subscriptions.add(
      _player.bufferedPositionStream.listen((buf) {
        state = state.copyWith(bufferedPosition: buf);
      }),
    );

    // 4. Track Total Duration
    _subscriptions.add(
      _player.durationStream.listen((dur) {
        if (dur != null) {
          state = state.copyWith(totalDuration: dur);
        }
      }),
    );

    // 5. Active Index Change in Playlist
    _subscriptions.add(
      _player.currentIndexStream.listen((index) {
        if (index != null && index >= 0 && index < _queueTracks.length) {
          _currentIndex = index;
          final track = _queueTracks[index];
          state = state.copyWith(
            currentIndex: index,
            currentTrack: track,
            totalDuration: track.duration ?? state.totalDuration,
          );

          // Log track to play history in SQLite
          try {
            _db.logPlayHistory(track);
          } catch (_) {}
          _saveCurrentSession();
        }
      }),
    );

    // 6. Shuffle Mode
    _subscriptions.add(
      _player.shuffleModeEnabledStream.listen((shuffling) {
        state = state.copyWith(isShuffling: shuffling);
      }),
    );

    // 7. Loop / Repeat Mode
    _subscriptions.add(
      _player.loopModeStream.listen((loop) {
        state = state.copyWith(loopMode: loop);
      }),
    );
  }

  /// Create an AudioSource tagged with MediaItem for notification & background playback.
  AudioSource _buildAudioSource(Track track) {
    Uri? artUri;
    if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty) {
      artUri = Uri.tryParse(track.artworkUrl!);
    }

    final mediaItem = MediaItem(
      id: track.id,
      album: track.album ?? 'Unknown Album',
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      artUri: artUri,
      extras: track.extraMetadata,
    );

    final uriStr = track.mediaUri ?? '';
    final isRemote =
        uriStr.startsWith('http://') || uriStr.startsWith('https://');

    if (!isRemote && uriStr.isNotEmpty) {
      final localPath =
          uriStr.startsWith('file://') ? uriStr.substring(7) : uriStr;
      return AudioSource.file(
        localPath,
        tag: mediaItem,
      );
    } else {
      return AudioSource.uri(
        Uri.parse(uriStr),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        },
        tag: mediaItem,
      );
    }
  }

  /// Play a list of tracks starting from an initial index.
  Future<void> playSongList(List<Track> tracks, int initialIndex) async {
    if (tracks.isEmpty) return;

    _queueTracks = List.from(tracks);
    _currentIndex = initialIndex;
    _currentPosition = Duration.zero;

    state = state.copyWith(
      queue: List.unmodifiable(_queueTracks),
      currentIndex: initialIndex,
      currentTrack: _queueTracks[initialIndex],
      position: Duration.zero,
      totalDuration: _queueTracks[initialIndex].duration ?? Duration.zero,
    );

    try {
      await _player.setAudioSources(
        _queueTracks.map(_buildAudioSource).toList(),
        initialIndex: initialIndex,
        initialPosition: Duration.zero,
      );
      await _player.play();
      _saveCurrentSession();
    } catch (_) {
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  /// Play a single track.
  Future<void> playTrack(Track track) async {
    await playSongList([track], 0);
  }

  /// Toggle play / pause.
  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Play current track.
  Future<void> play() async => await _player.play();

  /// Pause current track.
  Future<void> pause() async => await _player.pause();

  /// Seek to a specific playback position.
  Future<void> seek(Duration position) async {
    _currentPosition = position;
    await _player.seek(position);
    _saveCurrentSession();
  }

  /// Skip to next track in queue.
  Future<void> seekToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  /// Skip to previous track, or restart current track if > 3 seconds.
  Future<void> seekToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  /// Jump to a specific track index in the queue.
  Future<void> jumpToQueueItem(int index) async {
    if (index >= 0 && index < _queueTracks.length) {
      _currentIndex = index;
      _currentPosition = Duration.zero;
      await _player.seek(Duration.zero, index: index);
      await _player.play();
    }
  }

  /// Toggle shuffle mode on / off.
  Future<void> toggleShuffle() async {
    final enable = !state.isShuffling;
    if (enable) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enable);
  }

  /// Cycle repeat mode: off -> all -> one -> off.
  Future<void> cycleRepeatMode() async {
    final current = state.loopMode;
    final LoopMode next;
    switch (current) {
      case LoopMode.off:
        next = LoopMode.all;
        break;
      case LoopMode.all:
        next = LoopMode.one;
        break;
      case LoopMode.one:
        next = LoopMode.off;
        break;
    }
    await _player.setLoopMode(next);
  }

  /// Add track right after the current playing song.
  Future<void> addToNext(Track track) async {
    final nextIndex = _currentIndex + 1;
    if (nextIndex <= _queueTracks.length) {
      _queueTracks.insert(nextIndex, track);
      await _player.insertAudioSource(nextIndex, _buildAudioSource(track));
      state = state.copyWith(queue: List.unmodifiable(_queueTracks));
      _saveCurrentSession();
    } else {
      await addToEnd(track);
    }
  }

  /// Append track to the end of the queue.
  Future<void> addToEnd(Track track) async {
    _queueTracks.add(track);
    await _player.addAudioSource(_buildAudioSource(track));
    state = state.copyWith(queue: List.unmodifiable(_queueTracks));
    _saveCurrentSession();
  }

  /// Remove track at index from the queue.
  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queueTracks.length) {
      if (_queueTracks.length == 1) {
        await _player.stop();
        _queueTracks.clear();
        state = state.copyWith(
          queue: const [],
          clearCurrentTrack: true,
          currentIndex: -1,
        );
        _saveCurrentSession();
        return;
      }
      _queueTracks.removeAt(index);
      await _player.removeAudioSourceAt(index);
      state = state.copyWith(queue: List.unmodifiable(_queueTracks));
      _saveCurrentSession();
    }
  }

  /// Reorder track positions within the queue.
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    if (oldIndex >= 0 &&
        oldIndex < _queueTracks.length &&
        targetIndex >= 0 &&
        targetIndex < _queueTracks.length) {
      final movedTrack = _queueTracks.removeAt(oldIndex);
      _queueTracks.insert(targetIndex, movedTrack);
      await _player.moveAudioSource(oldIndex, targetIndex);
      state = state.copyWith(queue: List.unmodifiable(_queueTracks));
      _saveCurrentSession();
    }
  }

  /// Returns the Android Equalizer instance if supported.
  AndroidEqualizer? get equalizer => _equalizer;

  /// Retrieves the Android equalizer frequency parameters.
  Future<AndroidEqualizerParameters?> getEqualizerParameters() async {
    if (_equalizer == null) return null;
    try {
      return await _equalizer!.parameters;
    } catch (_) {
      return null;
    }
  }

  /// Sets whether the equalizer is active.
  Future<void> setEqualizerEnabled(bool enabled) async {
    if (_equalizer == null) return;
    try {
      await _equalizer!.setEnabled(enabled);
    } catch (_) {}
  }

  /// Sets the gain in dB for a specific equalizer frequency band.
  Future<void> setEqualizerBandGain(int bandIndex, double gain) async {
    if (_equalizer == null) return;
    try {
      final params = await _equalizer!.parameters;
      if (bandIndex < params.bands.length) {
        await params.bands[bandIndex].setGain(gain);
      }
    } catch (_) {}
  }

  /// Stops playback and clears the currently loaded track, dismissing the mini player.
  void stopAndClear() {
    _player.stop();
    state = state.copyWith(
      clearCurrentTrack: true,
      isPlaying: false,
      position: Duration.zero,
    );
  }
}

/// Global Riverpod provider for player controller and playback state.
final playerControllerProvider =
    NotifierProvider<PlayerController, CurrentPlayerState>(
  PlayerController.new,
);

/// Backward-compatible alias for existing imports.
final playerProvider = playerControllerProvider;
