import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/track_cache_service.dart';
import '../../../../domain/models/track.dart';
import '../../../../domain/sources/stream_resolver_strategy.dart';
import '../../../../features/player/presentation/player_controller.dart';
import '../../../../features/settings/presentation/settings_notifier.dart';

/// Strategy that resolves YouTube audio tracks directly.
///
/// Integrates Spotify Premium / ViMusic style offline caching to guarantee
/// instant playback without buffering freezes, 403 errors, or mobile network stalls.
class DirectYoutubeStrategy implements StreamResolverStrategy {
  @override
  String get id => 'direct_youtube';

  @override
  String get displayName => 'Direct YouTube Audio (Recommended)';

  @override
  String get description =>
      'Streams high-quality audio directly from YouTube. Supports auto-offline cache, background play, lock screen controls, seek bar, and equalizer.';

  @override
  Future<ResolutionResult> resolve(Track track) async {
    // 1. Fast-path: Check if already downloaded/cached locally
    final cachedPath = await TrackCacheService.instance.getCachedFilePath(track.id);
    if (cachedPath != null) {
      return ResolutionResult.playable(
        track: track.copyWith(
          mediaUri: cachedPath,
          extraMetadata: {
            ...track.extraMetadata,
            'isDownloaded': true,
            'localFilePath': cachedPath,
          },
        ),
        sourceName: 'Offline Download (Local File)',
        matchScore: 1.0,
      );
    }

    String? videoId = track.extraMetadata['videoId'] as String?;
    if (videoId == null || videoId.isEmpty) {
      if (track.id.startsWith('ytm_')) {
        videoId = track.id.substring(4);
      }
    }

    final yt = YoutubeExplode();
    try {
      // If videoId is still absent, perform a quick search with title + artist
      if (videoId == null || videoId.isEmpty) {
        final query = '${track.title} ${track.artist}'.trim();
        final searchResults = await yt.search.search(query);
        if (searchResults.isNotEmpty) {
          videoId = searchResults.first.id.value;
        } else {
          return ResolutionResult.notFound('Could not find YouTube track for "${track.title}".');
        }
      }

      // Fetch audio-only stream manifest
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        return ResolutionResult.notFound('No playable audio streams found for "${track.title}".');
      }

      // Prefer AAC/MP4 container streams for maximum Android ExoPlayer compatibility & instant playback
      final mp4Streams =
          audioStreams.where((s) => s.container.name.toLowerCase() == 'mp4').toList();
      final selectedAudio = mp4Streams.isNotEmpty
          ? mp4Streams.withHighestBitrate()
          : audioStreams.withHighestBitrate();
      final streamUrl = selectedAudio.url.toString();

      final playableTrack = track.copyWith(
        mediaUri: streamUrl,
        extraMetadata: {
          ...track.extraMetadata,
          'videoId': videoId,
          'bitrate': selectedAudio.bitrate.bitsPerSecond,
        },
      );

      return ResolutionResult.playable(
        track: playableTrack,
        sourceName: 'YouTube Online Stream',
        matchScore: 1.0,
      );
    } catch (e) {
      return ResolutionResult.error('Failed to resolve YouTube audio: $e');
    } finally {
      yt.close();
    }
  }

  @override
  Future<void> execute({
    required BuildContext context,
    required WidgetRef ref,
    required Track track,
  }) async {
    // 1. If already cached, play immediately from disk (0ms buffer)
    final cachedPath = await TrackCacheService.instance.getCachedFilePath(track.id);
    if (cachedPath != null) {
      final playable = track.copyWith(
        mediaUri: cachedPath,
        extraMetadata: {
          ...track.extraMetadata,
          'isDownloaded': true,
          'localFilePath': cachedPath,
        },
      );
      await ref.read(playerControllerProvider.notifier).playSongList([playable], 0);
      return;
    }

    final settings = ref.read(settingsProvider);

    // 2. Strict Offline Mode check
    if (settings.offlineModeOnly) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Offline mode is on. "${track.title}" is not downloaded yet.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.amber.shade900,
          ),
        );
      }
      return;
    }

    // 3. Auto-Download Cache Enabled (Spotify Premium style)
    if (settings.autoDownloadCache) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Caching "${track.title}" for offline play...',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: AppColors.surfaceElevated,
          ),
        );
      }

      try {
        final downloadedTrack = await TrackCacheService.instance.downloadTrack(track);
        ref.read(settingsProvider.notifier).refreshCacheSize();

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        // Play instantly from local storage
        await ref.read(playerControllerProvider.notifier).playSongList(
          [downloadedTrack],
          0,
        );
        return;
      } catch (e) {
        debugPrint('Auto-cache failed, falling back to direct stream: $e');
      }
    }

    // 4. Fallback or Auto-cache disabled: Stream directly
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Loading "${track.title}"...',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }

    final result = await resolve(track);

    if (result.type == ResolutionType.playable && result.track != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      await ref.read(playerControllerProvider.notifier).playSongList(
        [result.track!],
        0,
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to stream audio'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
