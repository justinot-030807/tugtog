import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/track_cache_service.dart';
import '../../../domain/models/track.dart';
import '../../player/presentation/player_controller.dart';
import 'downloaded_notifier.dart';

/// Screen displaying all offline downloaded and cached tracks (Spotify Premium style).
class DownloadedSongsScreen extends ConsumerStatefulWidget {
  const DownloadedSongsScreen({super.key});

  @override
  ConsumerState<DownloadedSongsScreen> createState() =>
      _DownloadedSongsScreenState();
}

class _DownloadedSongsScreenState extends ConsumerState<DownloadedSongsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadedState = ref.watch(downloadedProvider);
    final allTracks = downloadedState.tracks;
    final filteredTracks = _searchFilter.isEmpty
        ? allTracks
        : allTracks
            .where((t) =>
                t.title.toLowerCase().contains(_searchFilter) ||
                t.artist.toLowerCase().contains(_searchFilter))
            .toList();

    final playerState = ref.watch(playerControllerProvider);
    final currentTrack = playerState.currentTrack;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Downloaded Music'),
        actions: [
          if (allTracks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'Clear All Downloads',
              onPressed: () => _confirmClearAll(context),
            ),
        ],
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
                        colors: [Color(0xFF0D5235), Color(0xFF1DB954)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.download_done,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Downloaded Songs',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${allTracks.length} ${allTracks.length == 1 ? "song" : "songs"} • ${TrackCacheService.formatBytes(downloadedState.totalSizeBytes)} (Offline)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (allTracks.isNotEmpty)
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
                                .playSongList(allTracks, 0);
                          },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.shuffle, color: AppColors.textPrimary),
                          label: const Text(
                            'Shuffle',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.divider),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            final shuffled = List<Track>.from(allTracks)..shuffle();
                            ref
                                .read(playerControllerProvider.notifier)
                                .playSongList(shuffled, 0);
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Search Filter Field
                  if (allTracks.length > 4)
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Filter downloaded songs...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchFilter = val.toLowerCase().trim();
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // Empty State
          if (filteredTracks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_download_outlined,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchFilter.isEmpty
                            ? 'No downloaded songs yet'
                            : 'No matches found',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchFilter.isEmpty
                            ? 'Songs you play from YouTube Music are automatically cached here for offline listening, or you can tap download on any song!'
                            : 'Try searching with a different title or artist.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Track List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = filteredTracks[index];
                  final isCurrent = currentTrack?.id == track.id;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: track.artworkUrl != null
                          ? Image.network(
                              track.artworkUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.music_note,
                                color: AppColors.textSecondary,
                              ),
                            )
                          : const Icon(
                              Icons.music_note,
                              color: AppColors.textSecondary,
                            ),
                    ),
                    title: Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                        color:
                            isCurrent ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        const Icon(
                          Icons.download_done,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${track.artist} • ${track.formattedDuration}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      color: AppColors.surfaceElevated,
                      onSelected: (value) async {
                        if (value == 'remove') {
                          await ref
                              .read(downloadedProvider.notifier)
                              .removeTrack(track.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 20),
                              SizedBox(width: 8),
                              Text('Delete from Downloads',
                                  style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref
                          .read(playerControllerProvider.notifier)
                          .playSongList(filteredTracks, index);
                    },
                  );
                },
                childCount: filteredTracks.length,
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Clear All Downloads?'),
        content: const Text(
          'This will delete all offline music from your device storage to free up space. You can re-download them anytime.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(downloadedProvider.notifier).clearAll();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('All downloaded tracks cleared.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
