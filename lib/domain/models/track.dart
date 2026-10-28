/// Supported music source types in Tugtog.
enum AudioSourceType {
  local,
  audius,
  jamendo,
  youtubeMusic,
}

/// Core domain entity representing a playable audio track across all sources.
class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final Duration? duration;
  final String? artworkUrl;
  final AudioSourceType sourceType;
  final String? mediaUri; // File path for local, or source reference
  final Map<String, dynamic> extraMetadata;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.artworkUrl,
    required this.sourceType,
    this.mediaUri,
    this.extraMetadata = const {},
  });

  /// Formatted duration string (e.g. "3:45").
  String get formattedDuration {
    if (duration == null) return '--:--';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Serialize Track to a JSON Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration?.inMilliseconds,
      'artworkUrl': artworkUrl,
      'sourceType': sourceType.name,
      'mediaUri': mediaUri,
      'extraMetadata': extraMetadata,
    };
  }

  /// Deserialize Track from a JSON Map.
  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
      artworkUrl: json['artworkUrl'] as String?,
      sourceType: AudioSourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => AudioSourceType.local,
      ),
      mediaUri: json['mediaUri'] as String?,
      extraMetadata: json['extraMetadata'] != null
          ? Map<String, dynamic>.from(json['extraMetadata'] as Map)
          : const {},
    );
  }

  /// Creates a copy of this track with optional modified attributes.
  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? artworkUrl,
    AudioSourceType? sourceType,
    String? mediaUri,
    Map<String, dynamic>? extraMetadata,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      sourceType: sourceType ?? this.sourceType,
      mediaUri: mediaUri ?? this.mediaUri,
      extraMetadata: extraMetadata ?? this.extraMetadata,
    );
  }
}
