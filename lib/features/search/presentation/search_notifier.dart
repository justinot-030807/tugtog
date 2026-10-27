import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/sources/audius/audius_source.dart';
import '../../../data/sources/jamendo/jamendo_source.dart';
import '../../../data/sources/local/local_music_source.dart';
import '../../../data/sources/ytm/ytmusic_source.dart';
import '../../home/presentation/discover_notifier.dart';
import '../../home/presentation/ytm_history_notifier.dart';
import '../../library/presentation/local_library_notifier.dart';
import 'search_state.dart';

/// Riverpod Notifier coordinating multi-source parallel music search with 400ms debounce.
class SearchNotifier extends Notifier<SearchState> {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 15;

  Timer? _debounceTimer;
  late final LocalMusicSource _localSource;
  late final YtMusicSource _ytmSource;
  late final AudiusSource _audiusSource;
  late final JamendoSource _jamendoSource;

  @override
  SearchState build() {
    _localSource = ref.watch(localMusicSourceProvider);
    _ytmSource = ref.watch(ytMusicSourceProvider);
    _audiusSource = ref.watch(audiusSourceProvider);
    _jamendoSource = ref.watch(jamendoSourceProvider);

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    Future.microtask(() => loadRecentSearches());
    return const SearchState();
  }

  /// Handles search query input changes with a 400ms debounce.
  void onQueryChanged(String newQuery) {
    _debounceTimer?.cancel();

    if (newQuery.trim().isEmpty) {
      state = state.copyWith(
        query: '',
        isDebouncing: false,
        isSearching: false,
        localResults: const SourceSearchResult(),
        ytmResults: const SourceSearchResult(),
        audiusResults: const SourceSearchResult(),
        jamendoResults: const SourceSearchResult(),
      );
      return;
    }

    state = state.copyWith(
      query: newQuery,
      isDebouncing: true,
    );

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      executeSearch(newQuery.trim());
    });
  }

  /// Clears active search query and returns to recent searches view.
  void clearQuery() {
    _debounceTimer?.cancel();
    state = state.copyWith(
      query: '',
      isDebouncing: false,
      isSearching: false,
      localResults: const SourceSearchResult(),
      ytmResults: const SourceSearchResult(),
      audiusResults: const SourceSearchResult(),
      jamendoResults: const SourceSearchResult(),
    );
  }

  /// Executes parallel search across Local, YouTube Music, Audius, and Jamendo.
  ///
  /// Each source is queried and handled independently so that failure in one source
  /// (e.g. backend server offline) never prevents other sources from rendering.
  Future<void> executeSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    _debounceTimer?.cancel();
    addRecentSearch(query);

    // Set initial loading state for all 4 sources
    state = state.copyWith(
      query: query,
      isDebouncing: false,
      isSearching: true,
      localResults: const SourceSearchResult(isLoading: true),
      ytmResults: const SourceSearchResult(isLoading: true),
      audiusResults: const SourceSearchResult(isLoading: true),
      jamendoResults: const SourceSearchResult(isLoading: true),
    );

    // Run all 4 search queries concurrently with independent error isolation
    await Future.wait([
      _searchLocal(query),
      _searchYtm(query),
      _searchAudius(query),
      _searchJamendo(query),
    ]);

    state = state.copyWith(isSearching: false);
  }

  Future<void> _searchLocal(String query) async {
    try {
      final tracks = await _localSource.search(query);
      state = state.copyWith(
        localResults: SourceSearchResult(tracks: tracks, isLoading: false),
      );
    } catch (e) {
      state = state.copyWith(
        localResults: SourceSearchResult(
          isLoading: false,
          error: 'Local search error: $e',
        ),
      );
    }
  }

  Future<void> _searchYtm(String query) async {
    try {
      final tracks = await _ytmSource.search(query);
      state = state.copyWith(
        ytmResults: SourceSearchResult(tracks: tracks, isLoading: false),
      );
    } catch (e) {
      state = state.copyWith(
        ytmResults: SourceSearchResult(
          isLoading: false,
          error: 'YouTube Music companion offline or unreachable.',
        ),
      );
    }
  }

  Future<void> _searchAudius(String query) async {
    try {
      final tracks = await _audiusSource.search(query);
      state = state.copyWith(
        audiusResults: SourceSearchResult(tracks: tracks, isLoading: false),
      );
    } catch (e) {
      state = state.copyWith(
        audiusResults: SourceSearchResult(
          isLoading: false,
          error: 'Audius search error: $e',
        ),
      );
    }
  }

  Future<void> _searchJamendo(String query) async {
    try {
      final tracks = await _jamendoSource.search(query);
      state = state.copyWith(
        jamendoResults: SourceSearchResult(tracks: tracks, isLoading: false),
      );
    } catch (e) {
      state = state.copyWith(
        jamendoResults: SourceSearchResult(
          isLoading: false,
          error: 'Jamendo search error: $e',
        ),
      );
    }
  }

  /// Retries an individual source search without re-running the others.
  Future<void> retrySource(String sourceId) async {
    final query = state.query.trim();
    if (query.isEmpty) return;

    switch (sourceId) {
      case 'local':
        state = state.copyWith(
          localResults: const SourceSearchResult(isLoading: true),
        );
        await _searchLocal(query);
        break;
      case 'ytm':
        state = state.copyWith(
          ytmResults: const SourceSearchResult(isLoading: true),
        );
        await _searchYtm(query);
        break;
      case 'audius':
        state = state.copyWith(
          audiusResults: const SourceSearchResult(isLoading: true),
        );
        await _searchAudius(query);
        break;
      case 'jamendo':
        state = state.copyWith(
          jamendoResults: const SourceSearchResult(isLoading: true),
        );
        await _searchJamendo(query);
        break;
    }
  }

  // --- Recent Searches Local Persistence ---

  /// Loads recent search history from SharedPreferences.
  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentSearchesKey) ?? [];
      state = state.copyWith(recentSearches: saved);
    } catch (_) {}
  }

  /// Adds a query to recent searches, keeps it deduplicated and capped.
  Future<void> addRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final updated = List<String>.from(state.recentSearches);
    updated.remove(clean);
    updated.insert(0, clean);

    if (updated.length > _maxRecentSearches) {
      updated.removeRange(_maxRecentSearches, updated.length);
    }

    state = state.copyWith(recentSearches: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, updated);
    } catch (_) {}
  }

  /// Removes an individual query from recent searches.
  Future<void> removeRecentSearch(String query) async {
    final updated = List<String>.from(state.recentSearches)..remove(query);
    state = state.copyWith(recentSearches: updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, updated);
    } catch (_) {}
  }

  /// Clears all recent searches.
  Future<void> clearRecentSearches() async {
    state = state.copyWith(recentSearches: const []);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (_) {}
  }
}

/// Global provider for the multi-source Search feature.
final searchNotifierProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
