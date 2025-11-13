import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'screens/hourglass_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => HourglassSettings()..loadSettings(),
      child: const HourglassApp(),
    ),
  );
}

class HourglassApp extends StatelessWidget {
  const HourglassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HourglassSettings>(
      builder: (context, settings, child) {
        if (settings.isLoading) {
          // Show a loading screen while preferences are loaded
          return MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
          );
        }

        // Once settings are loaded, show the main app
        return MaterialApp(
          title: 'Pixel Hourglass',
          theme: ThemeData.dark(),
          home: const HourglassPage(),
        );
      },
    );
  }
}