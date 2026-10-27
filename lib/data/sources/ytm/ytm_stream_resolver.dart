import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/track.dart';
import '../../../domain/sources/stream_resolver.dart';
import '../../../domain/sources/stream_resolver_strategy.dart';

/// Stream resolver for YouTube Music tracks using the Strategy Pattern.
///
/// Easily extensible: new strategies (e.g. Invidious, Piped, Local Downloader) can be
/// registered without modifying any UI or player consumption code.
class YtStreamResolver implements StreamResolver {
  final Map<String, StreamResolverStrategy> _strategies = {};
  String activeStrategyId;

  YtStreamResolver({
    List<StreamResolverStrategy> initialStrategies = const [],
    this.activeStrategyId = 'match_audio',
  }) {
    for (final strategy in initialStrategies) {
      registerStrategy(strategy);
    }
  }

  @override
  String get sourceId => 'youtubeMusic';

  /// Registers a new resolution strategy into the resolver registry.
  void registerStrategy(StreamResolverStrategy strategy) {
    _strategies[strategy.id] = strategy;
  }

  /// Returns all currently registered strategies.
  List<StreamResolverStrategy> get availableStrategies =>
      _strategies.values.toList();

  /// Retrieves the currently active strategy, or null if no strategies are registered.
  StreamResolverStrategy? get activeStrategy {
    return _strategies[activeStrategyId] ??
        (_strategies.isNotEmpty ? _strategies.values.first : null);
  }

  @override
  Future<String> resolveStreamUrl(Track track) async {
    final strategy = activeStrategy;
    if (strategy == null) {
      return 'No resolution strategy configured';
    }
    final result = await strategy.resolve(track);
    if (result.type == ResolutionType.playable && result.track?.mediaUri != null) {
      return result.track!.mediaUri!;
    }
    return result.message ?? 'Playback not resolved';
  }

  /// Executes resolution for the given track using the active strategy in UI context.
  Future<void> resolveAndPlay({
    required BuildContext context,
    required WidgetRef ref,
    required Track track,
  }) async {
    final strategy = activeStrategy;
    if (strategy == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No resolution strategy configured.')),
        );
      }
      return;
    }
    await strategy.execute(
      context: context,
      ref: ref,
      track: track,
    );
  }
}
