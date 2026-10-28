import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../data/db/app_database.dart';
import '../../domain/models/track.dart';

/// Service responsible for downloading, caching, and serving offline audio tracks
/// (Spotify Premium / ViMusic style).
///
/// Bypasses mobile network throttling and eliminates 403 / buffering stalls by saving
/// audio locally to device storage and playing directly via AudioSource.file.
class TrackCacheService {
  static TrackCacheService? _instance;
  static TrackCacheService get instance => _instance ??= TrackCacheService._();

  final Dio _dio;

  TrackCacheService._({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
              ),
            );

  /// Directory where offline tracks are stored.
  Future<Directory> getOfflineDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/offline_tracks');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Sanitized local file path for a track.
  Future<String> getTrackFilePath(String trackId) async {
    final dir = await getOfflineDirectory();
    final sanitizedId = trackId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return '${dir.path}/$sanitizedId.m4a';
  }

  /// Check whether a track is already cached locally on disk.
  Future<String?> getCachedFilePath(String trackId) async {
    try {
      final filePath = await getTrackFilePath(trackId);
      final file = File(filePath);
      if (await file.exists()) {
        final length = await file.length();
        // A valid music file is at least 100 KB
        if (length > 100 * 1024) {
          return filePath;
        } else {
          // Incomplete or corrupted file: clean up
          await file.delete().catchError((_) => file);
        }
      }
    } catch (e) {
      debugPrint('Error checking cached file path for $trackId: $e');
    }
    return null;
  }

  /// Returns true if the track is fully downloaded and available offline.
  Future<bool> isCached(String trackId) async {
    final path = await getCachedFilePath(trackId);
    return path != null;
  }

  /// Download and cache an audio track to local storage for offline playback.
  ///
  /// Uses chunked HTTP Range requests to maximize download speed and prevent
  /// CDN throttling from YouTube / googlevideo.
  Future<Track> downloadTrack(
    Track track, {
    void Function(double progress, String status)? onProgress,
  }) async {
    // 1. If already cached, return immediately
    final existingPath = await getCachedFilePath(track.id);
    if (existingPath != null) {
      final updated = track.copyWith(mediaUri: existingPath);
      return updated;
    }

    final finalPath = await getTrackFilePath(track.id);
    final partFile = File('$finalPath.part');
    if (await partFile.exists()) {
      await partFile.delete().catchError((_) => partFile);
    }

    String? directAudioUrl;
    int? totalBytes;

    // 2. Resolve download URL
    final isYouTube = track.sourceType == AudioSourceType.youtubeMusic ||
        track.id.startsWith('ytm_') ||
        track.extraMetadata['videoId'] != null;

    if (isYouTube) {
      String? videoId = track.extraMetadata['videoId'] as String?;
      if (videoId == null || videoId.isEmpty) {
        if (track.id.startsWith('ytm_')) {
          videoId = track.id.substring(4);
        }
      }

      final yt = YoutubeExplode();
      try {
        if (videoId == null || videoId.isEmpty) {
          final query = '${track.title} ${track.artist}'.trim();
          final results = await yt.search.search(query);
          if (results.isNotEmpty) {
            videoId = results.first.id.value;
          } else {
            throw Exception('Could not find YouTube track for "${track.title}"');
          }
        }

        final manifest = await yt.videos.streamsClient.getManifest(videoId);
        final audioStreams = manifest.audioOnly;
        if (audioStreams.isEmpty) {
          throw Exception('No playable audio streams found for "${track.title}"');
        }

        final mp4Streams = audioStreams
            .where((s) => s.container.name.toLowerCase() == 'mp4')
            .toList();
        final selectedStream = mp4Streams.isNotEmpty
            ? mp4Streams.withHighestBitrate()
            : audioStreams.withHighestBitrate();

        directAudioUrl = selectedStream.url.toString();
        totalBytes = selectedStream.size.totalBytes;
      } finally {
        yt.close();
      }
    } else if (track.mediaUri != null && track.mediaUri!.startsWith('http')) {
      directAudioUrl = track.mediaUri;
    }

    if (directAudioUrl == null || directAudioUrl.isEmpty) {
      throw Exception('Cannot download track without remote audio URL');
    }
    final targetUrl = directAudioUrl;

    // 3. Download audio file in fast 512KB range chunks
    const chunkSize = 512 * 1024;
    var start = 0;
    var downloadedBytes = 0;
    final sink = partFile.openWrite();

    try {
      if (totalBytes != null && totalBytes > 0) {
        while (start < totalBytes) {
          final end = (start + chunkSize - 1) < totalBytes
              ? (start + chunkSize - 1)
              : (totalBytes - 1);

          final response = await _dio.get<List<int>>(
            targetUrl,
            options: Options(
              headers: {
                'Range': 'bytes=$start-$end',
              },
              responseType: ResponseType.bytes,
            ),
          );

          if (response.statusCode == 206 || response.statusCode == 200) {
            final data = response.data!;
            sink.add(data);
            downloadedBytes += data.length;
            final ratio = (downloadedBytes / totalBytes).clamp(0.0, 1.0);
            onProgress?.call(
              ratio,
              '${(ratio * 100).toStringAsFixed(0)}% (${(downloadedBytes / 1024 / 1024).toStringAsFixed(1)} MB)',
            );
          } else {
            throw Exception('Chunk failed with status ${response.statusCode}');
          }

          start = end + 1;
        }
      } else {
        // Fallback: standard streaming download
        await _dio.download(
          targetUrl,
          partFile.path,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final ratio = (received / total).clamp(0.0, 1.0);
              onProgress?.call(ratio, '${(ratio * 100).toStringAsFixed(0)}%');
            }
          },
        );
        downloadedBytes = await partFile.length();
      }

      await sink.flush();
      await sink.close();

      // 4. Atomically rename to final file path
      final finalFile = File(finalPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partFile.rename(finalPath);

      final totalSize = await finalFile.length();
      final updatedTrack = track.copyWith(
        mediaUri: finalPath,
        extraMetadata: {
          ...track.extraMetadata,
          'isDownloaded': true,
          'fileSize': totalSize,
          'localFilePath': finalPath,
        },
      );

      // 5. Persist record to SQLite
      await AppDatabase.instance.saveDownloadedTrack(
        track: updatedTrack,
        filePath: finalPath,
        fileSize: totalSize,
      );

      return updatedTrack;
    } catch (e) {
      await sink.close().catchError((_) {});
      if (await partFile.exists()) {
        await partFile.delete().catchError((_) => partFile);
      }
      rethrow;
    }
  }

  /// Remove a downloaded track from disk and database.
  Future<void> removeTrack(String trackId) async {
    try {
      final filePath = await getTrackFilePath(trackId);
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    await AppDatabase.instance.removeDownloadedTrack(trackId);
  }

  /// Clear all downloaded offline tracks from disk and SQLite.
  Future<void> clearAllCache() async {
    try {
      final dir = await getOfflineDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete().catchError((_) => entity);
          }
        }
      }
    } catch (_) {}
    await AppDatabase.instance.clearAllDownloadedTracks();
  }

  /// Retrieve all downloaded tracks available for offline listening.
  Future<List<Track>> getAllDownloadedTracks() async {
    final dbTracks = await AppDatabase.instance.getDownloadedTracks();
    final List<Track> verifiedTracks = [];

    for (final track in dbTracks) {
      if (track.mediaUri != null && await File(track.mediaUri!).exists()) {
        verifiedTracks.add(track);
      } else {
        // Remove stale DB record if file is gone
        await AppDatabase.instance.removeDownloadedTrack(track.id);
      }
    }

    return verifiedTracks;
  }

  /// Calculate total size of all offline cached tracks in bytes.
  Future<int> getTotalCacheSizeBytes() async {
    var total = 0;
    try {
      final dir = await getOfflineDirectory();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      }
    } catch (_) {}
    return total;
  }

  /// Format byte count into human-readable string (e.g. "14.2 MB").
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb < 1024) {
      return '${mb.toStringAsFixed(1)} MB';
    }
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }
}
