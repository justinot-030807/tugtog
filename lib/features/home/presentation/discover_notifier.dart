import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/sources/audius/audius_source.dart';
import '../../../data/sources/jamendo/jamendo_source.dart';
import '../../../domain/models/track.dart';

/// Available genre filters for the Discover section.
class DiscoverGenres {
  static const List<String> list = [
    'Pop',
    'OPM / Filipino',
    'Rock',
    'Chill',
    'Hip-Hop',
    'Electronic',
  ];

  /// Map UI genre label to Jamendo tags
  static String mapToJamendoTag(String genre) {
    switch (genre) {
      case 'Pop':
        return 'pop';
      case 'OPM / Filipino':
        return 'acoustic';
      case 'Rock':
        return 'rock';
      case 'Chill':
        return 'chillout';
      case 'Hip-Hop':
        return 'hiphop';
      case 'Electronic':
        return 'electronic';
      default:
        return 'pop';
    }
  }

  /// Map UI genre label to Audius genres
  static String mapToAudiusGenre(String genre) {
    switch (genre) {
      case 'Pop':
        return 'Pop';
      case 'OPM / Filipino':
        return 'Acoustic';
      case 'Rock':
        return 'Rock';
      case 'Chill':
        return 'Ambient';
      case 'Hip-Hop':
        return 'Hip-Hop/Rap';
      case 'Electronic':
        return 'Electronic';
      default:
        return 'Pop';
    }
  }
}

/// State for the Discover section on Home.
class DiscoverState {
  final List<Track> tracks;
  final String selectedGenre;
  final bool isLoading;
  final String? errorMessage;

  const DiscoverState({
    this.tracks = const [],
    this.selectedGenre = 'Pop',
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

/// Provider for AudiusSource.
final audiusSourceProvider = Provider<AudiusSource>((ref) {
  return AudiusSource();
});

/// Provider for JamendoSource.
final jamendoSourceProvider = Provider<JamendoSource>((ref) {
  return JamendoSource();
});

/// Notifier managing Discover trending tracks and genre selections.
class DiscoverNotifier extends Notifier<DiscoverState> {
  late final AudiusSource _audius;
  late final JamendoSource _jamendo;

  @override
  DiscoverState build() {
    _audius = ref.watch(audiusSourceProvider);
    _jamendo = ref.watch(jamendoSourceProvider);
    Future.microtask(() => fetchDiscoverTracks());
    return const DiscoverState(isLoading: true);
  }

  /// Select a genre and load trending tracks.
  Future<void> selectGenre(String genre) async {
    if (state.selectedGenre == genre && state.tracks.isNotEmpty) return;
    state = state.copyWith(selectedGenre: genre, isLoading: true);
    await fetchDiscoverTracks(genre: genre);
  }

  /// Fetch trending tracks across Audius and Jamendo.
  Future<void> fetchDiscoverTracks({String? genre}) async {
    final activeGenre = genre ?? state.selectedGenre;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final audiusGenre = DiscoverGenres.mapToAudiusGenre(activeGenre);
      final jamendoTag = DiscoverGenres.mapToJamendoTag(activeGenre);

      final audiusFuture = _audius.getTrending(genre: audiusGenre, limit: 12);
      final jamendoFuture = _jamendo.getTrending(genre: jamendoTag, limit: 12);

      final results = await Future.wait([audiusFuture, jamendoFuture]);
      final audiusTracks = results[0];
      final jamendoTracks = results[1];

      // Interleave results from both sources for rich variety
      final combined = <Track>[];
      final maxLen = audiusTracks.length > jamendoTracks.length
          ? audiusTracks.length
          : jamendoTracks.length;

      for (var i = 0; i < maxLen; i++) {
        if (i < audiusTracks.length) combined.add(audiusTracks[i]);
        if (i < jamendoTracks.length) combined.add(jamendoTracks[i]);
      }

      state = state.copyWith(
        isLoading: false,
        tracks: combined,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to discover music: $e',
      );
    }
  }
}

/// Global provider for Discover section state.
final discoverProvider =
    NotifierProvider<DiscoverNotifier, DiscoverState>(DiscoverNotifier.new);
