import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/audio_permission_helper.dart';

/// Friendly permission prompt widget when device audio access is not granted.
class PermissionRequestCard extends StatelessWidget {
  final AudioPermissionState permissionState;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  const PermissionRequestCard({
    super.key,
    required this.permissionState,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isPermanentlyDenied =
        permissionState == AudioPermissionState.permanentlyDenied;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.library_music_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Listen to your local music',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              isPermanentlyDenied
                  ? 'Audio access was permanently disabled in system settings. Please enable storage or audio permissions in Android Settings to let Tugtog scan your device music.'
                  : 'To play your MP3, FLAC, M4A, and local music files, Tugtog needs permission to access audio on this device.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // Action button
            ElevatedButton(
              onPressed: isPermanentlyDenied ? onOpenSettings : onRequestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                isPermanentlyDenied ? 'Open Settings' : 'Grant Permission',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (isPermanentlyDenied) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRequestPermission,
                child: const Text(
                  'I enabled it, refresh now',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
