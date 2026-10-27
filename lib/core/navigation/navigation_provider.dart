import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported tabs in bottom navigation bar.
enum NavigationTab {
  home,
  search,
  library,
}

/// Notifier managing active bottom navigation index.
class NavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int index) {
    if (index >= 0 && index <= 2) {
      state = index;
    }
  }
}

/// Global provider for bottom navigation tab index.
final navigationProvider =
    NotifierProvider<NavigationNotifier, int>(NavigationNotifier.new);
