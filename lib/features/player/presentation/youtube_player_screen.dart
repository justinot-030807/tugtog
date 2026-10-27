import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/track.dart';

/// Screen displaying the official YouTube IFrame Player in a WebView.
/// Clearly labeled as foreground-only per YouTube terms and technical constraints.
class YouTubePlayerScreen extends StatefulWidget {
  final String videoId;
  final Track track;

  const YouTubePlayerScreen({
    super.key,
    required this.videoId,
    required this.track,
  });

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF121212))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadHtmlString(_buildHtml(widget.videoId));
  }

  String _buildHtml(String videoId) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      background-color: #121212;
      width: 100%;
      height: 100%;
      display: flex;
      justify-content: center;
      align-items: center;
      overflow: hidden;
    }
    .video-container {
      width: 100%;
      height: 100%;
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    iframe {
      width: 100%;
      height: 100%;
      border: 0;
    }
  </style>
</head>
<body>
  <div class="video-container">
    <iframe
      src="https://www.youtube.com/embed/$videoId?autoplay=1&playsinline=1&enablejsapi=1&rel=0&modestbranding=1"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>
  </div>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.track.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.track.artist,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Clear Foreground-Only Label Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade300, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foreground Only Mode',
                          style: TextStyle(
                            color: Colors.amber.shade300,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Background playback and lock screen controls are not available in YouTube IFrame mode.',
                          style: TextStyle(
                            color: Colors.amber.shade100,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Interactive YouTube WebView Player
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    Container(
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Track Details & Switch Option
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (widget.track.artworkUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              widget.track.artworkUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.music_note,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.track.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.track.artist,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: AppColors.divider),
                    const Text(
                      'About YouTube Playback Mode',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This mode streams directly from YouTube via the official IFrame Player. For full background listening and notification controls, switch to the "Audius & Jamendo Matcher" strategy in Settings.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
