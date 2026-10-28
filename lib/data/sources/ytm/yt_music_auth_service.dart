import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/track.dart';

/// Helper and authentication service for direct in-app YouTube Music integration.
class YtMusicAuthService {
  static const String cookiesPrefKey = 'yt_music_cookies';
  static const String userEmailPrefKey = 'yt_music_user_email';

  /// Saves the YouTube Music session cookies string.
  static Future<void> saveCookies(String cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cookiesPrefKey, cookies);
  }

  /// Retrieves stored YouTube Music cookies, if any.
  static Future<String?> getCookies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(cookiesPrefKey);
  }

  /// Checks if the user is currently logged in to YouTube Music.
  static Future<bool> isLoggedIn() async {
    final cookies = await getCookies();
    return cookies != null && cookies.contains('SAPISID');
  }

  /// Clears stored YouTube Music session cookies.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cookiesPrefKey);
    await prefs.remove(userEmailPrefKey);
  }

  /// Generates the SAPISIDHASH Authorization header from the SAPISID cookie.
  static String? generateSapisidHash(String cookies, {String origin = 'https://music.youtube.com'}) {
    final sapisidRegex = RegExp(r'(?:^|;\s*)(?:SAPISID|__Secure-3PAPISID)=([^;]+)');
    final match = sapisidRegex.firstMatch(cookies);
    if (match == null) return null;

    final sapisid = match.group(1)!;
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = '$timestamp $sapisid $origin';
    final hash = sha1.convert(utf8.encode(payload)).toString();

    return 'SAPISIDHASH ${timestamp}_$hash';
  }

  /// Fetches listening history directly from YouTube Music using saved cookies.
  static Future<List<Track>> fetchHistoryDirect(String cookies) async {
    final sapisidAuth = generateSapisidHash(cookies);
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
          'Content-Type': 'application/json',
          'Cookie': cookies,
          'x-origin': 'https://music.youtube.com',
          ...?sapisidAuth != null ? {'Authorization': sapisidAuth} : null,
        },
      ),
    );

    try {
      final response = await dio.post(
        'https://music.youtube.com/youtubei/v1/browse',
        data: {
          'context': {
            'client': {
              'clientName': 'WEB_REMIX',
              'clientVersion': '1.20240101.01.00',
              'hl': 'en',
              'gl': 'US',
            },
          },
          'browseId': 'FEmusic_history',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return _parseHistoryResponse(response.data as Map<String, dynamic>);
      }
    } catch (_) {}
    return [];
  }

  /// Parses YouTube Music browse response JSON into unified Track items.
  static List<Track> _parseHistoryResponse(Map<String, dynamic> data) {
    final List<Track> tracks = [];
    try {
      final tabs = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs'] as List?;
      if (tabs == null || tabs.isEmpty) return [];

      final sections = tabs.first['tabRenderer']?['content']?['sectionListRenderer']?['contents'] as List?;
      if (sections == null) return [];

      for (final section in sections) {
        final items = section['musicShelfRenderer']?['contents'] as List?;
        if (items == null) continue;

        for (final item in items) {
          final renderer = item['musicResponsiveListItemRenderer'];
          if (renderer == null) continue;

          final videoId = renderer['playlistItemData']?['videoId'] as String?;
          if (videoId == null || videoId.isEmpty) continue;

          final flexCols = renderer['flexColumns'] as List?;
          String title = 'Unknown Title';
          String artist = 'YouTube Music';

          if (flexCols != null && flexCols.isNotEmpty) {
            final titleRuns = flexCols[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
            if (titleRuns != null && titleRuns.isNotEmpty) {
              title = (titleRuns.first['text'] as String?) ?? title;
            }

            if (flexCols.length > 1) {
              final artistRuns = flexCols[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List?;
              if (artistRuns != null && artistRuns.isNotEmpty) {
                artist = (artistRuns.first['text'] as String?) ?? artist;
              }
            }
          }

          String? artworkUrl;
          final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
          if (thumbnails != null && thumbnails.isNotEmpty) {
            artworkUrl = thumbnails.last['url'] as String?;
          }

          tracks.add(
            Track(
              id: 'ytm_$videoId',
              title: title,
              artist: artist,
              artworkUrl: artworkUrl,
              sourceType: AudioSourceType.youtubeMusic,
              extraMetadata: {
                'videoId': videoId,
                'source': 'yt_music_in_app',
              },
            ),
          );
        }
      }
    } catch (_) {}
    return tracks;
  }
}
