import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/local_artist.dart';

/// List tile representing a local music artist with circular avatar.
class ArtistTile extends StatelessWidget {
  final LocalArtist artist;
  final VoidCallback onTap;

  const ArtistTile({
    super.key,
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tracksCount = artist.numberOfTracks ?? 0;
    final albumsCount = artist.numberOfAlbums ?? 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Circular artist avatar
            ClipOval(
              child: SizedBox(
                width: 50,
                height: 50,
                child: QueryArtworkWidget(
                  id: artist.id,
                  type: ArtworkType.ARTIST,
                  artworkBorder: BorderRadius.zero,
                  nullArtworkWidget: Container(
                    color: AppColors.surfaceElevated,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Artist name & info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artist.artist,
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
                    'Artist • $albumsCount ${albumsCount == 1 ? "album" : "albums"}, $tracksCount ${tracksCount == 1 ? "song" : "songs"}',
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
