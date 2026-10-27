import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/track.dart';
import '../player_controller.dart';

/// Interactive Queue management bottom sheet with reordering and removal.
class QueueBottomSheet extends ConsumerWidget {
  const QueueBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final queue = playerState.queue;
    final currentIndex = playerState.currentIndex;
    final currentTrack = playerState.currentTrack;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Queue',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${queue.length} ${queue.length == 1 ? "track" : "tracks"}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),

          Expanded(
            child: queue.isEmpty
                ? const Center(
                    child: Text(
                      'Queue is empty',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // Section: Now Playing
                      if (currentTrack != null) ...[
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              'Now Playing',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                _buildTrackArtwork(currentTrack),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentTrack.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentTrack.artist,
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
                                const Icon(
                                  Icons.equalizer,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Section: Next In Queue
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Text(
                            'Next In Queue',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      SliverReorderableList(
                        itemCount: queue.length,
                        onReorder: (oldIndex, newIndex) {
                          ref
                              .read(playerControllerProvider.notifier)
                              .reorderQueue(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final track = queue[index];
                          final isCurrent = index == currentIndex;

                          return Material(
                            key: ValueKey('${track.id}_$index'),
                            color: isCurrent
                                ? AppColors.surfaceElevated
                                : Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 2,
                              ),
                              leading: _buildTrackArtwork(track),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      ref
                                          .read(playerControllerProvider.notifier)
                                          .removeFromQueue(index);
                                    },
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(
                                      Icons.drag_handle,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .jumpToQueueItem(index);
                              },
                            ),
                          );
                        },
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackArtwork(Track track) {
    final songId = track.extraMetadata['songId'];

    if (track.sourceType == AudioSourceType.local && songId is int) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 44,
          height: 44,
          child: QueryArtworkWidget(
            id: songId,
            type: ArtworkType.AUDIO,
            nullArtworkWidget: Container(
              color: AppColors.surfaceElevated,
              child: const Icon(
                Icons.music_note,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.music_note,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}
