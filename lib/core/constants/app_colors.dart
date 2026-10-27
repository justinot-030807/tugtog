import 'package:flutter/material.dart';

/// App color palette inspired by Spotify's dark design system.
class AppColors {
  AppColors._();

  /// Primary Spotify green accent.
  static const Color primary = Color(0xFF1DB954);

  /// Lighter green for active / hover states.
  static const Color primaryLight = Color(0xFF1ED760);

  /// Pure dark canvas background.
  static const Color background = Color(0xFF121212);

  /// Elevated card / surface background.
  static const Color surface = Color(0xFF181818);

  /// Higher elevation surface (e.g., mini player, dialogs).
  static const Color surfaceElevated = Color(0xFF242424);

  /// Subtle border or divider line.
  static const Color divider = Color(0xFF282828);

  /// Primary bright white text.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary muted gray text.
  static const Color textSecondary = Color(0xFFB3B3B3);

  /// Inactive bottom navigation or icon tint.
  static const Color iconInactive = Color(0xFF727272);

  /// Active icon tint.
  static const Color iconActive = Color(0xFFFFFFFF);
}
