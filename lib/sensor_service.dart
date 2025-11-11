import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

// Enum to represent the discrete orientations we care about.
enum DeviceOrientation {
  upright,
  upsideDown,
  tilted,
}

class SensorService {
  // Stream controller to broadcast the orientation changes.
  final StreamController<DeviceOrientation> _orientationController =
      StreamController.broadcast();
  
  // Public stream for widgets to listen to.
  Stream<DeviceOrientation> get orientationStream => _orientationController.stream;

  StreamSubscription? _accelerometerSubscription;
  DeviceOrientation _currentOrientation = DeviceOrientation.tilted;

  // Threshold for detecting upright or upside-down orientation.
  // This value is based on gravity (9.8 m/s^2). 7.0 is a safe threshold.
  static const double _orientationThreshold = 7.0;

  void start() {
    // Start listening to the accelerometer stream.
    // We use the normal interval for a good balance of responsiveness and battery life.
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((AccelerometerEvent event) {
      final double y = event.y;
      final double z = event.z;
      
      DeviceOrientation newOrientation;

      // Check if the phone is held relatively flat (on its back or front).
      // We only want to detect flips when it's held vertically.
      if (z.abs() < 4) {
        // Phone is upright
        if (y > _orientationThreshold) {
          newOrientation = DeviceOrientation.upright;
        // Phone is upside down
        } else if (y < -_orientationThreshold) {
          newOrientation = DeviceOrientation.upsideDown;
        // Phone is vertical but not fully flipped (e.g., sideways)
        } else {
          newOrientation = DeviceOrientation.tilted;
        }
      } else {
        // Phone is tilted, lying flat, or in another orientation.
        newOrientation = DeviceOrientation.tilted;
      }

      // Only broadcast the event if the orientation has actually changed.
      if (newOrientation != _currentOrientation) {
        _currentOrientation = newOrientation;
        _orientationController.add(_currentOrientation);
      }
    });
  }

  void dispose() {
    // Clean up resources.
    _accelerometerSubscription?.cancel();
    _orientationController.close();
  }
}