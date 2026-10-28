import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/db/app_database.dart';
import '../../../domain/models/playlist.dart';
import '../../../domain/models/track.dart';

/// State representation for user playlists, favorites, and history.
class PlaylistState {
  final List<Playlist> playlists;
  final List<Track> favorites;
  final List<Track> recentlyPlayed;
  final bool isLoading;

  const PlaylistState({
    this.playlists = const [],
    this.favorites = const [],
    this.recentlyPlayed = const [],
    this.isLoading = false,
  });

  PlaylistState copyWith({
    List<Playlist>? playlists,
    List<Track>? favorites,
    List<Track>? recentlyPlayed,
    bool? isLoading,
  }) {
    return PlaylistState(
      playlists: playlists ?? this.playlists,
      favorites: favorites ?? this.favorites,
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider for the AppDatabase instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

/// Riverpod Notifier managing playlist CRUD, favorites, and local history.
class PlaylistNotifier extends Notifier<PlaylistState> {
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  PlaylistState build() {
    Future.microtask(() => loadAll());
    return const PlaylistState();
  }

  /// Load playlists, liked songs, and recently played from local database.
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final playlistsFuture = _db.getAllPlaylists();
      final favoritesFuture = _db.getAllFavorites();
      final historyFuture = _db.getRecentlyPlayed(limit: 15);

      final results =
          await Future.wait([playlistsFuture, favoritesFuture, historyFuture]);

      state = state.copyWith(
        isLoading: false,
        playlists: results[0] as List<Playlist>,
        favorites: results[1] as List<Track>,
        recentlyPlayed: results[2] as List<Track>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Create a new playlist.
  Future<int> createPlaylist(String name) async {
    final id = await _db.createPlaylist(name);
    await loadAll();
    return id;
  }

  /// Rename an existing playlist.
  Future<void> renamePlaylist(int id, String newName) async {
    await _db.renamePlaylist(id, newName);
    await loadAll();
  }

  /// Delete a playlist.
  Future<void> deletePlaylist(int id) async {
    await _db.deletePlaylist(id);
    await loadAll();
  }

  /// Add track to playlist.
  Future<void> addTrackToPlaylist(int playlistId, Track track) async {
    await _db.addTrackToPlaylist(playlistId, track);
    await loadAll();
  }

  /// Remove track from playlist.
  Future<void> removeTrackFromPlaylist(int playlistId, String trackId) async {
    await _db.removeTrackFromPlaylist(playlistId, trackId);
    await loadAll();
  }

  /// Toggle liked / favorite status for a track.
  Future<bool> toggleFavorite(Track track) async {
    final isFav = await _db.toggleFavorite(track);
    final updatedFavorites = await _db.getAllFavorites();
    state = state.copyWith(favorites: updatedFavorites);
    return isFav;
  }

  /// Check if a track is in favorites.
  bool isFavorite(String trackId) {
    return state.favorites.any((t) => t.id == trackId);
  }

  /// Get tracks for a specific playlist.
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    return await _db.getPlaylistTracks(playlistId);
  }

  /// Refresh recently played tracks.
  Future<void> refreshRecentlyPlayed() async {
    final history = await _db.getRecentlyPlayed(limit: 15);
    state = state.copyWith(recentlyPlayed: history);
  }
}

/// Global provider for playlists, favorites, and history state.
final playlistProvider =
    NotifierProvider<PlaylistNotifier, PlaylistState>(PlaylistNotifier.new);
