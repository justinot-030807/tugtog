import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../lyrics_notifier.dart';
import '../player_controller.dart';

/// Spotify-style full/modal sheet for synchronized and plain lyrics.
class LyricsSheet extends ConsumerStatefulWidget {
  final Color dynamicColor;

  const LyricsSheet({
    super.key,
    this.dynamicColor = AppColors.primary,
  });

  @override
  ConsumerState<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends ConsumerState<LyricsSheet> {
  final ScrollController _scrollController = ScrollController();
  int _lastAutoScrolledIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index, int totalLines) {
    if (index == _lastAutoScrolledIndex || !_scrollController.hasClients) return;
    _lastAutoScrolledIndex = index;

    // Approximate line height ~52px; center active line
    final targetOffset = (index * 52.0) - 120.0;
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyricsState = ref.watch(lyricsProvider);
    final currentTrack = ref.watch(playerControllerProvider).currentTrack;

    if (lyricsState.currentLineIndex >= 0 &&
        lyricsState.lyrics?.syncedLyrics.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveLine(
          lyricsState.currentLineIndex,
          lyricsState.lyrics!.syncedLyrics.length,
        );
      });
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.dynamicColor.withValues(alpha: 0.75),
            const Color(0xFF121212),
          ],
          stops: const [0.0, 0.55],
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.lyrics, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lyrics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentTrack != null)
                        Text(
                          '${currentTrack.title} • ${currentTrack.artist}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Lyrics Body
          Expanded(
            child: _buildLyricsBody(lyricsState),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsBody(LyricsState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Finding lyrics...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (state.lyrics == null || state.lyrics!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.music_off_outlined, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Text(
                state.error ?? 'Lyrics not available for this track',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lyrics = state.lyrics!;

    // Synced lyrics view
    if (lyrics.isSynced && lyrics.syncedLyrics.isNotEmpty) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        itemCount: lyrics.syncedLyrics.length,
        itemBuilder: (context, index) {
          final line = lyrics.syncedLyrics[index];
          final isActive = index == state.currentLineIndex;

          return InkWell(
            onTap: () {
              // Tap to seek directly to timestamp (Spotify Premium feature!)
              ref.read(playerControllerProvider.notifier).seek(line.timestamp);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  fontSize: isActive ? 22 : 17,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                  height: 1.35,
                ),
                child: Text(line.text),
              ),
            ),
          );
        },
      );
    }

    // Plain text lyrics fallback
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Text(
        lyrics.plainLyrics ?? '',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.7,
        ),
      ),
    );
  }
}
