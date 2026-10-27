import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents the permission state for reading device audio files.
enum AudioPermissionState {
  granted,
  denied,
  permanentlyDenied,
}

/// Helper utility for handling Android 13+ and legacy storage permissions.
class AudioPermissionHelper {
  AudioPermissionHelper._();

  static final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Check current audio permission status across Android versions.
  static Future<AudioPermissionState> checkPermission() async {
    // Check through on_audio_query's internal version-aware status check
    final hasAudioQueryPermission = await _audioQuery.permissionsStatus();
    if (hasAudioQueryPermission) {
      return AudioPermissionState.granted;
    }

    // Double check with permission_handler
    final audioStatus = await Permission.audio.status;
    final storageStatus = await Permission.storage.status;

    if (audioStatus.isGranted || storageStatus.isGranted) {
      return AudioPermissionState.granted;
    }

    if (audioStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      return AudioPermissionState.permanentlyDenied;
    }

    return AudioPermissionState.denied;
  }

  /// Request audio permissions tailored for Android 13+ (audio) & Android 12- (storage).
  static Future<AudioPermissionState> requestPermission() async {
    // Request both permissions - Android automatically asks only for the supported one
    final statuses = await [
      Permission.audio,
      Permission.storage,
    ].request();

    final audioStatus = statuses[Permission.audio];
    final storageStatus = statuses[Permission.storage];

    if ((audioStatus != null && audioStatus.isGranted) ||
        (storageStatus != null && storageStatus.isGranted)) {
      return AudioPermissionState.granted;
    }

    // Fallback to on_audio_query's built-in request method if needed
    final queryGranted = await _audioQuery.permissionsRequest();
    if (queryGranted) {
      return AudioPermissionState.granted;
    }

    if ((audioStatus != null && audioStatus.isPermanentlyDenied) ||
        (storageStatus != null && storageStatus.isPermanentlyDenied)) {
      return AudioPermissionState.permanentlyDenied;
    }

    return AudioPermissionState.denied;
  }

  /// Open Android App Settings if permission was permanently denied.
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
