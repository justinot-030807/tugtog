/// Domain model representing a local audio album.
class LocalAlbum {
  final int id;
  final String album;
  final String artist;
  final int numOfSongs;

  const LocalAlbum({
    required this.id,
    required this.album,
    required this.artist,
    required this.numOfSongs,
  });
}
