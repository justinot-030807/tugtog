import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/presentation/main_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables if available
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  // Initialize background audio service & system notification
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.tugtog.tugtog.audio',
    androidNotificationChannelName: 'Tugtog Audio Playback',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );

  runApp(
    const ProviderScope(
      child: TugtogApp(),
    ),
  );
}

/// Root application widget for Tugtog.
class TugtogApp extends StatelessWidget {
  const TugtogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tugtog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScaffold(),
    );
  }
}
