/// Domain model representing a local audio artist.
class LocalArtist {
  final int id;
  final String artist;
  final int? numberOfAlbums;
  final int? numberOfTracks;

  const LocalArtist({
    required this.id,
    required this.artist,
    this.numberOfAlbums,
    this.numberOfTracks,
  });
}
