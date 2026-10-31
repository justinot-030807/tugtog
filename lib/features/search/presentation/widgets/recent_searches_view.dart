import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/track.dart';

/// View displaying locally saved recent searches, recently played tracks, and browse genre categories.
class RecentSearchesView extends StatelessWidget {
  final List<String> recentSearches;
  final List<Track> recentlyPlayed;
  final void Function(String query) onSelectQuery;
  final void Function(String query) onRemoveQuery;
  final VoidCallback onClearAll;
  final void Function(Track track, int index, List<Track> queue)? onPlayTrack;

  const RecentSearchesView({
    super.key,
    required this.recentSearches,
    this.recentlyPlayed = const [],
    required this.onSelectQuery,
    required this.onRemoveQuery,
    required this.onClearAll,
    this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        if (recentlyPlayed.isNotEmpty) ...[
          const Text(
            'Recently played',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 165,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentlyPlayed.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final track = recentlyPlayed[index];
                return _buildRecentTrackCard(context, track, index);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...recentSearches.map((query) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(
                Icons.history,
                color: AppColors.textSecondary,
                size: 22,
              ),
              title: Text(
                query,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                onPressed: () => onRemoveQuery(query),
              ),
              onTap: () => onSelectQuery(query),
            );
          }),
          const SizedBox(height: 18),
        ],

        const Text(
          'Browse all',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Quick browse genre cards
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildCategoryCard('Pop Hits', Colors.deepOrange, () => onSelectQuery('Pop')),
            _buildCategoryCard('Filipino / OPM', Colors.purple, () => onSelectQuery('OPM')),
            _buildCategoryCard('Rock & Indie', Colors.teal, () => onSelectQuery('Rock')),
            _buildCategoryCard('Chillout', Colors.pink, () => onSelectQuery('Chill')),
            _buildCategoryCard('Hip-Hop', Colors.blueGrey, () => onSelectQuery('Hip-Hop')),
            _buildCategoryCard('Electronic', Colors.indigo, () => onSelectQuery('Electronic')),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTrackCard(BuildContext context, Track track, int index) {
    final genre = track.extraMetadata['genre'] as String?;
    final isOriginal = track.extraMetadata['isOriginalArtist'] == true ||
        track.extraMetadata['isOfficial'] == true;

    return InkWell(
      onTap: () => onPlayTrack?.call(track, index, recentlyPlayed),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: _buildArtwork(track),
                  ),
                ),
                if (isOriginal)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: AppColors.primary, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: AppColors.primary, size: 8),
                          SizedBox(width: 2),
                          Text(
                            'ORIG',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 7.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (genre != null && genre.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        genre.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(Track track) {
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
          size: 32,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
