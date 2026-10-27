import '../../../domain/models/track.dart';

/// Search results for an individual music source with independent state and error handling.
class SourceSearchResult {
  final List<Track> tracks;
  final bool isLoading;
  final String? error;

  const SourceSearchResult({
    this.tracks = const [],
    this.isLoading = false,
    this.error,
  });

  SourceSearchResult copyWith({
    List<Track>? tracks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SourceSearchResult(
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Unified state for the multi-source Search tab.
class SearchState {
  final String query;
  final bool isDebouncing;
  final bool isSearching;
  final SourceSearchResult localResults;
  final SourceSearchResult ytmResults;
  final SourceSearchResult audiusResults;
  final SourceSearchResult jamendoResults;
  final List<String> recentSearches;

  const SearchState({
    this.query = '',
    this.isDebouncing = false,
    this.isSearching = false,
    this.localResults = const SourceSearchResult(),
    this.ytmResults = const SourceSearchResult(),
    this.audiusResults = const SourceSearchResult(),
    this.jamendoResults = const SourceSearchResult(),
    this.recentSearches = const [],
  });

  /// True if any source is actively loading.
  bool get hasAnyLoading =>
      isDebouncing ||
      isSearching ||
      localResults.isLoading ||
      ytmResults.isLoading ||
      audiusResults.isLoading ||
      jamendoResults.isLoading;

  /// True if there are any results across any source.
  bool get hasAnyResults =>
      localResults.tracks.isNotEmpty ||
      ytmResults.tracks.isNotEmpty ||
      audiusResults.tracks.isNotEmpty ||
      jamendoResults.tracks.isNotEmpty;

  SearchState copyWith({
    String? query,
    bool? isDebouncing,
    bool? isSearching,
    SourceSearchResult? localResults,
    SourceSearchResult? ytmResults,
    SourceSearchResult? audiusResults,
    SourceSearchResult? jamendoResults,
    List<String>? recentSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      isDebouncing: isDebouncing ?? this.isDebouncing,
      isSearching: isSearching ?? this.isSearching,
      localResults: localResults ?? this.localResults,
      ytmResults: ytmResults ?? this.ytmResults,
      audiusResults: audiusResults ?? this.audiusResults,
      jamendoResults: jamendoResults ?? this.jamendoResults,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}
