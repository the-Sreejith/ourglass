// main.dart
import 'package:flutter/material.dart';
import 'hourglass_screen.dart';

void main() {
  runApp(const HourglassApp());
}

class HourglassApp extends StatelessWidget {
  const HourglassApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixelated Hourglass',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      ),
      home: const HourglassScreen(),
    );
  }
}
