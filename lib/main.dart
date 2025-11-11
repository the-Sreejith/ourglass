import 'package:flutter/material.dart';
import 'hourglass_screen.dart'; // Import the new screen

void main() {
  runApp(const HourglassApp());
}

class HourglassApp extends StatelessWidget {
  const HourglassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Hourglass',
      theme: ThemeData.dark(),
      // The home is now the HourglassPage from the new file
      home: const HourglassPage(), 
    );
  }
}