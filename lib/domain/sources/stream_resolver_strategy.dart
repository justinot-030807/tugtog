import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/track.dart';

/// The outcome type of resolving a track.
enum ResolutionType {
  /// A direct audio stream or match was found that can be played in PlayerController.
  playable,

  /// An interactive WebView YouTube player should be opened.
  webView,

  /// No confident match or source was found.
  notFound,

  /// An error occurred during resolution.
  error,
}

/// Result returned from a [StreamResolverStrategy.resolve] call.
class ResolutionResult {
  final ResolutionType type;
  final Track? track;
  final String? videoId;
  final String? message;
  final String? sourceName;
  final double? matchScore;

  const ResolutionResult({
    required this.type,
    this.track,
    this.videoId,
    this.message,
    this.sourceName,
    this.matchScore,
  });

  /// Factory for a successfully resolved playable track.
  factory ResolutionResult.playable({
    required Track track,
    required String sourceName,
    double? matchScore,
  }) {
    return ResolutionResult(
      type: ResolutionType.playable,
      track: track,
      sourceName: sourceName,
      matchScore: matchScore,
    );
  }

  /// Factory for opening YouTube IFrame player in a WebView.
  factory ResolutionResult.webView({
    required String videoId,
    String? message,
  }) {
    return ResolutionResult(
      type: ResolutionType.webView,
      videoId: videoId,
      message: message,
    );
  }

  /// Factory when no match could be found.
  factory ResolutionResult.notFound(String message) {
    return ResolutionResult(
      type: ResolutionType.notFound,
      message: message,
    );
  }

  /// Factory when resolution encounters an error.
  factory ResolutionResult.error(String message) {
    return ResolutionResult(
      type: ResolutionType.error,
      message: message,
    );
  }
}

/// Abstract strategy contract for resolving YouTube Music or external tracks.
abstract class StreamResolverStrategy {
  /// Unique identifier of this strategy (e.g. 'match_audio', 'iframe_webview').
  String get id;

  /// User-facing label displayed in Settings.
  String get displayName;

  /// Description explaining how this strategy works and its capabilities.
  String get description;

  /// Pure resolution logic without UI dependencies (used for tests and background tasks).
  Future<ResolutionResult> resolve(Track track);

  /// Executes resolution within the current UI context (playback or navigation).
  Future<void> execute({
    required BuildContext context,
    required WidgetRef ref,
    required Track track,
  });
}
