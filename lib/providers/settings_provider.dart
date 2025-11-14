import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HourglassSettings with ChangeNotifier {
  late SharedPreferences _prefs;
  
  double _totalDurationInSeconds = 90.0; // Default value
  bool _isLoading = true;

  // Getters
  double get totalDurationInSeconds => _totalDurationInSeconds;
  bool get isLoading => _isLoading;

  // Method to load settings from storage
  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    // Retrieve saved duration, or use default if none exists
    _totalDurationInSeconds = _prefs.getDouble('duration') ?? 90.0;
    _isLoading = false;
    notifyListeners(); 
  }

  // Method to update and save the duration
  Future<void> updateDuration(double newDuration) async {
    _totalDurationInSeconds = newDuration;
    notifyListeners();
    await _prefs.setDouble('duration', newDuration);
  }
}
