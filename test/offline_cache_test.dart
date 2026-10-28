import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/core/services/track_cache_service.dart';
import 'package:tugtog/domain/models/track.dart';
import 'package:tugtog/features/library/presentation/downloaded_notifier.dart';
import 'package:tugtog/features/settings/presentation/settings_notifier.dart';

void main() {
  group('TrackCacheService helper tests', () {
    test('formatBytes formats bytes into MB and GB correctly', () {
      expect(TrackCacheService.formatBytes(0), '0 MB');
      expect(TrackCacheService.formatBytes(-50), '0 MB');
      expect(TrackCacheService.formatBytes(1024 * 1024 * 5), '5.0 MB');
      expect(TrackCacheService.formatBytes((1024 * 1024 * 14.5).round()), '14.5 MB');
      expect(TrackCacheService.formatBytes((1024 * 1024 * 1024 * 1.5).round()), '1.50 GB');
    });
  });

  group('SettingsState offline mode tests', () {
    test('SettingsState defaults to autoDownloadCache true and offlineModeOnly false', () {
      const state = SettingsState();
      expect(state.autoDownloadCache, true);
      expect(state.offlineModeOnly, false);
      expect(state.cachedSizeBytes, 0);

      final updated = state.copyWith(
        autoDownloadCache: false,
        offlineModeOnly: true,
        cachedSizeBytes: 52428800,
      );
      expect(updated.autoDownloadCache, false);
      expect(updated.offlineModeOnly, true);
      expect(updated.cachedSizeBytes, 52428800);
    });
  });

  group('DownloadedState tests', () {
    test('DownloadedState copyWith properly updates tracks and size', () {
      const state = DownloadedState();
      expect(state.tracks.isEmpty, true);
      expect(state.isLoading, false);
      expect(state.totalSizeBytes, 0);

      const track = Track(
        id: 'ytm_test123',
        title: 'Kathang Isip',
        artist: 'Ben&Ben',
        sourceType: AudioSourceType.youtubeMusic,
        mediaUri: '/data/user/0/com.tugtog.tugtog/offline_tracks/ytm_test123.m4a',
      );

      final updated = state.copyWith(
        tracks: [track],
        totalSizeBytes: 4500000,
        isLoading: false,
      );

      expect(updated.tracks.length, 1);
      expect(updated.tracks.first.title, 'Kathang Isip');
      expect(updated.totalSizeBytes, 4500000);
    });
  });
}
