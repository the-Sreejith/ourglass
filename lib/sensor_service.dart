import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

enum DeviceOrientation {
  upright,
  upsideDown,
  tilted,
}

class SensorService {
  final StreamController<DeviceOrientation> _orientationController =
      StreamController.broadcast();
  
  Stream<DeviceOrientation> get orientationStream => _orientationController.stream;

  StreamSubscription? _accelerometerSubscription;
  DeviceOrientation _currentOrientation = DeviceOrientation.tilted;

  static const double _orientationThreshold = 7.0;

  void start() {
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((AccelerometerEvent event) {
      final double y = event.y;
      final double z = event.z;
      
      DeviceOrientation newOrientation;

      if (z.abs() < 4) {
        if (y > _orientationThreshold) {
          newOrientation = DeviceOrientation.upright;
        } else if (y < -_orientationThreshold) {
          newOrientation = DeviceOrientation.upsideDown;
        } else {
          newOrientation = DeviceOrientation.tilted;
        }
      } else {
        newOrientation = DeviceOrientation.tilted;
      }
     
      if (newOrientation != _currentOrientation) {
        _currentOrientation = newOrientation;
        _orientationController.add(_currentOrientation);
      }
    });
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _orientationController.close();
  }
}