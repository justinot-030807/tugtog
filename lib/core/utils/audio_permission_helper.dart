import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents the permission state for reading device audio files.
enum AudioPermissionState {
  granted,
  denied,
  permanentlyDenied,
}

/// Robust and crash-proof utility for handling Android 13+ (audio) & legacy (storage) permissions.
class AudioPermissionHelper {
  AudioPermissionHelper._();

  /// Check current audio permission status across Android versions safely without crashing.
  static Future<AudioPermissionState> checkPermission() async {
    try {
      // Check audio permission (Android 13+)
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted || audioStatus.isLimited) {
        return AudioPermissionState.granted;
      }

      // Check storage permission (Android 12 and below)
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted || storageStatus.isLimited) {
        return AudioPermissionState.granted;
      }

      if (audioStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
        return AudioPermissionState.permanentlyDenied;
      }

      return AudioPermissionState.denied;
    } catch (e) {
      debugPrint('Safe permission check fallback: $e');
      return AudioPermissionState.denied;
    }
  }

  /// Request audio permissions tailored for Android 13+ & Android 12- with zero crash risk.
  static Future<AudioPermissionState> requestPermission() async {
    try {
      final statuses = await [
        Permission.audio,
        Permission.storage,
      ].request();

      final audioStatus = statuses[Permission.audio];
      final storageStatus = statuses[Permission.storage];

      if ((audioStatus != null && (audioStatus.isGranted || audioStatus.isLimited)) ||
          (storageStatus != null && (storageStatus.isGranted || storageStatus.isLimited))) {
        return AudioPermissionState.granted;
      }

      if ((audioStatus != null && audioStatus.isPermanentlyDenied) ||
          (storageStatus != null && storageStatus.isPermanentlyDenied)) {
        return AudioPermissionState.permanentlyDenied;
      }

      return AudioPermissionState.denied;
    } catch (e) {
      debugPrint('Safe permission request fallback: $e');
      return AudioPermissionState.denied;
    }
  }

  /// Open Android App Settings if permission was permanently denied.
  static Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
