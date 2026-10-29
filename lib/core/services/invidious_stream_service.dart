import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service that resolves YouTube audio streams through decentralized, privacy-focused
/// Invidious / Piped proxy endpoints (Spotube / ViMusic architecture).
///
/// Bypasses YouTube's strict bot-detection (PO Token / Proof-of-Origin requirement),
/// Carrier-Grade NAT (CGNAT) mobile drops on Philippine carriers (Globe, Smart, DITO),
/// and HTTP 403 Forbidden errors by routing media delivery through verified nodes.
class InvidiousStreamService {
  static InvidiousStreamService? _instance;
  static InvidiousStreamService get instance =>
      _instance ??= InvidiousStreamService._();

  final Dio _dio;

  /// High-reliability public Invidious instances supporting audio proxying with itag 140 (AAC).
  final List<String> _instances = [
    'https://yt.chocolatemoo53.com',
    'https://inv.tux.pizza',
    'https://invidious.nerdvpn.de',
    'https://invidious.protokolla.fi',
    'https://invidious.private.coffee',
  ];

  InvidiousStreamService._({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
              ),
            );

  /// Resolves a direct, playable audio stream URL for a YouTube [videoId].
  ///
  /// Returns a proxied AAC (itag 140) URL with `&local=true` that streams reliably
  /// into ExoPlayer / just_audio without 403 Forbidden or IP-binding drops.
  Future<String?> getAudioStreamUrl(String videoId) async {
    for (final instance in _instances) {
      final proxyUrl =
          '$instance/latest_version?id=$videoId&itag=140&local=true';
      try {
        final res = await _dio.head(
          proxyUrl,
          options: Options(
            followRedirects: false,
            validateStatus: (status) =>
                status != null && (status >= 200 && status < 400),
          ),
        );

        if (res.statusCode == 200 ||
            res.statusCode == 206 ||
            res.statusCode == 302) {
          debugPrint('InvidiousStreamService: Resolved via $instance');
          return proxyUrl;
        }
      } catch (e) {
        debugPrint('InvidiousStreamService: Instance $instance failed: $e');
      }
    }
    return null;
  }
}
