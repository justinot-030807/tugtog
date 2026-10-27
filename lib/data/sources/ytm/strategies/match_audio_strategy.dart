import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/song_matcher.dart';
import '../../../../domain/models/track.dart';
import '../../../../domain/sources/stream_resolver_strategy.dart';
import '../../../sources/audius/audius_source.dart';
import '../../../sources/jamendo/jamendo_source.dart';
import '../../../../features/player/presentation/player_controller.dart';
import '../../../../features/settings/presentation/settings_screen.dart';

/// Strategy A (Default): Searches Audius and Jamendo for a confident match
/// to enable full background playback, queueing, and notification controls.
class MatchAudioStrategy implements StreamResolverStrategy {
  final AudiusSource audiusSource;
  final JamendoSource jamendoSource;
  final double confidenceThreshold;

  MatchAudioStrategy({
    required this.audiusSource,
    required this.jamendoSource,
    this.confidenceThreshold = 0.75,
  });

  @override
  String get id => 'match_audio';

  @override
  String get displayName => 'Audius & Jamendo Matcher (Default)';

  @override
  String get description =>
      'Searches Audius and Jamendo for a confident match. Enables full background playback, lock screen controls, and playlist queues.';

  @override
  Future<ResolutionResult> resolve(Track track) async {
    final cleanTitle = SongMatcher.normalizeTitle(track.title);
    final cleanArtist = SongMatcher.normalizeArtist(track.artist);
    final searchQuery = '$cleanTitle $cleanArtist'.trim();

    try {
      // 1. Search Audius and Jamendo concurrently
      final audiusFuture = audiusSource.search(searchQuery);
      final jamendoFuture = jamendoSource.search(searchQuery);

      final results = await Future.wait<List<Track>>([
        audiusFuture.catchError((_) => <Track>[]),
        jamendoFuture.catchError((_) => <Track>[]),
      ]);

      final audiusCandidates = results[0];
      final jamendoCandidates = results[1];

      Track? bestTrack;
      String? bestSource;
      double highestScore = 0.0;

      // 2. Score Audius candidates
      for (final candidate in audiusCandidates) {
        final score = SongMatcher.matchConfidence(
          queryTitle: track.title,
          queryArtist: track.artist,
          candidateTitle: candidate.title,
          candidateArtist: candidate.artist,
        );
        if (score >= confidenceThreshold && score > highestScore) {
          highestScore = score;
          bestTrack = candidate;
          bestSource = 'Audius';
        }
      }

      // 3. Score Jamendo candidates
      for (final candidate in jamendoCandidates) {
        final score = SongMatcher.matchConfidence(
          queryTitle: track.title,
          queryArtist: track.artist,
          candidateTitle: candidate.title,
          candidateArtist: candidate.artist,
        );
        if (score >= confidenceThreshold && score > highestScore) {
          highestScore = score;
          bestTrack = candidate;
          bestSource = 'Jamendo';
        }
      }

      // 4. Return match or notFound
      if (bestTrack != null && highestScore >= confidenceThreshold) {
        return ResolutionResult.playable(
          track: bestTrack,
          sourceName: bestSource ?? 'Matched Audio',
          matchScore: highestScore,
        );
      }

      return ResolutionResult.notFound(
        'No confident match found on Audius or Jamendo for "${track.title}".',
      );
    } catch (e) {
      return ResolutionResult.error('Audio matching failed: $e');
    }
  }

  @override
  Future<void> execute({
    required BuildContext context,
    required WidgetRef ref,
    required Track track,
  }) async {
    if (!context.mounted) return;

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
                'Searching Audius & Jamendo for "${track.title}"...',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );

    final result = await resolve(track);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result.type == ResolutionType.playable && result.track != null) {
      ref.read(playerControllerProvider.notifier).playSongList([result.track!], 0);

      final pct = (result.matchScore! * 100).toInt();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playing via ${result.sourceName} ($pct% match): "${result.track!.title}"',
          ),
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'No confident match found on free audio sources.'),
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Settings',
            textColor: AppColors.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ),
      );
    }
  }
}
