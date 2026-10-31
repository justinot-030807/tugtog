import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../core/services/invidious_stream_service.dart';
import '../../../core/services/track_cache_service.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/models/track.dart';
import '../models/player_state.dart';

/// Riverpod Notifier controlling audio playback, background service, queue, and persistence.
class PlayerController extends Notifier<CurrentPlayerState> {
  late AudioPlayer _player;
  AndroidEqualizer? _equalizer;
  static const _eqChannel = MethodChannel('com.tugtog.tugtog/equalizer');
  final List<StreamSubscription> _subscriptions = [];
  List<Track> _queueTracks = [];
  int _currentIndex = 0;
  Duration _currentPosition = Duration.zero;
  final AppDatabase _db = AppDatabase.instance;
  Timer? _sessionSaveDebounce;

  @override
  CurrentPlayerState build() {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _equalizer = AndroidEqualizer();
        _player = AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [_equalizer!],
          ),
        );
      } else {
        _player = AudioPlayer();
        _equalizer = null;
      }
    } catch (_) {
      _player = AudioPlayer();
      _equalizer = null;
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

        // Auto-advance to next track when current song finishes
        if (playerState.processingState == ProcessingState.completed) {
          if (state.loopMode == LoopMode.one) {
            seek(Duration.zero);
            play();
          } else {
            seekToNext();
          }
        }

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
          debugPrint('Playback error occurred in ExoPlayer: $e');
          _player.pause().catchError((_) {});
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
    final isContentUri = uriStr.startsWith('content://');
    final isRemote =
        uriStr.startsWith('http://') || uriStr.startsWith('https://');

    if (isContentUri || isRemote) {
      return AudioSource.uri(
        Uri.parse(uriStr),
        tag: mediaItem,
      );
    } else if (uriStr.isNotEmpty) {
      final localPath =
          uriStr.startsWith('file://') ? uriStr.substring(7) : uriStr;
      return AudioSource.file(
        localPath,
        tag: mediaItem,
      );
    } else {
      return AudioSource.uri(
        Uri.parse(uriStr),
        tag: mediaItem,
      );
    }
  }

  /// Resolves an audio track's playable URI if it is not already available.
  Future<Track> _resolveTrack(Track track) async {
    // 1. If already valid URI, return immediately
    if (track.mediaUri != null && track.mediaUri!.isNotEmpty) {
      return track;
    }

    // 2. Check offline disk cache
    final cachedPath =
        await TrackCacheService.instance.getCachedFilePath(track.id);
    if (cachedPath != null) {
      return track.copyWith(
        mediaUri: cachedPath,
        extraMetadata: {
          ...track.extraMetadata,
          'isDownloaded': true,
          'localFilePath': cachedPath,
        },
      );
    }

    // 3. Extract videoId
    String? videoId = track.extraMetadata['videoId'] as String?;
    if (videoId == null || videoId.isEmpty) {
      if (track.id.startsWith('ytm_')) {
        videoId = track.id.substring(4);
      }
    }

    if (videoId != null && videoId.isNotEmpty) {
      // Priority 1: High-speed Invidious proxy stream
      try {
        final proxiedUrl =
            await InvidiousStreamService.instance.getAudioStreamUrl(videoId);
        if (proxiedUrl != null) {
          return track.copyWith(
            mediaUri: proxiedUrl,
            extraMetadata: {
              ...track.extraMetadata,
              'videoId': videoId,
              'isProxied': true,
            },
          );
        }
      } catch (_) {}

      // Priority 2: Direct YouTubeExplode manifest
      try {
        final yt = YoutubeExplode();
        try {
          final manifest = await yt.videos.streamsClient.getManifest(videoId);
          final audioStreams = manifest.audioOnly;
          if (audioStreams.isNotEmpty) {
            final mp4Streams = audioStreams
                .where((s) => s.container.name.toLowerCase() == 'mp4')
                .toList();
            final selected = mp4Streams.isNotEmpty
                ? mp4Streams.withHighestBitrate()
                : audioStreams.withHighestBitrate();

            return track.copyWith(
              mediaUri: selected.url.toString(),
              extraMetadata: {
                ...track.extraMetadata,
                'videoId': videoId,
              },
            );
          }
        } finally {
          yt.close();
        }
      } catch (_) {}
    }

    return track;
  }

  /// Plays track at given index within the current queue, resolving online streams on-the-fly.
  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _queueTracks.length) return;

    _currentIndex = index;
    final originalTrack = _queueTracks[index];

    state = state.copyWith(
      currentIndex: index,
      currentTrack: originalTrack,
      isBuffering: true,
      position: Duration.zero,
      totalDuration: originalTrack.duration ?? Duration.zero,
    );

    final resolvedTrack = await _resolveTrack(originalTrack);
    _queueTracks[index] = resolvedTrack;

    state = state.copyWith(
      currentTrack: resolvedTrack,
      queue: List.unmodifiable(_queueTracks),
      totalDuration: resolvedTrack.duration ?? state.totalDuration,
    );

    try {
      final audioSource = _buildAudioSource(resolvedTrack);
      await _player.setAudioSource(audioSource);
      await _player.play();

      try {
        _db.logPlayHistory(resolvedTrack);
      } catch (_) {}
      _saveCurrentSession();
    } catch (e) {
      debugPrint('Playback error at index $index: $e');
      state = state.copyWith(isBuffering: false, isPlaying: false);
    }
  }

  /// Trigger Spotify-style autoplay / radio when reaching the end of the queue.
  Future<void> _triggerAutoplay() async {
    try {
      final yt = YoutubeExplode();
      try {
        final current = state.currentTrack;
        final query = current != null
            ? '${current.artist} hits'
            : 'OPM trending music hits';
        final searchResults = await yt.search.search(query);
        final newTracks = searchResults
            .where((v) => !_queueTracks.any((q) => q.id == 'ytm_${v.id.value}'))
            .take(10)
            .map((video) {
          final cleanArtist = video.author.endsWith(' - Topic')
              ? video.author.replaceAll(' - Topic', '')
              : video.author;
          return Track(
            id: 'ytm_${video.id.value}',
            title: video.title,
            artist: cleanArtist,
            duration: video.duration,
            artworkUrl: video.thumbnails.highResUrl,
            sourceType: AudioSourceType.youtubeMusic,
            extraMetadata: {
              'videoId': video.id.value,
              'channelId': video.channelId.value,
              'isOfficial': true,
            },
          );
        }).toList();

        if (newTracks.isNotEmpty) {
          _queueTracks.addAll(newTracks);
          state = state.copyWith(queue: List.unmodifiable(_queueTracks));
          if (_currentIndex < _queueTracks.length - 1) {
            await playTrackAtIndex(_currentIndex + 1);
          }
        }
      } finally {
        yt.close();
      }
    } catch (_) {}
  }

  /// Play a list of tracks starting from an initial index.
  Future<void> playSongList(List<Track> tracks, int initialIndex) async {
    if (tracks.isEmpty) return;

    _queueTracks = List.from(tracks);
    final validIndex = initialIndex.clamp(0, _queueTracks.length - 1);

    state = state.copyWith(
      queue: List.unmodifiable(_queueTracks),
      currentIndex: validIndex,
      currentTrack: _queueTracks[validIndex],
      position: Duration.zero,
      totalDuration: _queueTracks[validIndex].duration ?? Duration.zero,
    );

    await playTrackAtIndex(validIndex);
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
    if (_queueTracks.isEmpty) return;

    if (state.isShuffling && _queueTracks.length > 1) {
      final nextIdx =
          DateTime.now().millisecondsSinceEpoch % _queueTracks.length;
      final target = nextIdx == _currentIndex
          ? (nextIdx + 1) % _queueTracks.length
          : nextIdx;
      await playTrackAtIndex(target);
      return;
    }

    if (_currentIndex < _queueTracks.length - 1) {
      await playTrackAtIndex(_currentIndex + 1);
    } else if (state.loopMode == LoopMode.all) {
      await playTrackAtIndex(0);
    } else {
      await _triggerAutoplay();
    }
  }

  /// Skip to previous track, or restart current track if > 3 seconds.
  Future<void> seekToPrevious() async {
    if (_currentPosition.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_currentIndex > 0) {
      await playTrackAtIndex(_currentIndex - 1);
    } else {
      await seek(Duration.zero);
    }
  }

  /// Jump to a specific track index in the queue.
  Future<void> jumpToQueueItem(int index) async {
    await playTrackAtIndex(index);
  }

  /// Toggle shuffle mode on / off.
  Future<void> toggleShuffle() async {
    final enable = !state.isShuffling;
    state = state.copyWith(isShuffling: enable);
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
    state = state.copyWith(loopMode: next);
  }

  /// Add track right after the current playing song.
  Future<void> addToNext(Track track) async {
    final nextIndex = (_currentIndex + 1).clamp(0, _queueTracks.length);
    _queueTracks.insert(nextIndex, track);
    state = state.copyWith(queue: List.unmodifiable(_queueTracks));
    _saveCurrentSession();
  }

  /// Append track to the end of the queue.
  Future<void> addToEnd(Track track) async {
    _queueTracks.add(track);
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
      if (_currentIndex > index) {
        _currentIndex--;
      }
      state = state.copyWith(
        queue: List.unmodifiable(_queueTracks),
        currentIndex: _currentIndex,
      );
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

      if (_currentIndex == oldIndex) {
        _currentIndex = targetIndex;
      } else if (oldIndex < _currentIndex && targetIndex >= _currentIndex) {
        _currentIndex--;
      } else if (oldIndex > _currentIndex && targetIndex <= _currentIndex) {
        _currentIndex++;
      }

      state = state.copyWith(
        queue: List.unmodifiable(_queueTracks),
        currentIndex: _currentIndex,
      );
      _saveCurrentSession();
    }
  }

  /// Returns the Android Equalizer instance if supported.
  AndroidEqualizer? get equalizer => _equalizer;

  /// Retrieves the Android equalizer frequency parameters.
  Future<AndroidEqualizerParameters?> getEqualizerParameters() async {
    if (_equalizer == null) return null;
    try {
      return await _equalizer!.parameters.timeout(const Duration(seconds: 2));
    } catch (_) {
      return null;
    }
  }

  /// Opens the device/system native equalizer (Dolby Atmos, Mi Sound Enhancer, Dirac, etc.).
  Future<bool> openSystemEqualizer() async {
    try {
      final res = await _eqChannel.invokeMethod<bool>('openSystemEqualizer');
      return res ?? false;
    } catch (_) {
      return false;
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
