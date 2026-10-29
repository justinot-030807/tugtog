import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugtog/features/home/presentation/discover_notifier.dart';
import 'package:tugtog/features/home/presentation/ytm_history_notifier.dart';
import 'package:tugtog/features/navigation/presentation/main_scaffold.dart';
import 'package:tugtog/main.dart';

class FakeDiscoverNotifier extends DiscoverNotifier {
  @override
  DiscoverState build() {
    return const DiscoverState(isLoading: false, tracks: []);
  }
}

class FakeYtmHistoryNotifier extends YtmHistoryNotifier {
  @override
  YtmHistoryState build() {
    return const YtmHistoryState(isLoading: false, tracks: []);
  }
}

void main() {
  testWidgets('Tugtog app launches and displays Home screen and MiniPlayer',
      (WidgetTester tester) async {
    // Build TugtogApp wrapped in ProviderScope with stubbed network providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverProvider.overrideWith(FakeDiscoverNotifier.new),
          ytmHistoryProvider.overrideWith(FakeYtmHistoryNotifier.new),
        ],
        child: const TugtogApp(home: MainScaffold()),
      ),
    );

    // Verify Home tab header is displayed
    expect(find.text('Good evening'), findsOneWidget);

    // Verify bottom navigation tabs exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Your Library'), findsOneWidget);

    // Verify mini player displays current dummy track
    expect(find.text('Midnight City'), findsOneWidget);
    expect(find.text('M83'), findsOneWidget);
  });

  testWidgets('Tapping Search tab displays SearchScreen without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverProvider.overrideWith(FakeDiscoverNotifier.new),
          ytmHistoryProvider.overrideWith(FakeYtmHistoryNotifier.new),
        ],
        child: const TugtogApp(home: MainScaffold()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(find.text('What do you want to listen to?'), findsOneWidget);
  });
}
