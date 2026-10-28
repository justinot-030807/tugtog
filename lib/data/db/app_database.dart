import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/models/playlist.dart';
import '../../domain/models/track.dart';

/// Representation of a persisted playback state session across restarts.
class SavedPlaybackSession {
  final List<Track> queue;
  final int currentIndex;
  final Duration position;

  const SavedPlaybackSession({
    required this.queue,
    required this.currentIndex,
    required this.position,
  });
}

/// SQLite Database Manager for playlists, liked songs, history, and state persistence.
class AppDatabase {
  static const String _dbName = 'tugtog.db';
  static const int _dbVersion = 1;

  static AppDatabase? _instance;
  Database? _db;

  AppDatabase._();

  static AppDatabase get instance => _instance ??= AppDatabase._();

  /// Retrieve active database instance, initializing if necessary.
  /// Returns null safely in headless test environments where native SQLite is absent.
  Future<Database?> get database async {
    if (_db != null) return _db;
    try {
      _db = await _initDatabase();
      return _db;
    } catch (_) {
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // 1. Playlists table
        await db.execute('''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        // 2. Playlist items table
        await db.execute('''
          CREATE TABLE playlist_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            playlist_id INTEGER NOT NULL,
            track_id TEXT NOT NULL,
            track_json TEXT NOT NULL,
            position INTEGER NOT NULL,
            added_at INTEGER NOT NULL,
            FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
          )
        ''');

        // 3. Favorites / Liked Songs table
        await db.execute('''
          CREATE TABLE favorites (
            track_id TEXT PRIMARY KEY,
            track_json TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        // 4. Play history table
        await db.execute('''
          CREATE TABLE play_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            track_id TEXT NOT NULL,
            track_json TEXT NOT NULL,
            played_at INTEGER NOT NULL
          )
        ''');

        // 5. Playback session table for persistence
        await db.execute('''
          CREATE TABLE playback_session (
            id INTEGER PRIMARY KEY,
            queue_json TEXT NOT NULL,
            current_index INTEGER NOT NULL,
            position_ms INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

        // 6. Downloaded & Cached Offline Tracks (Spotify Premium style)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS downloaded_tracks (
            track_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            track_json TEXT NOT NULL,
            downloaded_at INTEGER NOT NULL
          )
        ''');
      },
      onOpen: (db) async {
        // Ensure downloaded_tracks table exists for legacy DB instances
        await db.execute('''
          CREATE TABLE IF NOT EXISTS downloaded_tracks (
            track_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL,
            file_size INTEGER NOT NULL,
            track_json TEXT NOT NULL,
            downloaded_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ==========================================
  // PLAYLISTS OPERATIONS
  // ==========================================

  /// Create a new playlist and return its generated ID.
  Future<int> createPlaylist(String name) async {
    final db = await database;
    if (db == null) return -1;
    return await db.insert('playlists', {
      'name': name.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Rename an existing playlist.
  Future<void> renamePlaylist(int id, String newName) async {
    final db = await database;
    if (db == null) return;
    await db.update(
      'playlists',
      {'name': newName.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a playlist and its associated items.
  Future<void> deletePlaylist(int id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  /// Retrieve all playlists with track counts.
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    if (db == null) return [];
    final results = await db.rawQuery('''
      SELECT p.id, p.name, p.created_at, COUNT(pi.id) as track_count
      FROM playlists p
      LEFT JOIN playlist_items pi ON p.id = pi.playlist_id
      GROUP BY p.id
      ORDER BY p.created_at DESC
    ''');

    return results.map((row) {
      return Playlist(
        id: row['id'] as int,
        name: row['name'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        trackCount: (row['track_count'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Add a track to a playlist.
  Future<void> addTrackToPlaylist(int playlistId, Track track) async {
    final db = await database;
    if (db == null) return;
    final maxPosResult = await db.rawQuery(
      'SELECT MAX(position) as max_pos FROM playlist_items WHERE playlist_id = ?',
      [playlistId],
    );
    final currentMax = (maxPosResult.first['max_pos'] as int?) ?? -1;

    await db.insert('playlist_items', {
      'playlist_id': playlistId,
      'track_id': track.id,
      'track_json': jsonEncode(track.toJson()),
      'position': currentMax + 1,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Remove a track from a playlist.
  Future<void> removeTrackFromPlaylist(int playlistId, String trackId) async {
    final db = await database;
    if (db == null) return;
    await db.delete(
      'playlist_items',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }

  /// Retrieve all tracks for a specific playlist ordered by position.
  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    final db = await database;
    if (db == null) return [];
    final results = await db.query(
      'playlist_items',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );

    return results.map((row) {
      final jsonMap =
          jsonDecode(row['track_json'] as String) as Map<String, dynamic>;
      return Track.fromJson(jsonMap);
    }).toList();
  }

  // ==========================================
  // FAVORITES ("LIKED SONGS") OPERATIONS
  // ==========================================

  /// Check whether a track is currently favorited.
  Future<bool> isFavorite(String trackId) async {
    final db = await database;
    if (db == null) return false;
    final results = await db.query(
      'favorites',
      where: 'track_id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Add track to favorites.
  Future<void> addFavorite(Track track) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'favorites',
      {
        'track_id': track.id,
        'track_json': jsonEncode(track.toJson()),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove track from favorites.
  Future<void> removeFavorite(String trackId) async {
    final db = await database;
    if (db == null) return;
    await db.delete(
      'favorites',
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
  }

  /// Toggle favorite status of a track and return the new status.
  Future<bool> toggleFavorite(Track track) async {
    final favorited = await isFavorite(track.id);
    if (favorited) {
      await removeFavorite(track.id);
      return false;
    } else {
      await addFavorite(track);
      return true;
    }
  }

  /// Get all favorited / Liked songs.
  Future<List<Track>> getAllFavorites() async {
    final db = await database;
    if (db == null) return [];
    final results = await db.query(
      'favorites',
      orderBy: 'created_at DESC',
    );

    return results.map((row) {
      final jsonMap =
          jsonDecode(row['track_json'] as String) as Map<String, dynamic>;
      return Track.fromJson(jsonMap);
    }).toList();
  }

  // ==========================================
  // PLAY HISTORY OPERATIONS
  // ==========================================

  /// Log every played track to play history.
  Future<void> logPlayHistory(Track track) async {
    final db = await database;
    if (db == null) return;
    await db.insert('play_history', {
      'track_id': track.id,
      'track_json': jsonEncode(track.toJson()),
      'played_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get recently played tracks (deduplicated by track_id, keeping most recent).
  Future<List<Track>> getRecentlyPlayed({int limit = 20}) async {
    final db = await database;
    if (db == null) return [];
    final results = await db.rawQuery('''
      SELECT ph.track_json, MAX(ph.played_at) as latest_played
      FROM play_history ph
      GROUP BY ph.track_id
      ORDER BY latest_played DESC
      LIMIT ?
    ''', [limit]);

    return results.map((row) {
      final jsonMap =
          jsonDecode(row['track_json'] as String) as Map<String, dynamic>;
      return Track.fromJson(jsonMap);
    }).toList();
  }

  /// Clear all play history.
  Future<void> clearPlayHistory() async {
    final db = await database;
    if (db == null) return;
    await db.delete('play_history');
  }

  // ==========================================
  // PLAYBACK SESSION PERSISTENCE
  // ==========================================

  /// Persist the last active queue, track index, and position.
  Future<void> savePlaybackSession({
    required List<Track> queue,
    required int currentIndex,
    required Duration position,
  }) async {
    if (queue.isEmpty) return;
    final db = await database;
    if (db == null) return;
    final queueListJson = queue.map((t) => t.toJson()).toList();

    await db.insert(
      'playback_session',
      {
        'id': 1,
        'queue_json': jsonEncode(queueListJson),
        'current_index': currentIndex,
        'position_ms': position.inMilliseconds,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve the last saved playback session.
  Future<SavedPlaybackSession?> getPlaybackSession() async {
    try {
      final db = await database;
      if (db == null) return null;
      final results = await db.query(
        'playback_session',
        where: 'id = 1',
        limit: 1,
      );

      if (results.isEmpty) return null;

      final row = results.first;
      final rawQueue = jsonDecode(row['queue_json'] as String) as List;
      final queue = rawQueue
          .map((item) => Track.fromJson(item as Map<String, dynamic>))
          .toList();

      return SavedPlaybackSession(
        queue: queue,
        currentIndex: row['current_index'] as int,
        position: Duration(milliseconds: row['position_ms'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // DOWNLOADED & CACHED OFFLINE TRACKS (SPOTIFY PREMIUM STYLE)
  // ==========================================

  /// Save or update a downloaded track record in SQLite.
  Future<void> saveDownloadedTrack({
    required Track track,
    required String filePath,
    required int fileSize,
  }) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'downloaded_tracks',
      {
        'track_id': track.id,
        'file_path': filePath,
        'file_size': fileSize,
        'track_json': jsonEncode(track.toJson()),
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve all downloaded/cached offline tracks sorted by download date.
  Future<List<Track>> getDownloadedTracks() async {
    final db = await database;
    if (db == null) return [];
    final results = await db.query(
      'downloaded_tracks',
      orderBy: 'downloaded_at DESC',
    );

    return results.map((row) {
      final jsonMap =
          jsonDecode(row['track_json'] as String) as Map<String, dynamic>;
      final track = Track.fromJson(jsonMap);
      return track.copyWith(mediaUri: row['file_path'] as String?);
    }).toList();
  }

  /// Check whether a track is recorded as downloaded.
  Future<bool> isTrackDownloaded(String trackId) async {
    final db = await database;
    if (db == null) return false;
    final results = await db.query(
      'downloaded_tracks',
      columns: ['track_id'],
      where: 'track_id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Get the local file path of a downloaded track.
  Future<String?> getDownloadedTrackPath(String trackId) async {
    final db = await database;
    if (db == null) return null;
    final results = await db.query(
      'downloaded_tracks',
      columns: ['file_path'],
      where: 'track_id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['file_path'] as String?;
  }

  /// Remove a track from downloaded records.
  Future<void> removeDownloadedTrack(String trackId) async {
    final db = await database;
    if (db == null) return;
    await db.delete(
      'downloaded_tracks',
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
  }

  /// Clear all downloaded track records.
  Future<void> clearAllDownloadedTracks() async {
    final db = await database;
    if (db == null) return;
    await db.delete('downloaded_tracks');
  }

  /// Calculate total file size of all downloaded songs in bytes.
  Future<int> getTotalDownloadedSize() async {
    final db = await database;
    if (db == null) return 0;
    final results = await db.rawQuery(
      'SELECT SUM(file_size) as total_size FROM downloaded_tracks',
    );
    if (results.isEmpty) return 0;
    return (results.first['total_size'] as int?) ?? 0;
  }
}
