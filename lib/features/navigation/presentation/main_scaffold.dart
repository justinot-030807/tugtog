import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/navigation_provider.dart';
import '../../../core/services/app_update_service.dart';
import '../../home/presentation/home_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../player/presentation/mini_player.dart';
import '../../settings/presentation/widgets/update_dialog.dart';

/// Root navigation shell hosting the 3 primary tabs and the persistent mini player.
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  static const List<Widget> _screens = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Non-blocking auto update check 3 seconds after landing on the main screen
    _updateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _checkAutoUpdate();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAutoUpdate() async {
    try {
      final updateInfo = await AppUpdateService.instance.checkForUpdate();
      if (!mounted) return;
      if (updateInfo != null && updateInfo.hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            duration: const Duration(seconds: 8),
            content: Row(
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'May bagong update! (Tugtog v${updateInfo.latestVersion})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'I-update',
              textColor: AppColors.primary,
              onPressed: () {
                UpdateDialog.show(context, updateInfo);
              },
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentTabIndex = ref.watch(navigationProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Mini Player docked above BottomNavigationBar
            const MiniPlayer(),

            // Bottom Navigation Bar
            BottomNavigationBar(
              currentIndex: currentTabIndex,
              onTap: (index) {
                ref.read(navigationProvider.notifier).selectTab(index);
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(Icons.library_music),
                  label: 'Your Library',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

