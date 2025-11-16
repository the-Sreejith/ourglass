import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HourglassSettings with ChangeNotifier {
  late SharedPreferences _prefs;

  double _totalDurationInSeconds = 90.0; // Default value
  bool _isLoading = true;

  // New settings
  bool _soundEnabled = true;
  bool _startInTiltedAngles = false;
  bool _showButtons = true;
  Color _sandColor = Colors.white;
  Color _emptyColor = const Color(0xFF222222);

  // Getters
  double get totalDurationInSeconds => _totalDurationInSeconds;
  bool get isLoading => _isLoading;
  bool get soundEnabled => _soundEnabled;
  bool get startInTiltedAngles => _startInTiltedAngles;
  bool get showButtons => _showButtons;
  Color get sandColor => _sandColor;
  Color get emptyColor => _emptyColor;

  // Method to load settings from storage
  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    // Retrieve saved duration, or use default if none exists
    _totalDurationInSeconds = _prefs.getDouble('duration') ?? 90.0;
    _soundEnabled = _prefs.getBool('soundEnabled') ?? true;
    _startInTiltedAngles = _prefs.getBool('startInTiltedAngles') ?? false;
    _showButtons = _prefs.getBool('showButtons') ?? true;

    // Load colors
    final sandColorValue = _prefs.getInt('sandColor');
    if (sandColorValue != null) {
      _sandColor = Color(sandColorValue);
    }
    final emptyColorValue = _prefs.getInt('emptyColor');
    if (emptyColorValue != null) {
      _emptyColor = Color(emptyColorValue);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Method to update and save the duration
  Future<void> updateDuration(double newDuration) async {
    _totalDurationInSeconds = newDuration;
    notifyListeners();
    await _prefs.setDouble('duration', newDuration);
  }

  // Method to update and save sound setting
  Future<void> updateSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    notifyListeners();
    await _prefs.setBool('soundEnabled', enabled);
  }

  // Method to update and save tilted angles setting
  Future<void> updateStartInTiltedAngles(bool enabled) async {
    _startInTiltedAngles = enabled;
    notifyListeners();
    await _prefs.setBool('startInTiltedAngles', enabled);
  }

  // Method to update and save show buttons setting
  Future<void> updateShowButtons(bool show) async {
    _showButtons = show;
    notifyListeners();
    await _prefs.setBool('showButtons', show);
  }

  // Method to update and save sand color
  Future<void> updateSandColor(Color color) async {
    _sandColor = color;
    notifyListeners();
    await _prefs.setInt('sandColor', color.value);
  }

  // Method to update and save empty color
  Future<void> updateEmptyColor(Color color) async {
    _emptyColor = color;
    notifyListeners();
    await _prefs.setInt('emptyColor', color.value);
  }
}
