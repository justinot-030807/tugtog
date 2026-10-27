import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/track.dart';

/// List tile representing a search result track with unified artwork, metadata, and source indicator.
class SearchTrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback onTap;

  const SearchTrackTile({
    super.key,
    required this.track,
    required this.onTap,
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
            // Artwork container
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _buildArtwork(),
              ),
            ),
            const SizedBox(width: 14),

            // Title, Artist & Duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _buildSourceBadge(),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Duration
            Text(
              track.formattedDuration,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    // 1. Local audio file artwork via MediaStore
    if (track.sourceType == AudioSourceType.local) {
      final songId = track.extraMetadata['songId'] as int? ??
          int.tryParse(track.id.replaceAll('local_', ''));
      if (songId != null) {
        return QueryArtworkWidget(
          id: songId,
          type: ArtworkType.AUDIO,
          artworkBorder: BorderRadius.zero,
          nullArtworkWidget: _buildPlaceholder(),
        );
      }
    }

    // 2. Network artwork (YouTube Music, Audius, Jamendo)
    if (track.artworkUrl != null && track.artworkUrl!.isNotEmpty) {
      return Image.network(
        track.artworkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Icon(
          Icons.music_note,
          color: AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSourceBadge() {
    Color color;
    String label;

    switch (track.sourceType) {
      case AudioSourceType.local:
        color = AppColors.primary;
        label = 'Phone';
        break;
      case AudioSourceType.youtubeMusic:
        color = Colors.redAccent;
        label = 'YTM';
        break;
      case AudioSourceType.audius:
        color = const Color(0xFFCC00FF);
        label = 'Audius';
        break;
      case AudioSourceType.jamendo:
        color = const Color(0xFFFF9900);
        label = 'Jamendo';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
