import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/navigation_provider.dart';
import '../../../domain/models/playlist.dart';
import '../../../domain/models/track.dart';
import '../../library/presentation/downloaded_notifier.dart';
import '../../library/presentation/downloaded_songs_screen.dart';
import '../../library/presentation/liked_songs_screen.dart';
import '../../library/presentation/playlist_detail_screen.dart';
import '../../library/presentation/playlist_notifier.dart';
import '../../player/presentation/player_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/presentation/yt_music_login_screen.dart';
import '../../../data/sources/ytm/yt_music_auth_service.dart';
import 'discover_notifier.dart';
import 'ytm_history_notifier.dart';

/// Home tab showing Discover (Audius + Jamendo), YouTube Music history, Local history, and playlists.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistState = ref.watch(playlistProvider);
    final recentlyPlayed = playlistState.recentlyPlayed;
    final playlists = playlistState.playlists;
    final favorites = playlistState.favorites;
    final ytmHistoryState = ref.watch(ytmHistoryProvider);
    final discoverState = ref.watch(discoverProvider);
    final downloadedState = ref.watch(downloadedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Good evening'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(playlistProvider.notifier).loadAll();
              ref.read(ytmHistoryProvider.notifier).fetchHistory();
              ref.read(discoverProvider.notifier).fetchDiscoverTracks();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () async {
          await Future.wait([
            ref.read(playlistProvider.notifier).loadAll(),
            ref.read(ytmHistoryProvider.notifier).fetchHistory(),
            ref.read(discoverProvider.notifier).fetchDiscoverTracks(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Quick Access Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildQuickCard(
                  context,
                  title: 'Liked Songs',
                  subtitle: '${favorites.length} songs',
                  icon: Icons.favorite,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF450AF5), Color(0xFFC4EFD9)],
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
                _buildQuickCard(
                  context,
                  title: 'Downloaded',
                  subtitle: '${downloadedState.tracks.length} songs (offline)',
                  icon: Icons.download_done,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D5235), Color(0xFF1DB954)],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DownloadedSongsScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickCard(
                  context,
                  title: 'Local Music',
                  subtitle: 'Device Audio',
                  icon: Icons.phone_android,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                  onTap: () {
                    ref.read(navigationProvider.notifier).selectTab(2);
                  },
                ),
                _buildQuickCard(
                  context,
                  title: 'Your Playlists',
                  subtitle: '${playlists.length} playlists',
                  icon: Icons.queue_music,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
                  ),
                  onTap: () {
                    ref.read(navigationProvider.notifier).selectTab(2);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SECTION 1: Discover (Audius + Jamendo Streaming)
            _buildDiscoverSection(context, ref, discoverState),
            const SizedBox(height: 28),

            // SECTION 2: Recently played on YouTube Music
            _buildYtmHistorySection(context, ref, ytmHistoryState),
            const SizedBox(height: 28),

            // SECTION 3: Recently played (local)
            const Text(
              'Recently played (local)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (recentlyPlayed.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.history, color: AppColors.textSecondary),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'No local play history yet. Play songs from your library to see them here!',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 175,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentlyPlayed.length,
                  itemBuilder: (context, index) {
                    final track = recentlyPlayed[index];
                    return _buildRecentTrackCard(
                        context, ref, track, recentlyPlayed, index);
                  },
                ),
              ),
            const SizedBox(height: 28),

            // SECTION 4: Your Playlists
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your playlists',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                  label: const Text(
                    'New',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _showCreatePlaylistDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (playlists.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Create your first personal playlist to organize your favorite tracks.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _showCreatePlaylistDialog(context, ref),
                      child: const Text('Create'),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: playlists.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildCreatePlaylistCard(context, ref);
                    }
                    final playlist = playlists[index - 1];
                    return _buildPlaylistCard(context, playlist);
                  },
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Builds the Discover section with genre chips and streaming tracks.
  Widget _buildDiscoverSection(
    BuildContext context,
    WidgetRef ref,
    DiscoverState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trending free music from Audius & Jamendo',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
              onPressed: () =>
                  ref.read(discoverProvider.notifier).fetchDiscoverTracks(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Genre filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: DiscoverGenres.list.map((genre) {
              final isSelected = state.selectedGenre == genre;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(genre),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.black,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (_) {
                    ref.read(discoverProvider.notifier).selectGenre(genre);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Content
        if (state.isLoading)
          SizedBox(
            height: 185,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) => _buildShimmerTrackCard(),
            ),
          )
        else if (state.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(discoverProvider.notifier).fetchDiscoverTracks(),
                  child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          )
        else if (state.tracks.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No tracks found for this genre.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.tracks.length,
              itemBuilder: (context, index) {
                final track = state.tracks[index];
                return _buildDiscoverTrackCard(context, ref, track, state.tracks, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDiscoverTrackCard(
    BuildContext context,
    WidgetRef ref,
    Track track,
    List<Track> queue,
    int index,
  ) {
    final isAudius = track.sourceType == AudioSourceType.audius;
    final badgeColor = isAudius ? const Color(0xFFCC00FF) : const Color(0xFFFF9900);
    final badgeLabel = isAudius ? 'Audius' : 'Jamendo';

    return Container(
      width: 135,
      margin: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // Play directly via PlayerController and just_audio URL stream!
          ref.read(playerControllerProvider.notifier).playSongList(queue, index);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 135,
                    height: 120,
                    color: AppColors.surfaceElevated,
                    child: track.artworkUrl != null
                        ? Image.network(
                            track.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(Icons.music_note,
                                  size: 40, color: AppColors.primary),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.music_note,
                                size: 40, color: AppColors.primary),
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the YouTube Music recently played horizontal section with loading, error, and empty states.
  Widget _buildYtmHistorySection(
    BuildContext context,
    WidgetRef ref,
    YtmHistoryState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 22),
                SizedBox(width: 8),
                Text(
                  'Recently played on YouTube Music',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
              onPressed: () =>
                  ref.read(ytmHistoryProvider.notifier).fetchHistory(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 1. Loading State
        if (state.isLoading)
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) => _buildShimmerTrackCard(),
            ),
          )
        // 2. Empty or Not Connected State (Friendly card instead of scary red error)
        else if (state.tracks.isEmpty)
          FutureBuilder<bool>(
            future: YtMusicAuthService.isLoggedIn(),
            builder: (context, snapshot) {
              final isLoggedIn = snapshot.data == true;
              if (isLoggedIn) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.primary, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connected to YouTube Music. Listen to tracks on YouTube Music to display them here!',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Not logged in: Show stylish Connect card
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect YouTube Music (Optional)',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Log in with Google to view your recently played YouTube Music tracks.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const YtMusicLoginScreen()),
                        );
                      },
                      child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              );
            },
          )
        // 4. Loaded State
        else
          SizedBox(
            height: 185,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.tracks.length,
              itemBuilder: (context, index) {
                final track = state.tracks[index];
                return _buildYtmTrackCard(context, ref, track);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildYtmTrackCard(BuildContext context, WidgetRef ref, Track track) {
    final playedLabel = track.extraMetadata['played'] as String?;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await ref.read(ytStreamResolverProvider).resolveAndPlay(
                context: context,
                ref: ref,
                track: track,
              );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 130,
                    height: 120,
                    color: AppColors.surfaceElevated,
                    child: track.artworkUrl != null
                        ? Image.network(
                            track.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                              child: Icon(Icons.music_note,
                                  size: 40, color: AppColors.primary),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.music_note,
                                size: 40, color: AppColors.primary),
                          ),
                  ),
                ),
                if (playedLabel != null && playedLabel.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        playedLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerTrackCard() {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 130,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.divider,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTrackCard(
    BuildContext context,
    WidgetRef ref,
    Track track,
    List<Track> queue,
    int index,
  ) {
    final songId = track.extraMetadata['songId'];

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          ref.read(playerControllerProvider.notifier).playSongList(queue, index);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 130,
                height: 120,
                color: AppColors.surfaceElevated,
                child: (track.sourceType == AudioSourceType.local &&
                        songId is int)
                    ? QueryArtworkWidget(
                        id: songId,
                        type: ArtworkType.AUDIO,
                        artworkWidth: 130,
                        artworkHeight: 120,
                        artworkBorder: BorderRadius.zero,
                        nullArtworkWidget: const Center(
                          child: Icon(Icons.music_note,
                              size: 44, color: AppColors.primary),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.music_note,
                            size: 44, color: AppColors.primary),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePlaylistCard(BuildContext context, WidgetRef ref) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showCreatePlaylistDialog(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 130,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.divider,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 40, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create Playlist',
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'New mix',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, Playlist playlist) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistDetailScreen(playlist: playlist),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 130,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.queue_music,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${playlist.trackCount} ${playlist.trackCount == 1 ? "song" : "songs"}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
