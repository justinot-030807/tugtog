import 'package:on_audio_query/on_audio_query.dart';
import '../../../domain/models/local_album.dart';
import '../../../domain/models/local_artist.dart';
import '../../../domain/models/song.dart';
import '../../../domain/models/track.dart';
import '../../../domain/sources/music_source.dart';

/// Concrete MusicSource implementation for device local audio storage.
class LocalMusicSource implements MusicSource {
  final OnAudioQuery _audioQuery;

  LocalMusicSource({OnAudioQuery? audioQuery})
      : _audioQuery = audioQuery ?? OnAudioQuery();

  @override
  String get sourceId => 'local';

  @override
  String get displayName => 'Local Storage';

  /// Query all local audio files from MediaStore via on_audio_query.
  Future<List<Song>> queryAllSongs() async {
    final songModels = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return songModels.map((item) {
      return Song(
        id: item.id,
        title: item.title,
        artist: (item.artist == null || item.artist == '<unknown>')
            ? 'Unknown Artist'
            : item.artist!,
        album: item.album,
        duration: item.duration != null
            ? Duration(milliseconds: item.duration!)
            : null,
        albumId: item.albumId,
        data: item.data,
        displayName: item.displayName,
        size: item.size,
      );
    }).toList();
  }

  /// Query all local music albums.
  Future<List<LocalAlbum>> queryAllAlbums() async {
    final albumModels = await _audioQuery.queryAlbums(
      sortType: AlbumSortType.ALBUM,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return albumModels.map((item) {
      return LocalAlbum(
        id: item.id,
        album: item.album,
        artist: (item.artist == null || item.artist == '<unknown>')
            ? 'Unknown Artist'
            : item.artist!,
        numOfSongs: item.numOfSongs,
      );
    }).toList();
  }

  /// Query all local music artists.
  Future<List<LocalArtist>> queryAllArtists() async {
    final artistModels = await _audioQuery.queryArtists(
      sortType: ArtistSortType.ARTIST,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    return artistModels.map((item) {
      return LocalArtist(
        id: item.id,
        artist: item.artist,
        numberOfAlbums: item.numberOfAlbums,
        numberOfTracks: item.numberOfTracks,
      );
    }).toList();
  }

  @override
  Future<List<Track>> search(String query) async {
    final allSongs = await queryAllSongs();
    final lowerQuery = query.toLowerCase();

    return allSongs
        .where((song) =>
            song.title.toLowerCase().contains(lowerQuery) ||
            song.artist.toLowerCase().contains(lowerQuery) ||
            (song.album?.toLowerCase().contains(lowerQuery) ?? false))
        .map((s) => s.toTrack())
        .toList();
  }

  @override
  Future<List<Track>> getTrending({int page = 1, int limit = 20}) async {
    final allSongs = await queryAllSongs();
    return allSongs.take(limit).map((s) => s.toTrack()).toList();
  }

  @override
  Future<List<Track>> getRecentlyPlayed() async {
    // Return recent local songs (by sort or query order)
    final allSongs = await queryAllSongs();
    return allSongs.take(15).map((s) => s.toTrack()).toList();
  }
}
