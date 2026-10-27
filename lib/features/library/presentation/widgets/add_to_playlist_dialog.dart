import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/track.dart';
import '../playlist_notifier.dart';

/// Bottom sheet dialog allowing the user to add a track to any playlist or create a new one.
class AddToPlaylistBottomSheet extends ConsumerWidget {
  final Track track;

  const AddToPlaylistBottomSheet({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistProvider);
    final playlists = playlistState.playlists;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add to playlist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // "+ New playlist" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('New playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _showCreatePlaylistDialog(context, ref);
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),

          // Playlists list
          Expanded(
            child: playlists.isEmpty
                ? const Center(
                    child: Text(
                      'No playlists found. Create one above!',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final pl = playlists[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.queue_music,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          pl.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${pl.trackCount} ${pl.trackCount == 1 ? "song" : "songs"}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () async {
                          await ref
                              .read(playlistProvider.notifier)
                              .addTrackToPlaylist(pl.id, track);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to ${pl.name}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Give your playlist a name',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'My Playlist #1',
            hintStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final id = await ref
                    .read(playlistProvider.notifier)
                    .createPlaylist(name);
                await ref
                    .read(playlistProvider.notifier)
                    .addTrackToPlaylist(id, track);
                if (context.mounted) {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created "$name" and added track'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
