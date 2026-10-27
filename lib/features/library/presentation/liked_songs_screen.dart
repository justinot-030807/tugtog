import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/track.dart';
import '../../player/presentation/player_controller.dart';
import 'playlist_notifier.dart';

/// Screen displaying the user's Liked Songs with immediate playback and unliking.
class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistProvider);
    final favorites = playlistState.favorites;
    final playerState = ref.watch(playerControllerProvider);
    final currentTrack = playerState.currentTrack;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Liked Songs'),
      ),
      body: CustomScrollView(
        slivers: [
          // Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Liked Songs',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${favorites.length} ${favorites.length == 1 ? "song" : "songs"}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (favorites.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            ref
                                .read(playerControllerProvider.notifier)
                                .playSongList(favorites, 0);
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Shuffle'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(
                                color: AppColors.textSecondary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            final shuffled = List<Track>.from(favorites)
                              ..shuffle();
                            ref
                                .read(playerControllerProvider.notifier)
                                .playSongList(shuffled, 0);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // List of Liked Songs
          if (favorites.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border,
                          size: 56, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text(
                        'No liked songs yet',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap the heart icon on any song on Home, Search, or Now Playing to save your favorites here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text('Discover Music'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = favorites[index];
                  final isPlayingThis =
                      currentTrack != null && currentTrack.id == track.id;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 44,
                        height: 44,
                        color: AppColors.surfaceElevated,
                        child: const Icon(
                          Icons.music_note,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    title: Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPlayingThis
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      onPressed: () {
                        ref
                            .read(playlistProvider.notifier)
                            .toggleFavorite(track);
                      },
                    ),
                    onTap: () {
                      ref
                          .read(playerControllerProvider.notifier)
                          .playSongList(favorites, index);
                    },
                  );
                },
                childCount: favorites.length,
              ),
            ),
        ],
      ),
    );
  }
}
