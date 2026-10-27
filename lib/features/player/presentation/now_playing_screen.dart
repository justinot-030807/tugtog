import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/track.dart';
import '../../library/presentation/playlist_notifier.dart';
import '../../library/presentation/widgets/add_to_playlist_dialog.dart';
import '../models/player_state.dart';
import 'player_controller.dart';
import 'sleep_timer_notifier.dart';
import 'widgets/equalizer_bottom_sheet.dart';
import 'widgets/queue_bottom_sheet.dart';
import 'widgets/sleep_timer_bottom_sheet.dart';

/// Full-screen Spotify-style Now Playing view with dynamic album-art colors,
/// equalizer, sleep timer, seek bar, controls, and queue.
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  double? _dragValue;
  Color _dynamicColor = const Color(0xFF1DB954);
  String? _lastTrackKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _extractPalette();
  }

  Future<void> _extractPalette() async {
    final track = ref.read(playerControllerProvider).currentTrack;
    if (track == null) return;

    final trackKey = '${track.id}_${track.artworkUrl}';
    if (_lastTrackKey == trackKey) return;
    _lastTrackKey = trackKey;

    if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty) {
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          NetworkImage(track.artworkUrl!),
          maximumColorCount: 16,
        );
        final color = palette.dominantColor?.color ??
            palette.vibrantColor?.color ??
            palette.mutedColor?.color;

        if (color != null && mounted) {
          setState(() => _dynamicColor = color);
        }
      } catch (_) {}
    } else {
      if (mounted) {
        setState(() => _dynamicColor = AppColors.primary);
      }
    }
  }

  void _showSleepTimerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SleepTimerBottomSheet(),
    );
  }

  void _showEqualizerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EqualizerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final track = playerState.currentTrack;
    final sleepTimer = ref.watch(sleepTimerProvider);

    // Trigger palette extraction when current track updates
    if (track != null && '${track.id}_${track.artworkUrl}' != _lastTrackKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _extractPalette());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'PLAYING FROM PLAYLIST',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              track?.album ?? 'Local Storage',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppColors.surfaceElevated,
            onSelected: (val) {
              if (val == 'playlist' && track != null) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddToPlaylistBottomSheet(track: track),
                );
              } else if (val == 'sleep_timer') {
                _showSleepTimerSheet();
              } else if (val == 'equalizer') {
                _showEqualizerSheet();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sleep_timer',
                child: Row(
                  children: [
                    Icon(Icons.bedtime_outlined,
                        color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 10),
                    Text('Sleep timer',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'equalizer',
                child: Row(
                  children: [
                    Icon(Icons.equalizer,
                        color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 10),
                    Text('Equalizer',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'playlist',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add,
                        color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 10),
                    Text('Add to playlist',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // Animated gradient adapting dynamically to the album art colors
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _dynamicColor.withValues(alpha: 0.65),
              const Color(0xFF161616),
              const Color(0xFF121212),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Large Artwork Display
                _buildArtwork(track),

                const Spacer(flex: 1),

                // Title, Artist, & Favorite
                _buildTrackInfo(track),

                const SizedBox(height: 16),

                // Seek Slider & Duration Labels
                _buildSeekBar(playerState),

                const SizedBox(height: 16),

                // Playback Controls Row
                _buildControls(playerState),

                const SizedBox(height: 20),

                // Bottom Utilities (Sleep Timer, Equalizer, Queue)
                _buildBottomUtilities(context, sleepTimer),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork(Track? track) {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildArtworkContent(track),
        ),
      ),
    );
  }

  Widget _buildArtworkContent(Track? track) {
    if (track == null) {
      return Container(
        color: AppColors.surfaceElevated,
        child: const Icon(Icons.music_note, size: 80, color: AppColors.textSecondary),
      );
    }

    if (track.sourceType == AudioSourceType.local) {
      final songId = track.extraMetadata['songId'] as int? ??
          int.tryParse(track.id.replaceAll('local_', ''));
      if (songId != null) {
        return QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkBorder: BorderRadius.zero,
          artworkWidth: 300,
          artworkHeight: 300,
          nullArtworkWidget: Container(
            color: AppColors.surfaceElevated,
            child: const Icon(Icons.music_note, size: 80, color: AppColors.primary),
          ),
        );
      }
    }

    if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty) {
      return Image.network(
        track.artworkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surfaceElevated,
          child: const Icon(Icons.music_note, size: 80, color: AppColors.primary),
        ),
      );
    }

    return Container(
      color: AppColors.surfaceElevated,
      child: const Icon(Icons.music_note, size: 80, color: AppColors.primary),
    );
  }

  Widget _buildTrackInfo(Track? track) {
    final playlistState = ref.watch(playlistProvider);
    final isFav = track != null && playlistState.favorites.any((f) => f.id == track.id);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track?.title ?? 'No Track Playing',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                track?.artist ?? 'Unknown Artist',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? AppColors.primary : AppColors.textSecondary,
            size: 28,
          ),
          onPressed: track != null
              ? () {
                  ref.read(playlistProvider.notifier).toggleFavorite(track);
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSeekBar(CurrentPlayerState playerState) {
    final total = playerState.totalDuration.inMilliseconds.toDouble();
    final current = (_dragValue ?? playerState.position.inMilliseconds.toDouble())
        .clamp(0.0, total > 0 ? total : 0.0);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppColors.textPrimary,
            inactiveTrackColor: Colors.white24,
            thumbColor: AppColors.textPrimary,
          ),
          child: Slider(
            min: 0.0,
            max: total > 0 ? total : 1.0,
            value: current,
            onChanged: (val) {
              setState(() => _dragValue = val);
            },
            onChangeEnd: (val) {
              ref
                  .read(playerControllerProvider.notifier)
                  .seek(Duration(milliseconds: val.toInt()));
              setState(() => _dragValue = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(Duration(milliseconds: current.toInt())),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                _formatDuration(playerState.totalDuration),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(CurrentPlayerState playerState) {
    final notifier = ref.read(playerControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle,
            size: 24,
            color: playerState.isShuffling ? AppColors.primary : AppColors.textSecondary,
          ),
          onPressed: notifier.toggleShuffle,
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_previous,
            size: 38,
            color: AppColors.textPrimary,
          ),
          onPressed: notifier.seekToPrevious,
        ),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.textPrimary,
          ),
          child: IconButton(
            icon: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
              size: 36,
              color: Colors.black,
            ),
            onPressed: notifier.togglePlayPause,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.skip_next,
            size: 38,
            color: AppColors.textPrimary,
          ),
          onPressed: notifier.seekToNext,
        ),
        IconButton(
          icon: _buildRepeatIcon(playerState.loopMode),
          onPressed: notifier.cycleRepeatMode,
        ),
      ],
    );
  }

  Widget _buildRepeatIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return const Icon(Icons.repeat, size: 24, color: AppColors.textSecondary);
      case LoopMode.all:
        return const Icon(Icons.repeat, size: 24, color: AppColors.primary);
      case LoopMode.one:
        return const Icon(Icons.repeat_one, size: 24, color: AppColors.primary);
    }
  }

  Widget _buildBottomUtilities(BuildContext context, SleepTimerState sleepTimer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Sleep Timer Button with active countdown badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Sleep Timer',
              icon: Icon(
                sleepTimer.isActive ? Icons.bedtime : Icons.bedtime_outlined,
                size: 22,
                color: sleepTimer.isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              onPressed: _showSleepTimerSheet,
            ),
            if (sleepTimer.isActive)
              Positioned(
                right: 2,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),

        // Equalizer Button
        IconButton(
          tooltip: 'Equalizer',
          icon: const Icon(
            Icons.equalizer,
            size: 22,
            color: AppColors.textSecondary,
          ),
          onPressed: _showEqualizerSheet,
        ),

        // Queue Sheet Button
        IconButton(
          tooltip: 'Queue',
          icon: const Icon(
            Icons.queue_music,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const QueueBottomSheet(),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
