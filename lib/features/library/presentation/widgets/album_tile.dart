import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/local_album.dart';

/// Grid item or list tile representing a local music album.
class AlbumTile extends StatelessWidget {
  final LocalAlbum album;
  final VoidCallback onTap;

  const AlbumTile({
    super.key,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Album Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 52,
                height: 52,
                child: QueryArtworkWidget(
                  id: album.id,
                  type: ArtworkType.ALBUM,
                  artworkBorder: BorderRadius.zero,
                  nullArtworkWidget: Container(
                    color: AppColors.surfaceElevated,
                    child: const Icon(
                      Icons.album,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Album metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${album.artist} • ${album.numOfSongs} ${album.numOfSongs == 1 ? "song" : "songs"}',
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
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
