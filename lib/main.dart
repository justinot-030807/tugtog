import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

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

  // Friendly error fallback instead of Flutter's default release grey box
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.orangeAccent, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'View Render Notice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: TugtogApp(),
    ),
  );
}

/// Root application widget for Tugtog.
class TugtogApp extends StatelessWidget {
  final Widget? home;
  const TugtogApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tugtog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: home ?? const SplashScreen(),
    );
  }
}
