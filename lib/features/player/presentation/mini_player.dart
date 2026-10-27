import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/track.dart';
import '../../library/presentation/playlist_notifier.dart';
import 'now_playing_screen.dart';
import 'player_controller.dart';

/// Floating mini player widget docked above the bottom navigation bar.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final track = playerState.currentTrack;

    // Do not show mini player if there is no loaded track
    if (track == null) return const SizedBox.shrink();

    return Dismissible(
      key: Key('mini_player_${track.id}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        // Stop audio playback and dismiss mini player
        ref.read(playerControllerProvider.notifier).stopAndClear();
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 22),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: GestureDetector(
          onTap: () => _openNowPlayingScreen(context),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E2E),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main content row
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        // Album Artwork thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: _buildArtworkThumbnail(track),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Track details
                        Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Favorite toggle
                      Builder(builder: (context) {
                        final isFavorite = ref
                            .watch(playlistProvider)
                            .favorites
                            .any((t) => t.id == track.id);
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            ref
                                .read(playlistProvider.notifier)
                                .toggleFavorite(track);
                          },
                        );
                      }),

                      // Play/Pause button
                      IconButton(
                        icon: playerState.isBuffering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : Icon(
                                playerState.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: AppColors.textPrimary,
                                size: 28,
                              ),
                        onPressed: () {
                          ref
                              .read(playerControllerProvider.notifier)
                              .togglePlayPause();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom micro progress bar
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                child: LinearProgressIndicator(
                  value: playerState.progress,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildArtworkThumbnail(Track track) {
    final songId = track.extraMetadata['songId'];

    if (track.sourceType == AudioSourceType.local && songId is int) {
      return QueryArtworkWidget(
        id: songId,
        type: ArtworkType.AUDIO,
        artworkBorder: BorderRadius.zero,
        nullArtworkWidget: Container(
          color: AppColors.surface,
          child: const Icon(
            Icons.music_note,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      child: const Icon(
        Icons.music_note,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }

  void _openNowPlayingScreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}
