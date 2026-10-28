import 'package:dio/dio.dart';
import '../../../core/services/track_cache_service.dart';
import '../../library/presentation/downloaded_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/sources/ytm/yt_music_auth_service.dart';
import '../../home/presentation/ytm_history_notifier.dart';
import 'settings_notifier.dart';
import 'yt_music_login_screen.dart';

/// Settings screen for configuring companion backend URL, connectivity, and info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(settingsProvider).backendBaseUrl;
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final testUrl = _urlController.text.trim();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
      ),
    );

    try {
      final response = await dio.get('$testUrl/health');
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final isAuthPresent = data['auth_file_present'] == true;
        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _testResult = isAuthPresent
              ? 'Connected successfully! YouTube Music authentication is active.'
              : 'Connected, but browser.json is missing on the server. Follow backend/README.md.';
        });
      } else {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Server returned unexpected status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult =
            'Connection failed. Ensure FastAPI server is running on $testUrl.';
      });
    }
  }

  Future<void> _saveUrl() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setBackendBaseUrl(newUrl);
      // Trigger refresh on history
      ref.read(ytmHistoryProvider.notifier).fetchHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved backend URL: $newUrl'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // SECTION 1: Direct YouTube Music Account Login (Optional)
          const Text(
            'YouTube Music Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Log in with your Google account to automatically sync and fetch your real YouTube Music history directly on your phone.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<bool>(
            future: YtMusicAuthService.isLoggedIn(),
            builder: (context, snapshot) {
              final isLoggedIn = snapshot.data == true;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLoggedIn ? AppColors.primary.withValues(alpha: 0.4) : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLoggedIn ? Icons.account_circle : Icons.no_accounts,
                      color: isLoggedIn ? AppColors.primary : AppColors.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? 'Connected to YouTube Music' : 'Not Connected',
                            style: TextStyle(
                              color: isLoggedIn ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLoggedIn
                                ? 'Your history is synced directly on this device.'
                                : 'Optional. You can still search and stream all songs.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isLoggedIn)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () async {
                          await YtMusicAuthService.logout();
                          ref.read(ytmHistoryProvider.notifier).fetchHistory();
                          setState(() {});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out of YouTube Music.')),
                            );
                          }
                        },
                        child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      )
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const YtMusicLoginScreen()),
                          );
                          if (result == true) {
                            setState(() {});
                          }
                        },
                        child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          const Text(
            'YouTube Music Companion Backend (Self-Hosted)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Optional. Only needed if you run the Python backend on your PC. In-app login and direct search work without any server.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          // URL Input field
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              labelText: 'Backend Base URL',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintText: 'http://192.168.1.X:8000',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Presets row
          Row(
            children: [
              _buildPresetChip('Emulator (10.0.2.2)', 'http://10.0.2.2:8000'),
              const SizedBox(width: 8),
              _buildPresetChip('Default LAN IP', 'http://192.168.1.100:8000'),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons: Test & Save
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isTesting ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Text(
                          'Test Connection',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // Test results message box
          if (_testResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testSuccess
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _testSuccess ? Colors.green : Colors.redAccent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _testSuccess ? Icons.check_circle : Icons.error_outline,
                    color: _testSuccess ? Colors.green : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _testResult!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _testSuccess ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),

          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // Stream Resolution Strategy Selection
          const Text(
            'YouTube Music Playback Strategy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose how Tugtog resolves tracks from your YouTube Music history. Both strategies can be swapped without changing other screens.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          Consumer(
            builder: (context, ref, child) {
              final activeStrategy =
                  ref.watch(settingsProvider).streamResolutionStrategyId;
              final settingsNotifier = ref.read(settingsProvider.notifier);

              return Column(
                children: [
                  _buildStrategyTile(
                    id: 'direct_youtube',
                    title: 'Direct YouTube Audio (Recommended)',
                    subtitle:
                        'Streams high-quality audio directly from YouTube. Supports background play, lock screen controls, seek bar, queue, and equalizer.',
                    badge: 'Recommended',
                    badgeColor: AppColors.primary,
                    isSelected: activeStrategy == 'direct_youtube',
                    onTap: () =>
                        settingsNotifier.setStreamResolutionStrategy('direct_youtube'),
                  ),
                  const SizedBox(height: 12),
                  _buildStrategyTile(
                    id: 'match_audio',
                    title: 'Audius & Jamendo Matcher',
                    subtitle:
                        'Matches the song on free sources (Audius & Jamendo) for background playback, notification controls, and lock screen queueing.',
                    badge: 'Background Audio',
                    badgeColor: AppColors.primary,
                    isSelected: activeStrategy == 'match_audio',
                    onTap: () =>
                        settingsNotifier.setStreamResolutionStrategy('match_audio'),
                  ),
                  const SizedBox(height: 12),
                  _buildStrategyTile(
                    id: 'iframe_webview',
                    title: 'In-App YouTube IFrame Player',
                    subtitle:
                        'Opens the exact video in an in-app WebView using the official YouTube Player. Operates foreground-only (background playback not available).',
                    badge: 'Foreground Only',
                    badgeColor: Colors.amber,
                    isSelected: activeStrategy == 'iframe_webview',
                    onTap: () =>
                        settingsNotifier.setStreamResolutionStrategy('iframe_webview'),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          // SECTION: Offline Mode & Cache Management (Spotify Premium Style)
          const Text(
            'Offline Mode & Storage Cache',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Save streamed tracks directly to your phone for 100% buffer-free offline listening, just like Spotify Premium.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          Consumer(
            builder: (context, ref, child) {
              final settings = ref.watch(settingsProvider);
              final notifier = ref.read(settingsProvider.notifier);

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeTrackColor: AppColors.primary,
                      title: const Text(
                        'Auto-Download / Cache Online Music',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Automatically saves YouTube Music tracks to offline storage as you play them.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: settings.autoDownloadCache,
                      onChanged: (val) => notifier.setAutoDownloadCache(val),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SwitchListTile(
                      activeTrackColor: AppColors.primary,
                      title: const Text(
                        'Offline Mode Only',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Only play downloaded songs to save cellular data when you have no Wi-Fi.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: settings.offlineModeOnly,
                      onChanged: (val) => notifier.setOfflineModeOnly(val),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ListTile(
                      leading: const Icon(Icons.sd_storage, color: AppColors.primary),
                      title: const Text(
                        'Cached Offline Music',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${TrackCacheService.formatBytes(settings.cachedSizeBytes)} used',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: settings.cachedSizeBytes == 0
                            ? null
                            : () => _confirmClearCache(context, ref),
                        child: const Text(
                          'Clear Cache',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 28),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 16),

          const Text(
            'About Tugtog',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Version 1.0.0\nA free personal Spotify-like music player for Android, combining local device storage, Audius, Jamendo, and YouTube Music history.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
      ),
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      onPressed: () {
        setState(() {
          _urlController.text = url;
        });
      },
    );
  }

  Widget _buildStrategyTile({
    required String id,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: badgeColor.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Clear Music Cache?'),
        content: const Text(
          'This will delete all downloaded songs from device storage to free up space.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(settingsProvider.notifier).clearAllCache();
              await ref.read(downloadedProvider.notifier).loadDownloadedTracks();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline music cache cleared successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
