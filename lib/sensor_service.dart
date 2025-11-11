// sensor_service.dart
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;

class SensorService {
  StreamSubscription? _accelerometerSubscription;
  Function(double, bool)? _onTiltChanged;
  
  static const double _tiltThreshold = 0.3;

  void startListening(Function(double, bool) onTiltChanged) {
    _onTiltChanged = onTiltChanged;
    
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      // Calculate direction based on all three axes
      // Using accelerometer gives us gravity direction which indicates device orientation
      double x = event.x;
      double y = event.y;
      double z = event.z;
      
      // Calculate the magnitude of the tilt vector in the x-y plane
      double magnitude = math.sqrt(x * x + y * y + z * z);
      
      // Normalize to avoid division by zero
      if (magnitude < 0.1) {
        _onTiltChanged?.call(0.0, false);
        return;
      }
      
      // Calculate vertical component (z-axis, where device is upright when z ≈ 9.8)
      // Normalize z to range [-1, 1] where -1 is upside down, 1 is upright
      double normalizedZ = (z / magnitude).clamp(-1.0, 1.0);
      
      // Calculate horizontal tilt direction combining x and y
      // When device tilts forward/backward (y-axis) or left/right (x-axis)
      double horizontalTilt = y / magnitude;
      
      // Direction value: combines vertical orientation with horizontal tilt
      // Positive when tilted one way, negative when tilted the other
      double direction = horizontalTilt * (1.0 - normalizedZ.abs());
      direction = direction.clamp(-1.0, 1.0);
      
      // Check if device is tilted enough to flow
      bool isFlowing = direction.abs() > _tiltThreshold && normalizedZ.abs() < 0.9;
      
      _onTiltChanged?.call(direction, isFlowing);
    });
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
  }
}