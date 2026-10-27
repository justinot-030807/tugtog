import 'track.dart';

/// Domain entity representing a playable audio song (local file or remote stream).
class Song {
  final int id;
  final String title;
  final String artist;
  final String? album;
  final Duration? duration;
  final int? albumId;
  final String data; // File path on device or HTTP streaming URL
  final String? artworkUrl;
  final AudioSourceType sourceType;
  final String? displayName;
  final int? size;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.albumId,
    required this.data,
    this.artworkUrl,
    this.sourceType = AudioSourceType.local,
    this.displayName,
    this.size,
  });

  /// Convert to generic unified domain Track entity.
  Track toTrack() {
    return Track(
      id: '${sourceType.name}_$id',
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artworkUrl: artworkUrl,
      sourceType: sourceType,
      mediaUri: data,
      extraMetadata: {
        'songId': id,
        'albumId': albumId,
        'size': size,
      },
    );
  }

  /// Create a Song instance from a Track.
  factory Song.fromTrack(Track track, {int? songId}) {
    final parsedId = songId ?? int.tryParse(track.id.replaceAll(RegExp(r'^[a-zA-Z]+_'), '')) ?? track.hashCode;
    return Song(
      id: parsedId,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: track.duration,
      data: track.mediaUri ?? '',
      artworkUrl: track.artworkUrl,
      sourceType: track.sourceType,
    );
  }

  /// Formatted duration (e.g., 3:45).
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
