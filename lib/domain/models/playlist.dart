/// Domain entity representing a user music playlist.
class Playlist {
  final int id;
  final String name;
  final DateTime createdAt;
  final int trackCount;

  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.trackCount = 0,
  });

  Playlist copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    int? trackCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      trackCount: trackCount ?? this.trackCount,
    );
  }
}
