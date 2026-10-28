import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/sources/ytm/yt_music_auth_service.dart';
import '../../home/presentation/ytm_history_notifier.dart';

/// Screen hosting an in-app WebView for authenticating with YouTube Music.
///
/// Securely loads the official music.youtube.com interface, captures session
/// cookies (such as SAPISID) upon sign-in, and stores them for direct history access.
class YtMusicLoginScreen extends ConsumerStatefulWidget {
  const YtMusicLoginScreen({super.key});

  @override
  ConsumerState<YtMusicLoginScreen> createState() => _YtMusicLoginScreenState();
}

class _YtMusicLoginScreenState extends ConsumerState<YtMusicLoginScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            // Attempt auto-detection of login cookies
            await _checkAndExtractCookies(isSilent: true);
          },
          onWebResourceError: (error) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://music.youtube.com'));
  }

  /// Extracts cookies from the WebView and persists them if authenticated.
  Future<void> _checkAndExtractCookies({bool isSilent = false}) async {
    if (_isSaving) return;

    try {
      final cookieManager = WebViewCookieManager();
      final musicCookies = await cookieManager.getCookies(domain: Uri.parse('https://music.youtube.com'));
      final ytCookies = await cookieManager.getCookies(domain: Uri.parse('https://youtube.com'));
      final googleCookies = await cookieManager.getCookies(domain: Uri.parse('https://google.com'));

      final cookiesMap = <String, String>{};
      for (final c in [...googleCookies, ...ytCookies, ...musicCookies]) {
        cookiesMap[c.name] = c.value;
      }

      // Also incorporate any document.cookie values
      try {
        final jsCookies = await _controller.runJavaScriptReturningResult('document.cookie');
        final jsClean = jsCookies.toString().replaceAll('"', '').trim();
        for (final pair in jsClean.split(';')) {
          final parts = pair.split('=');
          if (parts.length == 2) {
            cookiesMap[parts[0].trim()] = parts[1].trim();
          }
        }
      } catch (_) {}

      final cookiesString = cookiesMap.entries.map((e) => '${e.key}=${e.value}').join('; ');

      if (cookiesString.contains('SAPISID') ||
          cookiesString.contains('__Secure-3PAPISID') ||
          cookiesString.contains('LOGIN_INFO') ||
          cookiesString.contains('SSID') ||
          cookiesString.contains('HSID')) {
        setState(() => _isSaving = true);
        await YtMusicAuthService.saveCookies(cookiesString);

        // Refresh YouTube Music history
        ref.read(ytmHistoryProvider.notifier).fetchHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully connected to YouTube Music!'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
        return;
      }

      if (!isSilent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please finish signing in on the YouTube Music page first.'),
            backgroundColor: AppColors.surfaceElevated,
          ),
        );
      }
    } catch (e) {
      if (!isSilent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving login: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connect YouTube Music'),
        backgroundColor: AppColors.surface,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : () => _checkAndExtractCookies(isSilent: false),
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, color: AppColors.primary),
            label: const Text(
              'Done',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
