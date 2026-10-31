import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../../core/utils/song_matcher.dart';
import '../../../domain/models/track.dart';

/// Single line of synchronized lyrics with timestamp offset.
class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });
}

/// Representation of fetched lyrics (supports both synced LRC and plain text).
class LyricsData {
  final String trackTitle;
  final String artistName;
  final String? plainLyrics;
  final List<LyricLine> syncedLyrics;
  final bool isSynced;

  const LyricsData({
    required this.trackTitle,
    required this.artistName,
    this.plainLyrics,
    this.syncedLyrics = const [],
    this.isSynced = false,
  });

  bool get isEmpty =>
      (plainLyrics == null || plainLyrics!.trim().isEmpty) &&
      syncedLyrics.isEmpty;

  bool get isNotEmpty => !isEmpty;
}

/// Service that retrieves synchronized and plain lyrics for any track.
///
/// Multi-tier architecture:
/// 1. LRCLIB API (Free, open-source synced & plain lyrics database)
/// 2. LRCLIB Search fallback (Fuzzy match)
/// 3. YouTube Closed Captions (Subtitles extracted directly from video)
/// 4. In-memory caching for zero latency on repeat views
class LyricsService {
  static LyricsService? _instance;
  static LyricsService get instance => _instance ??= LyricsService._();

  final Dio _dio;
  final Map<String, LyricsData> _cache = {};

  LyricsService._({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://lrclib.net/api',
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
                headers: {
                  'User-Agent': 'Tugtog-Android-Music-Player/1.0.1 (https://github.com/justinot-030807/tugtog)',
                },
              ),
            );

  /// Fetch lyrics for a track, checking LRCLIB first then YouTube closed captions.
  Future<LyricsData?> getLyrics(Track track) async {
    final cacheKey = '${track.id}_${track.title}_${track.artist}'.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final cleanTitle = SongMatcher.normalizeTitle(track.title);
    final cleanArtist = SongMatcher.normalizeArtist(track.artist);

    // 1. Try LRCLIB exact get
    try {
      final response = await _dio.get(
        '/get',
        queryParameters: {
          'track_name': cleanTitle,
          'artist_name': cleanArtist,
          if (track.duration != null && track.duration!.inSeconds > 0)
            'duration': track.duration!.inSeconds,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final lyrics = _parseLrclibResponse(data, track.title, track.artist);
        if (lyrics != null && lyrics.isNotEmpty) {
          _cache[cacheKey] = lyrics;
          return lyrics;
        }
      }
    } catch (_) {
      // Fall through to search endpoint
    }

    // 2. Try LRCLIB search fallback
    try {
      final searchResponse = await _dio.get(
        '/search',
        queryParameters: {
          'q': '$cleanTitle $cleanArtist'.trim(),
        },
      );

      if (searchResponse.statusCode == 200 && searchResponse.data is List) {
        final list = searchResponse.data as List;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final lyrics = _parseLrclibResponse(first, track.title, track.artist);
          if (lyrics != null && lyrics.isNotEmpty) {
            _cache[cacheKey] = lyrics;
            return lyrics;
          }
        }
      }
    } catch (_) {
      // Fall through to YouTube captions
    }

    // 3. Try YouTube Closed Captions if videoId is available
    final videoId = track.extraMetadata['videoId'] as String? ??
        (track.id.startsWith('ytm_') ? track.id.substring(4) : null);

    if (videoId != null && videoId.isNotEmpty) {
      try {
        final ytCaptions = await _fetchYouTubeCaptions(videoId, track);
        if (ytCaptions != null && ytCaptions.isNotEmpty) {
          _cache[cacheKey] = ytCaptions;
          return ytCaptions;
        }
      } catch (e) {
        debugPrint('YouTube caption extraction failed: $e');
      }
    }

    return null;
  }

  LyricsData? _parseLrclibResponse(
    Map<String, dynamic> data,
    String trackTitle,
    String artistName,
  ) {
    final syncedRaw = data['syncedLyrics'] as String?;
    final plainRaw = data['plainLyrics'] as String?;

    if (syncedRaw != null && syncedRaw.trim().isNotEmpty) {
      final parsedLines = parseLrc(syncedRaw);
      if (parsedLines.isNotEmpty) {
        return LyricsData(
          trackTitle: trackTitle,
          artistName: artistName,
          plainLyrics: plainRaw,
          syncedLyrics: parsedLines,
          isSynced: true,
        );
      }
    }

    if (plainRaw != null && plainRaw.trim().isNotEmpty) {
      final plainLines = plainRaw
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => LyricLine(timestamp: Duration.zero, text: l))
          .toList();

      return LyricsData(
        trackTitle: trackTitle,
        artistName: artistName,
        plainLyrics: plainRaw,
        syncedLyrics: plainLines,
        isSynced: false,
      );
    }

    return null;
  }

  /// Parses standard LRC timestamp strings ([mm:ss.xx] Lyric text).
  List<LyricLine> parseLrc(String lrcContent) {
    final lines = <LyricLine>[];
    final regExp = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');

    for (final rawLine in const LineSplitter().convert(lrcContent)) {
      final match = regExp.firstMatch(rawLine.trim());
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final secondsPart = double.tryParse(match.group(2) ?? '0') ?? 0.0;
        final text = (match.group(3) ?? '').trim();

        final totalMilliseconds =
            (minutes * 60 * 1000) + (secondsPart * 1000).round();
        lines.add(
          LyricLine(
            timestamp: Duration(milliseconds: totalMilliseconds),
            text: text,
          ),
        );
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Extracts subtitles from YouTube video captions if available.
  Future<LyricsData?> _fetchYouTubeCaptions(
    String videoId,
    Track track,
  ) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.closedCaptions.getManifest(videoId);
      if (manifest.tracks.isEmpty) return null;

      // Prefer English or Filipino or first available track
      final preferred = manifest.tracks.firstWhere(
        (t) =>
            t.language.code.startsWith('en') ||
            t.language.code.startsWith('tl') ||
            t.language.code.startsWith('fil'),
        orElse: () => manifest.tracks.first,
      );

      final trackCaptions = await yt.videos.closedCaptions.get(preferred);
      if (trackCaptions.captions.isEmpty) return null;

      final syncedLines = trackCaptions.captions
          .map((c) => LyricLine(timestamp: c.offset, text: c.text.trim()))
          .where((c) => c.text.isNotEmpty)
          .toList();

      if (syncedLines.isEmpty) return null;

      final plain = syncedLines.map((l) => l.text).join('\n');
      return LyricsData(
        trackTitle: track.title,
        artistName: track.artist,
        plainLyrics: plain,
        syncedLyrics: syncedLines,
        isSynced: true,
      );
    } catch (_) {
      return null;
    } finally {
      yt.close();
    }
  }
}
