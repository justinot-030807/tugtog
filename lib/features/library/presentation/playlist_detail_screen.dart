import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/playlist.dart';
import '../../../domain/models/track.dart';
import '../../player/presentation/player_controller.dart';
import 'playlist_notifier.dart';

/// Screen displaying playlist contents, actions (play, shuffle, delete), and tracks.
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistDetailScreen> createState() =>
      _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);
    final tracks = await ref
        .read(playlistProvider.notifier)
        .getPlaylistTracks(widget.playlist.id);
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final currentTrack = playerState.currentTrack;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.playlist.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppColors.surfaceElevated,
            onSelected: (val) {
              if (val == 'rename') {
                _showRenameDialog(context);
              } else if (val == 'delete') {
                _confirmDelete(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'rename',
                child: Text('Rename Playlist',
                    style: TextStyle(color: AppColors.textPrimary)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete Playlist',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : CustomScrollView(
              slivers: [
                // Header Info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Playlist Icon Box
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
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
                            Icons.queue_music,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.playlist.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_tracks.length} ${_tracks.length == 1 ? "song" : "songs"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Play & Shuffle buttons
                        if (_tracks.isNotEmpty)
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
                                      .playSongList(_tracks, 0);
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
                                onPressed: () async {
                                  final shuffled = List<Track>.from(_tracks)
                                    ..shuffle();
                                  await ref
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

                // Tracks List
                if (_tracks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_note,
                                size: 56, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            const Text(
                              'This playlist is empty',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Browse songs on your phone or search Discover & YouTube Music, then tap ⋮ to add tracks here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Browse & Search Music'),
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
                        final track = _tracks[index];
                        final isPlayingThis = currentTrack != null &&
                            currentTrack.id == track.id;

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
                              Icons.remove_circle_outline,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () async {
                              await ref
                                  .read(playlistProvider.notifier)
                                  .removeTrackFromPlaylist(
                                    widget.playlist.id,
                                    track.id,
                                  );
                              _loadTracks();
                            },
                          ),
                          onTap: () {
                            ref
                                .read(playerControllerProvider.notifier)
                                .playSongList(_tracks, index);
                          },
                        );
                      },
                      childCount: _tracks.length,
                    ),
                  ),
              ],
            ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.playlist.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Rename Playlist',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Playlist name',
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
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ref
                    .read(playlistProvider.notifier)
                    .renamePlaylist(widget.playlist.id, newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context); // return to library
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Delete Playlist?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${widget.playlist.name}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref
                  .read(playlistProvider.notifier)
                  .deletePlaylist(widget.playlist.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context); // return to library
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
