import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugtog/data/sources/audius/audius_source.dart';
import 'package:tugtog/data/sources/jamendo/jamendo_source.dart';
import 'package:tugtog/data/sources/local/local_music_source.dart';
import 'package:tugtog/data/sources/ytm/ytmusic_source.dart';
import 'package:tugtog/domain/models/track.dart';
import 'package:tugtog/features/home/presentation/discover_notifier.dart';
import 'package:tugtog/features/home/presentation/ytm_history_notifier.dart';
import 'package:tugtog/features/library/presentation/local_library_notifier.dart';
import 'package:tugtog/features/search/presentation/search_notifier.dart';
import 'package:tugtog/features/search/presentation/search_state.dart';

// Test doubles for music sources
class FakeTestLocalSource extends LocalMusicSource {
  final List<Track> tracksToReturn;
  final bool shouldThrow;

  FakeTestLocalSource({this.tracksToReturn = const [], this.shouldThrow = false});

  @override
  Future<List<Track>> search(String query) async {
    if (shouldThrow) throw Exception('Local storage read error');
    return tracksToReturn;
  }
}

class FakeTestYtmSource extends YtMusicSource {
  final List<Track> tracksToReturn;
  final bool shouldThrow;

  FakeTestYtmSource({
    this.tracksToReturn = const [],
    this.shouldThrow = false,
  }) : super(baseUrl: 'http://127.0.0.1:8000');

  @override
  Future<List<Track>> search(String query) async {
    if (shouldThrow) throw Exception('YouTube Music backend connection refused');
    return tracksToReturn;
  }
}

class FakeTestAudiusSource extends AudiusSource {
  final List<Track> tracksToReturn;
  final bool shouldThrow;

  FakeTestAudiusSource({this.tracksToReturn = const [], this.shouldThrow = false});

  @override
  Future<List<Track>> search(String query) async {
    if (shouldThrow) throw Exception('Audius API timeout');
    return tracksToReturn;
  }
}

class FakeTestJamendoSource extends JamendoSource {
  final List<Track> tracksToReturn;
  final bool shouldThrow;

  FakeTestJamendoSource({this.tracksToReturn = const [], this.shouldThrow = false});

  @override
  Future<List<Track>> search(String query) async {
    if (shouldThrow) throw Exception('Jamendo server error');
    return tracksToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchState tests', () {
    test('initial state defaults are correct', () {
      const state = SearchState();
      expect(state.query, isEmpty);
      expect(state.isDebouncing, isFalse);
      expect(state.isSearching, isFalse);
      expect(state.hasAnyLoading, isFalse);
      expect(state.hasAnyResults, isFalse);
      expect(state.recentSearches, isEmpty);
    });

    test('hasAnyLoading flags true when debouncing or loading', () {
      const debouncingState = SearchState(isDebouncing: true);
      expect(debouncingState.hasAnyLoading, isTrue);

      const sourceLoadingState = SearchState(
        localResults: SourceSearchResult(isLoading: true),
      );
      expect(sourceLoadingState.hasAnyLoading, isTrue);
    });

    test('hasAnyResults detects results across any source', () {
      const dummyTrack = Track(
        id: '1',
        title: 'Song',
        artist: 'Artist',
        sourceType: AudioSourceType.audius,
      );

      final stateWithResults = const SearchState().copyWith(
        audiusResults: const SourceSearchResult(tracks: [dummyTrack]),
      );
      expect(stateWithResults.hasAnyResults, isTrue);
    });
  });

  group('SearchNotifier parallel search and error isolation tests', () {
    test('parallel search succeeds across all sources and populates groups', () async {
      const localTrack = Track(
        id: 'local_1',
        title: 'Local Song',
        artist: 'Device Artist',
        sourceType: AudioSourceType.local,
      );
      const ytmTrack = Track(
        id: 'ytm_1',
        title: 'YTM Song',
        artist: 'Online Artist',
        sourceType: AudioSourceType.youtubeMusic,
      );
      const audiusTrack = Track(
        id: 'aud_1',
        title: 'Audius Song',
        artist: 'Indie Artist',
        sourceType: AudioSourceType.audius,
      );
      const jamendoTrack = Track(
        id: 'jam_1',
        title: 'Jamendo Song',
        artist: 'CC Artist',
        sourceType: AudioSourceType.jamendo,
      );

      final container = ProviderContainer(
        overrides: [
          localMusicSourceProvider.overrideWithValue(
            FakeTestLocalSource(tracksToReturn: [localTrack]),
          ),
          ytMusicSourceProvider.overrideWithValue(
            FakeTestYtmSource(tracksToReturn: [ytmTrack]),
          ),
          audiusSourceProvider.overrideWithValue(
            FakeTestAudiusSource(tracksToReturn: [audiusTrack]),
          ),
          jamendoSourceProvider.overrideWithValue(
            FakeTestJamendoSource(tracksToReturn: [jamendoTrack]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(searchNotifierProvider.notifier);
      await notifier.executeSearch('Song');

      final state = container.read(searchNotifierProvider);
      expect(state.query, equals('Song'));
      expect(state.isSearching, isFalse);
      expect(state.localResults.tracks.length, equals(1));
      expect(state.ytmResults.tracks.length, equals(1));
      expect(state.audiusResults.tracks.length, equals(1));
      expect(state.jamendoResults.tracks.length, equals(1));
    });

    test('individual source failure does not break other sources (error isolation)', () async {
      const localTrack = Track(
        id: 'local_1',
        title: 'Local Song',
        artist: 'Device Artist',
        sourceType: AudioSourceType.local,
      );
      const jamendoTrack = Track(
        id: 'jam_1',
        title: 'Jamendo Song',
        artist: 'CC Artist',
        sourceType: AudioSourceType.jamendo,
      );

      final container = ProviderContainer(
        overrides: [
          localMusicSourceProvider.overrideWithValue(
            FakeTestLocalSource(tracksToReturn: [localTrack]),
          ),
          // YTM and Audius throw exceptions
          ytMusicSourceProvider.overrideWithValue(
            FakeTestYtmSource(shouldThrow: true),
          ),
          audiusSourceProvider.overrideWithValue(
            FakeTestAudiusSource(shouldThrow: true),
          ),
          jamendoSourceProvider.overrideWithValue(
            FakeTestJamendoSource(tracksToReturn: [jamendoTrack]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(searchNotifierProvider.notifier);
      await notifier.executeSearch('Test');

      final state = container.read(searchNotifierProvider);
      // Local and Jamendo succeeded
      expect(state.localResults.tracks.length, equals(1));
      expect(state.localResults.error, isNull);
      expect(state.jamendoResults.tracks.length, equals(1));
      expect(state.jamendoResults.error, isNull);

      // YTM and Audius isolated their errors without throwing
      expect(state.ytmResults.error, isNotNull);
      expect(state.ytmResults.tracks, isEmpty);
      expect(state.audiusResults.tracks, isEmpty);
    });
  });

  group('SearchNotifier recent searches management tests', () {
    test('adding recent searches deduplicates and keeps newest first', () async {
      final container = ProviderContainer(
        overrides: [
          localMusicSourceProvider.overrideWithValue(FakeTestLocalSource()),
          ytMusicSourceProvider.overrideWithValue(FakeTestYtmSource()),
          audiusSourceProvider.overrideWithValue(FakeTestAudiusSource()),
          jamendoSourceProvider.overrideWithValue(FakeTestJamendoSource()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(searchNotifierProvider.notifier);

      await notifier.addRecentSearch('Taylor Swift');
      await notifier.addRecentSearch('The Weeknd');
      await notifier.addRecentSearch('Taylor Swift'); // Re-search duplicate

      final state = container.read(searchNotifierProvider);
      expect(state.recentSearches.length, equals(2));
      expect(state.recentSearches.first, equals('Taylor Swift'));
      expect(state.recentSearches.last, equals('The Weeknd'));

      // Remove single search
      await notifier.removeRecentSearch('The Weeknd');
      expect(container.read(searchNotifierProvider).recentSearches, equals(['Taylor Swift']));

      // Clear all
      await notifier.clearRecentSearches();
      expect(container.read(searchNotifierProvider).recentSearches, isEmpty);
    });
  });
}
