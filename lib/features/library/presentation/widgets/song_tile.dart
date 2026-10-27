import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/song.dart';

/// List tile representing a single device audio file with artwork, duration, and playlist options.
class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onAddToPlaylist;
  final bool isPlaying;

  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.onPlayNext,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Embedded artwork via QueryArtworkWidget
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.zero,
                  nullArtworkWidget: Container(
                    color: AppColors.surfaceElevated,
                    child: const Icon(
                      Icons.music_note,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title & Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isPlaying ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${song.artist}${song.album != null ? " • ${song.album}" : ""}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Duration
            Text(
              song.formattedDuration,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),

            // More actions
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                size: 18,
                color: AppColors.textSecondary,
              ),
              color: AppColors.surfaceElevated,
              onSelected: (action) {
                if (action == 'next') {
                  onPlayNext?.call();
                } else if (action == 'queue') {
                  onAddToQueue?.call();
                } else if (action == 'playlist') {
                  onAddToPlaylist?.call();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'next',
                  child: Row(
                    children: [
                      Icon(Icons.playlist_play,
                          size: 20, color: AppColors.textPrimary),
                      SizedBox(width: 10),
                      Text(
                        'Play next',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'queue',
                  child: Row(
                    children: [
                      Icon(Icons.queue_music,
                          size: 20, color: AppColors.textPrimary),
                      SizedBox(width: 10),
                      Text(
                        'Add to queue',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'playlist',
                  child: Row(
                    children: [
                      Icon(Icons.playlist_add,
                          size: 20, color: AppColors.textPrimary),
                      SizedBox(width: 10),
                      Text(
                        'Add to playlist',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
