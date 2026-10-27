import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation/navigation_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../player/presentation/mini_player.dart';

/// Root navigation shell hosting the 3 primary tabs and the persistent mini player.
class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
