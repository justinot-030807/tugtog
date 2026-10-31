import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/models/track.dart';
import '../../../../domain/sources/stream_resolver_strategy.dart';
import '../../../../features/player/presentation/player_controller.dart';
import '../../../../features/player/presentation/youtube_player_screen.dart';

/// Strategy B: Opens the track in an in-app WebView using the official YouTube IFrame Player.
/// Operates foreground-only per YouTube terms.
class YouTubeIFrameStrategy implements StreamResolverStrategy {
  @override
  String get id => 'iframe_webview';

  @override
  String get displayName => 'In-App YouTube IFrame Player';

  @override
  String get description =>
      'Streams the video directly using the official YouTube IFrame Player in a WebView. Foreground only (background playback not available).';

  @override
  Future<ResolutionResult> resolve(Track track) async {
    // Extract videoId from metadata, id or mediaUri
    String? videoId = track.extraMetadata['videoId'] as String?;
    if (videoId == null || videoId.isEmpty) {
      if (track.id.startsWith('ytm_')) {
        videoId = track.id.replaceFirst('ytm_', '');
      } else {
        videoId = track.id;
      }
    }

    if (videoId.isEmpty) {
      return ResolutionResult.error('No YouTube video ID found for "${track.title}".');
    }

    return ResolutionResult.webView(
      videoId: videoId,
      message: 'Opening in YouTube IFrame Player (Foreground Only)',
    );
  }

  @override
  Future<void> execute({
    required BuildContext context,
    required WidgetRef ref,
    required Track track,
    List<Track>? queue,
    int initialIndex = 0,
  }) async {
    final result = await resolve(track);

    if (!context.mounted) return;

    if (result.type == ResolutionType.webView && result.videoId != null) {
      // Pause background music player so audio does not overlap
      ref.read(playerControllerProvider.notifier).pause();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => YouTubePlayerScreen(
            videoId: result.videoId!,
            track: track,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Failed to open YouTube player.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }
}
