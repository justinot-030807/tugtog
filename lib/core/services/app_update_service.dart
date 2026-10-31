import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Metadata representation of an in-app software update.
class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String apkDownloadUrl;
  final int apkSizeBytes;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    this.apkSizeBytes = 0,
  });
}

/// Service that coordinates in-app OTA software updates directly from GitHub Releases.
///
/// Eliminates the need to manually browse GitHub or download APKs via a web browser.
/// Checks the releases API, streams the downloaded APK with progress feedback,
/// and delegates installation directly to Android's PackageInstaller via FileProvider.
class AppUpdateService {
  static AppUpdateService? _instance;
  static AppUpdateService get instance => _instance ??= AppUpdateService._();

  final Dio _dio;
  static const _updaterChannel = MethodChannel('com.tugtog.tugtog/updater');

  /// Current semantic version of the installed Tugtog client.
  static const String currentAppVersion = '1.0.2';

  /// GitHub repository slug hosting official releases.
  static const String repoOwner = 'justinot-030807';
  static const String repoName = 'tugtog';

  AppUpdateService._({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'Tugtog-Android-Client',
                },
              ),
            );

  /// Checks GitHub Releases API for any newer version than [currentAppVersion].
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final tagName = (data['tag_name'] as String? ?? '').trim();
        final rawVersion = tagName.replaceAll(RegExp(r'^[vV]'), '').trim();
        final releaseTitle = (data['name'] as String? ?? 'Tugtog Update').trim();
        final releaseBody = (data['body'] as String? ?? '').trim();

        final assets = data['assets'] as List<dynamic>? ?? [];
        String? apkUrl;
        int apkSize = 0;

        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            apkSize = (asset['size'] as num?)?.toInt() ?? 0;
            break;
          }
        }

        // Fallback to release download URL if asset not found in payload
        apkUrl ??=
            'https://github.com/$repoOwner/$repoName/releases/download/$tagName/app-release.apk';

        final isNewer = _compareVersions(rawVersion, currentAppVersion) > 0;

        return AppUpdateInfo(
          hasUpdate: isNewer,
          currentVersion: currentAppVersion,
          latestVersion: rawVersion.isNotEmpty ? rawVersion : tagName,
          releaseTitle: releaseTitle,
          releaseNotes: releaseBody.isNotEmpty
              ? releaseBody
              : 'Bug fixes, performance improvements, and music playback optimizations.',
          apkDownloadUrl: apkUrl,
          apkSizeBytes: apkSize,
        );
      }
    } catch (e) {
      debugPrint('AppUpdateService: Error checking for update: $e');
    }
    return null;
  }

  /// Downloads the release APK with progress tracking and opens Android Package Installer.
  Future<bool> downloadAndInstallUpdate({
    required String downloadUrl,
    required void Function(double progress, int receivedBytes, int totalBytes)
        onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/tugtog_update.apk');

      // If older update file exists, clean it up
      if (await targetFile.exists()) {
        await targetFile.delete().catchError((_) => targetFile);
      }

      final cancelToken = CancelToken();

      await _dio.download(
        downloadUrl,
        targetFile.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            onProgress(progress, received, total);
          } else {
            onProgress(0.5, received, total);
          }
        },
      );

      if (await targetFile.exists() && await targetFile.length() > 1024 * 1024) {
        // Trigger native PackageInstaller via FileProvider
        final success = await _updaterChannel.invokeMethod<bool>(
          'installApk',
          {'filePath': targetFile.path},
        );
        return success ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('AppUpdateService: Download / Install failed: $e');
      return false;
    }
  }

  /// Compares semantic versions (e.g. "1.0.1" vs "1.0.0").
  /// Returns > 0 if v1 > v2, < 0 if v1 < v2, and 0 if equal.
  int _compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (var i = 0; i < maxLen; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }
    return 0;
  }
}
