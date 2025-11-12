import 'package:flutter/material.dart';
import 'hourglass_screen.dart'; 

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
      home: const HourglassPage(), 
    );
  }
}