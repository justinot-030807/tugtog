import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration state for app settings.
class SettingsState {
  final String backendBaseUrl;
  final String streamResolutionStrategyId;
  final bool isLoaded;

  const SettingsState({
    this.backendBaseUrl = 'http://192.168.1.100:8000',
    this.streamResolutionStrategyId = 'direct_youtube',
    this.isLoaded = false,
  });

  SettingsState copyWith({
    String? backendBaseUrl,
    String? streamResolutionStrategyId,
    bool? isLoaded,
  }) {
    return SettingsState(
      backendBaseUrl: backendBaseUrl ?? this.backendBaseUrl,
      streamResolutionStrategyId:
          streamResolutionStrategyId ?? this.streamResolutionStrategyId,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

/// Riverpod Notifier managing persistent settings with SharedPreferences.
class SettingsNotifier extends Notifier<SettingsState> {
  static const String _backendUrlKey = 'backend_base_url';
  static const String _strategyKey = 'stream_resolution_strategy';
  static const String defaultBackendUrl = 'http://192.168.1.100:8000';
  static const String defaultStrategyId = 'direct_youtube';

  @override
  SettingsState build() {
    Future.microtask(() => loadSettings());
    return const SettingsState();
  }

  /// Load settings from SharedPreferences.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_backendUrlKey) ?? defaultBackendUrl;
      var savedStrategy = prefs.getString(_strategyKey) ?? defaultStrategyId;
      // Auto-migrate legacy default 'match_audio' to 'direct_youtube'
      if (savedStrategy == 'match_audio') {
        savedStrategy = defaultStrategyId;
        await prefs.setString(_strategyKey, defaultStrategyId);
      }
      state = state.copyWith(
        backendBaseUrl: savedUrl,
        streamResolutionStrategyId: savedStrategy,
        isLoaded: true,
      );
    } catch (_) {
      state = state.copyWith(
        backendBaseUrl: defaultBackendUrl,
        streamResolutionStrategyId: defaultStrategyId,
        isLoaded: true,
      );
    }
  }

  /// Update and persist backend base URL.
  Future<void> setBackendBaseUrl(String url) async {
    var cleanedUrl = url.trim();
    if (cleanedUrl.endsWith('/')) {
      cleanedUrl = cleanedUrl.substring(0, cleanedUrl.length - 1);
    }
    state = state.copyWith(backendBaseUrl: cleanedUrl);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_backendUrlKey, cleanedUrl);
    } catch (_) {}
  }

  /// Update and persist stream resolution strategy.
  Future<void> setStreamResolutionStrategy(String strategyId) async {
    state = state.copyWith(streamResolutionStrategyId: strategyId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_strategyKey, strategyId);
    } catch (_) {}
  }
}

/// Global provider for application settings.
final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
