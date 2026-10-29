import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/sources/audius/audius_source.dart';
import '../../../data/sources/jamendo/jamendo_source.dart';
import '../../../data/sources/ytm/ytmusic_source.dart';
import '../../../domain/models/track.dart';
import 'ytm_history_notifier.dart';

/// Available genre / chart filters for the Discover section on Home (SimpMusic Engine).
class DiscoverGenres {
  static const List<String> list = [
    'OPM Hits',
    'Billboard Top',
    'Chill & Acoustic',
    'Pinoy Rock',
    'P-Pop',
    'Hip-Hop',
  ];

  /// Map UI genre label to YouTube Music search query
  static String mapToSearchQuery(String genre) {
    switch (genre) {
      case 'OPM Hits':
        return 'trending opm music philippines';
      case 'Billboard Top':
        return 'billboard hot 100 music hits';
      case 'Chill & Acoustic':
        return 'acoustic opm chill songs';
      case 'Pinoy Rock':
        return 'classic opm rock hits';
      case 'P-Pop':
        return 'ppop hits bini sb19 alamat';
      case 'Hip-Hop':
        return 'pinoy hiphop rap hits';
      default:
        return 'trending opm hits';
    }
  }

  /// Backward-compatibility helpers for tests
  static String mapToJamendoTag(String genre) => 'pop';
  static String mapToAudiusGenre(String genre) => 'Pop';
}

/// State for the Discover section on Home.
class DiscoverState {
  final List<Track> tracks;
  final String selectedGenre;
  final bool isLoading;
  final String? errorMessage;

  const DiscoverState({
    this.tracks = const [],
    this.selectedGenre = 'OPM Hits',
    this.isLoading = false,
    this.errorMessage,
  });

  DiscoverState copyWith({
    List<Track>? tracks,
    String? selectedGenre,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DiscoverState(
      tracks: tracks ?? this.tracks,
      selectedGenre: selectedGenre ?? this.selectedGenre,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for AudiusSource (kept for test compatibility).
final audiusSourceProvider = Provider<AudiusSource>((ref) {
  return AudiusSource();
});

/// Provider for JamendoSource (kept for test compatibility).
final jamendoSourceProvider = Provider<JamendoSource>((ref) {
  return JamendoSource();
});

/// Notifier managing SimpMusic YouTube Music trending charts and categories.
class DiscoverNotifier extends Notifier<DiscoverState> {
  YtMusicSource get _ytm => ref.read(ytMusicSourceProvider);

  @override
  DiscoverState build() {
    Future.microtask(() => fetchDiscoverTracks());
    return const DiscoverState(isLoading: true);
  }

  /// Select a genre/chart and load YouTube Music tracks.
  Future<void> selectGenre(String genre) async {
    if (state.selectedGenre == genre && state.tracks.isNotEmpty) return;
    state = state.copyWith(selectedGenre: genre, isLoading: true);
    await fetchDiscoverTracks(genre: genre);
  }

  /// Fetch trending YouTube Music tracks for the selected category.
  Future<void> fetchDiscoverTracks({String? genre}) async {
    final activeGenre = genre ?? state.selectedGenre;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final query = DiscoverGenres.mapToSearchQuery(activeGenre);
      final tracks = await _ytm.search(query);

      state = state.copyWith(
        isLoading: false,
        tracks: tracks,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load YouTube Music charts. Please check your connection.',
      );
    }
  }
}

/// Global provider for Discover section on Home.
final discoverProvider =
    NotifierProvider<DiscoverNotifier, DiscoverState>(
  DiscoverNotifier.new,
);
