import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/track.dart';
import '../../../../domain/sources/stream_resolver_strategy.dart';
import '../../../../features/player/presentation/player_controller.dart';

/// Strategy that resolves YouTube audio streams directly using YoutubeExplode.
///
/// Enables seamless background playback, lock screen controls, seek bar, and
/// offline queueing for any YouTube/YouTube Music track without requiring a local backend.
class DirectYoutubeStrategy implements StreamResolverStrategy {
  @override
  String get id => 'direct_youtube';

  @override
  String get displayName => 'Direct YouTube Audio (Recommended)';

  @override
  String get description =>
      'Streams high-quality audio directly from YouTube. Supports background play, lock screen controls, seek bar, and equalizer.';

  @override
  Future<ResolutionResult> resolve(Track track) async {
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
