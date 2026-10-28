import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/track_cache_service.dart';
import '../../../domain/models/track.dart';

/// State representing the offline downloaded songs library.
class DownloadedState {
  final List<Track> tracks;
  final bool isLoading;
  final int totalSizeBytes;

  const DownloadedState({
    this.tracks = const [],
    this.isLoading = false,
    this.totalSizeBytes = 0,
  });

  DownloadedState copyWith({
    List<Track>? tracks,
    bool? isLoading,
    int? totalSizeBytes,
  }) {
    return DownloadedState(
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
    );
  }
}

/// Notifier for managing offline downloaded music.
class DownloadedNotifier extends Notifier<DownloadedState> {
  @override
  DownloadedState build() {
    Future.microtask(() => loadDownloadedTracks());
    return const DownloadedState(isLoading: true);
  }

  /// Reload all offline tracks from disk and database.
  Future<void> loadDownloadedTracks() async {
    state = state.copyWith(isLoading: true);
    try {
      final tracks = await TrackCacheService.instance.getAllDownloadedTracks();
      final totalSize = await TrackCacheService.instance.getTotalCacheSizeBytes();
      state = state.copyWith(
        tracks: tracks,
        totalSizeBytes: totalSize,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Explicitly download a track for offline listening.
  Future<Track?> downloadTrack(
    Track track, {
    void Function(double progress, String status)? onProgress,
  }) async {
    try {
      final downloaded = await TrackCacheService.instance.downloadTrack(
        track,
        onProgress: onProgress,
      );
      await loadDownloadedTracks();
      return downloaded;
    } catch (_) {
      return null;
    }
  }

  /// Delete a single offline track from local storage.
  Future<void> removeTrack(String trackId) async {
    await TrackCacheService.instance.removeTrack(trackId);
    await loadDownloadedTracks();
  }

  /// Delete all offline cached music.
  Future<void> clearAll() async {
    await TrackCacheService.instance.clearAllCache();
    await loadDownloadedTracks();
  }
}

/// Global provider for offline downloaded tracks.
final downloadedProvider =
    NotifierProvider<DownloadedNotifier, DownloadedState>(
  DownloadedNotifier.new,
);
