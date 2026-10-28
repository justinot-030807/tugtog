import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/audio_permission_helper.dart';
import '../../../domain/models/playlist.dart';
import '../../player/presentation/player_controller.dart';
import 'downloaded_notifier.dart';
import 'downloaded_songs_screen.dart';
import 'liked_songs_screen.dart';
import 'local_library_notifier.dart';
import 'playlist_detail_screen.dart';
import 'playlist_notifier.dart';
import 'widgets/add_to_playlist_dialog.dart';
import 'widgets/album_tile.dart';
import 'widgets/artist_tile.dart';
import 'widgets/permission_request_card.dart';
import 'widgets/song_tile.dart';

/// Library screen displaying user Playlists, Songs, Albums, and Artists.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(localLibraryProvider);
    final playerState = ref.watch(playerControllerProvider);
    final playlistState = ref.watch(playlistProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Your Library'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New Playlist',
              onPressed: () => _showCreatePlaylistDialog(context),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: [
              Tab(text: 'Playlists'),
              Tab(text: 'Songs'),
              Tab(text: 'Albums'),
              Tab(text: 'Artists'),
            ],
          ),
        ),
        body: _buildBody(context, libraryState, playerState, playlistState),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LocalLibraryState libraryState,
    dynamic playerState,
    PlaylistState playlistState,
  ) {
    // 1. Permission Denied State
    if (libraryState.permissionState != AudioPermissionState.granted) {
      return PermissionRequestCard(
        permissionState: libraryState.permissionState,
        onRequestPermission: () {
          ref.read(localLibraryProvider.notifier).requestPermissionAndLoad();
        },
        onOpenSettings: () {
          ref.read(localLibraryProvider.notifier).openSettings();
        },
      );
    }

    // 2. Loading State
    if (libraryState.isLoading && libraryState.songs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // 3. Tab views
    return Column(
      children: [
        _buildSearchField(),
        Expanded(
          child: TabBarView(
            children: [
              _buildPlaylistsView(playlistState),
              _buildSongsView(libraryState, playerState),
              _buildAlbumsView(libraryState),
              _buildArtistsView(libraryState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        cursorColor: AppColors.primary,
        onChanged: (val) {
          ref.read(localLibraryProvider.notifier).setSearchQuery(val);
        },
        decoration: InputDecoration(
          hintText: 'Filter your library...',
          hintStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(localLibraryProvider.notifier).setSearchQuery('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surfaceElevated,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaylistsView(PlaylistState state) {
    final query = _searchController.text.toLowerCase().trim();
    final playlists = query.isEmpty
        ? state.playlists
        : state.playlists
            .where((p) => p.name.toLowerCase().contains(query))
            .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () => ref.read(playlistProvider.notifier).loadAll(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Pinned "Liked Songs" item
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 26),
            ),
            title: const Text(
              'Liked Songs',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Playlist • ${state.favorites.length} ${state.favorites.length == 1 ? "song" : "songs"}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LikedSongsScreen(),
                ),
              );
            },
          ),

          // Pinned "Downloaded Songs (Offline)" item
          Consumer(
            builder: (context, ref, child) {
              final downloadedState = ref.watch(downloadedProvider);
              final count = downloadedState.tracks.length;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D5235), Color(0xFF1DB954)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.download_done,
                      color: Colors.white, size: 26),
                ),
                title: const Text(
                  'Downloaded Songs',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Offline • $count ${count == 1 ? "song" : "songs"}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DownloadedSongsScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const Divider(color: AppColors.divider, height: 16),

          // User Playlists
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No playlists found.\nTap "+" above to create one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...playlists.map((pl) => _buildPlaylistTile(pl)),
        ],
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.queue_music,
          color: AppColors.primary,
          size: 26,
        ),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        'Playlist • ${playlist.trackCount} ${playlist.trackCount == 1 ? "song" : "songs"}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistDetailScreen(playlist: playlist),
          ),
        );
      },
    );
  }

  Widget _buildSongsView(LocalLibraryState state, dynamic playerState) {
    final songs = state.filteredSongs;
    final currentTrack = playerState.currentTrack;

    if (songs.isEmpty) {
      return _buildEmptyView('No audio files found on your device.');
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () =>
          ref.read(localLibraryProvider.notifier).loadLocalAudioData(),
      child: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final isPlayingThis = currentTrack != null &&
              currentTrack.id == 'local_${song.id}';

          return SongTile(
            song: song,
            isPlaying: isPlayingThis,
            onTap: () {
              final allTracks = songs.map((s) => s.toTrack()).toList();
              ref
                  .read(playerControllerProvider.notifier)
                  .playSongList(allTracks, index);
            },
            onPlayNext: () {
              ref
                  .read(playerControllerProvider.notifier)
                  .addToNext(song.toTrack());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Playing next: ${song.title}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            onAddToQueue: () {
              ref
                  .read(playerControllerProvider.notifier)
                  .addToEnd(song.toTrack());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added to queue: ${song.title}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            onAddToPlaylist: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) =>
                    AddToPlaylistBottomSheet(track: song.toTrack()),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAlbumsView(LocalLibraryState state) {
    final albums = state.filteredAlbums;

    if (albums.isEmpty) {
      return _buildEmptyView('No albums found on your device.');
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () =>
          ref.read(localLibraryProvider.notifier).loadLocalAudioData(),
      child: ListView.builder(
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return AlbumTile(
            album: album,
            onTap: () {
              _searchController.text = album.album;
              ref.read(localLibraryProvider.notifier).setSearchQuery(album.album);
              DefaultTabController.of(context).animateTo(1);
            },
          );
        },
      ),
    );
  }

  Widget _buildArtistsView(LocalLibraryState state) {
    final artists = state.filteredArtists;

    if (artists.isEmpty) {
      return _buildEmptyView('No artists found on your device.');
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      onRefresh: () =>
          ref.read(localLibraryProvider.notifier).loadLocalAudioData(),
      child: ListView.builder(
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return ArtistTile(
            artist: artist,
            onTap: () {
              _searchController.text = artist.artist;
              ref.read(localLibraryProvider.notifier).setSearchQuery(artist.artist);
              DefaultTabController.of(context).animateTo(1);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.music_off_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
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
                await ref.read(playlistProvider.notifier).createPlaylist(name);
                if (context.mounted) {
                  Navigator.pop(context);
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
