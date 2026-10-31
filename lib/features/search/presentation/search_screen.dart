import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/track.dart';
import '../../home/presentation/ytm_history_notifier.dart';
import '../../player/presentation/player_controller.dart';
import 'search_notifier.dart';
import 'search_state.dart';
import 'widgets/recent_searches_view.dart';
import 'widgets/search_group_section.dart';

/// Search tab querying Local storage, YouTube Music, Audius, and Jamendo in parallel with 400ms debounce.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTrackSelected(Track track, int index, List<Track> groupTracks) {
    if (track.sourceType == AudioSourceType.youtubeMusic) {
      // Delegate to stream resolver with full search result queue intact
      ref.read(ytStreamResolverProvider).resolveAndPlay(
            context: context,
            ref: ref,
            track: track,
            queue: groupTracks,
            initialIndex: index,
          );
    } else {
      // Play directly in PlayerController
      ref.read(playerControllerProvider.notifier).playSongList(groupTracks, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);
    final notifier = ref.read(searchNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          // 1. Spotify-style Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: 'What do you want to listen to?',
                  hintStyle: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.black87),
                  suffixIcon: searchState.hasAnyLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black54,
                            ),
                          ),
                        )
                      : (_searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black54),
                              onPressed: () {
                                _searchController.clear();
                                notifier.clearQuery();
                              },
                            )
                          : null),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) => notifier.onQueryChanged(value),
                onSubmitted: (value) => notifier.executeSearch(value),
              ),
            ),
          ),

          // 2. Body: Recent Searches vs Grouped Results
          Expanded(
            child: searchState.query.isEmpty
                ? RecentSearchesView(
                    recentSearches: searchState.recentSearches,
                    onSelectQuery: (selectedQuery) {
                      _searchController.text = selectedQuery;
                      notifier.executeSearch(selectedQuery);
                    },
                    onRemoveQuery: (query) => notifier.removeRecentSearch(query),
                    onClearAll: () => notifier.clearRecentSearches(),
                  )
                : _buildSearchResults(searchState, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchState searchState, SearchNotifier notifier) {
    final hasNoResults = !searchState.hasAnyLoading && !searchState.hasAnyResults;

    if (hasNoResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                'No results found for "${searchState.query}"',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Try searching with different keywords, artist name, or song title.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        // Group 1: Top Songs (Online Catalog - Ad-free)
        SearchGroupSection(
          title: 'Songs',
          icon: Icons.music_note,
          iconColor: AppColors.primary,
          result: searchState.ytmResults,
          onTrackTap: _onTrackSelected,
          onRetry: () => notifier.retrySource('ytm'),
        ),

        // Group 2: On your phone (Local storage)
        SearchGroupSection(
          title: 'On your phone',
          icon: Icons.phone_android,
          iconColor: AppColors.primary,
          result: searchState.localResults,
          onTrackTap: _onTrackSelected,
          onRetry: () => notifier.retrySource('local'),
        ),
      ],
    );
  }
}
