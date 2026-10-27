import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/audio_permission_helper.dart';
import '../../../data/sources/local/local_music_source.dart';
import '../../../domain/models/local_album.dart';
import '../../../domain/models/local_artist.dart';
import '../../../domain/models/song.dart';

/// State representation for device local music library.
class LocalLibraryState {
  final AudioPermissionState permissionState;
  final bool isLoading;
  final List<Song> songs;
  final List<LocalAlbum> albums;
  final List<LocalArtist> artists;
  final String searchQuery;
  final String? errorMessage;

  const LocalLibraryState({
    this.permissionState = AudioPermissionState.denied,
    this.isLoading = false,
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  LocalLibraryState copyWith({
    AudioPermissionState? permissionState,
    bool? isLoading,
    List<Song>? songs,
    List<LocalAlbum>? albums,
    List<LocalArtist>? artists,
    String? searchQuery,
    String? errorMessage,
  }) {
    return LocalLibraryState(
      permissionState: permissionState ?? this.permissionState,
      isLoading: isLoading ?? this.isLoading,
      songs: songs ?? this.songs,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  /// Filtered songs matching active search query.
  List<Song> get filteredSongs {
    if (searchQuery.trim().isEmpty) return songs;
    final query = searchQuery.toLowerCase();
    return songs.where((s) {
      return s.title.toLowerCase().contains(query) ||
          s.artist.toLowerCase().contains(query) ||
          (s.album?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  /// Filtered albums matching active search query.
  List<LocalAlbum> get filteredAlbums {
    if (searchQuery.trim().isEmpty) return albums;
    final query = searchQuery.toLowerCase();
    return albums.where((a) {
      return a.album.toLowerCase().contains(query) ||
          a.artist.toLowerCase().contains(query);
    }).toList();
  }

  /// Filtered artists matching active search query.
  List<LocalArtist> get filteredArtists {
    if (searchQuery.trim().isEmpty) return artists;
    final query = searchQuery.toLowerCase();
    return artists.where((a) {
      return a.artist.toLowerCase().contains(query);
    }).toList();
  }
}

/// Provider for LocalMusicSource instance.
final localMusicSourceProvider = Provider<LocalMusicSource>((ref) {
  return LocalMusicSource();
});

/// Riverpod Notifier managing the local library lifecycle, permissions, and queries.
class LocalLibraryNotifier extends Notifier<LocalLibraryState> {
  @override
  LocalLibraryState build() {
    // Initial check without blocking UI build
    Future.microtask(() => checkPermissionAndLoad());
    return const LocalLibraryState();
  }

  /// Check permission on startup; if already granted, load content.
  Future<void> checkPermissionAndLoad() async {
    final status = await AudioPermissionHelper.checkPermission();
    state = state.copyWith(permissionState: status);
    if (status == AudioPermissionState.granted) {
      await loadLocalAudioData();
    }
  }

  /// Explicitly request permission and load library data.
  Future<void> requestPermissionAndLoad() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final status = await AudioPermissionHelper.requestPermission();
      state = state.copyWith(permissionState: status);

      if (status == AudioPermissionState.granted) {
        await loadLocalAudioData();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to request audio permission: $e',
      );
    }
  }

  /// Load songs, albums, and artists using LocalMusicSource.
  Future<void> loadLocalAudioData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final source = ref.read(localMusicSourceProvider);
      final songsFuture = source.queryAllSongs();
      final albumsFuture = source.queryAllAlbums();
      final artistsFuture = source.queryAllArtists();

      final results = await Future.wait([songsFuture, albumsFuture, artistsFuture]);

      state = state.copyWith(
        isLoading: false,
        songs: results[0] as List<Song>,
        albums: results[1] as List<LocalAlbum>,
        artists: results[2] as List<LocalArtist>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load local audio files: $e',
      );
    }
  }

  /// Update search filtering query.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Open application system settings.
  Future<void> openSettings() async {
    await AudioPermissionHelper.openSettings();
  }
}

/// Global provider for local library state.
final localLibraryProvider =
    NotifierProvider<LocalLibraryNotifier, LocalLibraryState>(
  LocalLibraryNotifier.new,
);
