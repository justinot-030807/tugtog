import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/track.dart';
import '../search_state.dart';
import 'search_track_tile.dart';

/// Renders an individual music source group in the search results
/// ("On your phone", "YouTube Music", "Audius", "Jamendo").
class SearchGroupSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final SourceSearchResult result;
  final void Function(Track track, int index, List<Track> tracks) onTrackTap;
  final VoidCallback onRetry;

  const SearchGroupSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.result,
    required this.onTrackTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // If not loading, no error, and no tracks, return a subtle empty note or empty widget
    if (!result.isLoading && result.error == null && result.tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              if (result.tracks.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${result.tracks.length}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 1. Loading state
        if (result.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Searching...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        // 2. Error state (isolated to this source)
        else if (result.error != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.error!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(40, 30),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        // 3. Results list
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: result.tracks.length,
            itemBuilder: (context, index) {
              final track = result.tracks[index];
              return SearchTrackTile(
                track: track,
                onTap: () => onTrackTap(track, index, result.tracks),
              );
            },
          ),

        const SizedBox(height: 14),
      ],
    );
  }
}
