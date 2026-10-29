import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/invidious_stream_service.dart';
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

      // Priority 1: High-Speed Invidious / Piped Audio Proxy (Spotube architecture)
      // Completely eliminates 403 Forbidden, PO-Token botguard, and mobile CGNAT drops
      try {
        final proxiedUrl =
            await InvidiousStreamService.instance.getAudioStreamUrl(videoId);
        if (proxiedUrl != null) {
          final playableTrack = track.copyWith(
            mediaUri: proxiedUrl,
            extraMetadata: {
              ...track.extraMetadata,
              'videoId': videoId,
              'isProxied': true,
            },
          );

          return ResolutionResult.playable(
            track: playableTrack,
            sourceName: 'YouTube High-Speed Stream',
            matchScore: 1.0,
          );
        }
      } catch (e) {
        debugPrint('Invidious resolution failed, falling back to direct: $e');
      }

      // Priority 2: Direct YouTubeExplode manifest extraction
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

    // 3. Resolve stream URL immediately for instant playback (< 1 second)
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
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }

    final result = await resolve(track);

    if (result.type == ResolutionType.playable && result.track != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Play immediately without making user wait for full download!
      await ref.read(playerControllerProvider.notifier).playSongList(
        [result.track!],
        0,
      );

      // 4. Background Auto-Download Cache (Spotify Premium style)
      // Cache quietly in background for zero buffering and zero data on future plays
      if (settings.autoDownloadCache) {
        TrackCacheService.instance.downloadTrack(track).then((_) {
          ref.read(settingsProvider.notifier).refreshCacheSize();
        }).catchError((e) {
          debugPrint('Background cache failed for "${track.title}": $e');
        });
      }
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
