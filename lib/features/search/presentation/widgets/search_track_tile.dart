import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/track.dart';
import '../../../library/presentation/downloaded_notifier.dart';

/// List tile representing a search result track with unified artwork, metadata, and source indicator.
class SearchTrackTile extends ConsumerWidget {
  final Track track;
  final VoidCallback onTap;

  const SearchTrackTile({
    super.key,
    required this.track,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDownloaded =
        ref.watch(downloadedProvider).tracks.any((t) => t.id == track.id);
    final isOnline = track.sourceType != AudioSourceType.local;
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
                      if (_shouldShowBadge) ...[
                        _buildSourceBadge(),
                        const SizedBox(width: 6),
                      ],
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

            // Download indicator or action button
            if (isDownloaded)
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Icon(Icons.download_done, color: AppColors.primary, size: 18),
              )
            else if (isOnline)
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_circle_down_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Download for offline play',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading "${track.title}" for offline play...'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    final res = await ref.read(downloadedProvider.notifier).downloadTrack(track);
                    if (context.mounted && res != null) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Saved "${track.title}" to Downloaded Songs!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
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

  bool get _shouldShowBadge =>
      track.extraMetadata['isOfficial'] == true ||
      track.sourceType == AudioSourceType.local;

  Widget _buildSourceBadge() {
    if (track.extraMetadata['isOfficial'] == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.primary, width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.primary, size: 9),
            SizedBox(width: 3),
            Text(
              'ORIGINAL',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      );
    }

    if (track.sourceType == AudioSourceType.local) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.blueAccent, width: 0.8),
        ),
        child: const Text(
          'PHONE',
          style: TextStyle(
            color: Colors.blueAccent,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
