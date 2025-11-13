import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  final StreamController<int> _orientationController =
      StreamController.broadcast();
  
  Stream<int> get orientationStream => _orientationController.stream;

  StreamSubscription? _accelerometerSubscription;
  int _currentOrientationValue = 0; // 0 = tilted, 1 = upright, -1 = upside down

  static const double _orientationThreshold = 7.0;

  void start() {
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((AccelerometerEvent event) {
      final double y = event.y;
      final double z = event.z;
      
      int newOrientationValue;

      if (z.abs() < 4) {
        if (y > _orientationThreshold) {
          newOrientationValue = 1; // Upright
        } else if (y < -_orientationThreshold) {
          newOrientationValue = -1; // Upside Down
        } else {
          newOrientationValue = 0; // Tilted
        }
      } else {
        newOrientationValue = 0; // Tilted
      }
     
      if (newOrientationValue != _currentOrientationValue) {
        _currentOrientationValue = newOrientationValue;
        _orientationController.add(_currentOrientationValue);
      }
    });
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _orientationController.close();
  }
}