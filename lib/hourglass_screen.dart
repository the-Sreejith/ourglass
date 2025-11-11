import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import for CupertinoTimerPicker
import 'sensor_service.dart';

class HourglassPage extends StatefulWidget {
  const HourglassPage({super.key});

  @override
  State<HourglassPage> createState() => _HourglassPageState();
}

class _HourglassPageState extends State<HourglassPage> {
  final SensorService _sensorService = SensorService();
  StreamSubscription? _sensorSubscription;
  Timer? _sandTimer;

  DeviceOrientation _orientation = DeviceOrientation.upright;
  bool _isFlowing = false;

  // Constants for the hourglass
  static const int _totalSand = 100; // Total "units" of sand
  static const int _gridCells = 64; // 8x8 grid

  // State for editable time
  double _totalDurationInSeconds = 15.0; // Default time: 15 seconds
  late Duration _sandTickDuration; // Will be calculated based on total time
  double _timeLeftInSeconds = 0.0; // State for time left display

  // State of the sand
  int _topSand = _totalSand;
  int _bottomSand = 0;

  @override
  void initState() {
    super.initState();
    _timeLeftInSeconds = _totalDurationInSeconds; // Initialize time left
    _updateTickDuration(); // Calculate initial tick duration
    // Start the sensor service and listen for changes.
    _sensorService.start();
    _sensorSubscription =
        _sensorService.orientationStream.listen(_handleOrientationChange);
    // Start the flow immediately if the phone is upright.
    _startFlow();
  }

  @override
  void dispose() {
    // Clean up all streams and timers.
    _sensorSubscription?.cancel();
    _sensorService.dispose();
    _sandTimer?.cancel();
    super.dispose();
  }

  // Calculate how long each "unit" of sand should take to fall.
  void _updateTickDuration() {
    // Ensure duration is at least 1 second to prevent issues
    if (_totalDurationInSeconds < 1) _totalDurationInSeconds = 1;
    // Calculate milliseconds per tick
    final int tickMillis = (_totalDurationInSeconds * 1000) ~/ _totalSand;
    // Ensure tick is at least 1ms
    _sandTickDuration = Duration(milliseconds: tickMillis > 0 ? tickMillis : 1);

    // If flowing, restart the timer with the new duration
    if (_isFlowing) {
      _stopFlow();
      _startFlow();
    }
  }

  void _handleOrientationChange(DeviceOrientation newOrientation) {
    if (newOrientation == _orientation) return;

    setState(() {
      _orientation = newOrientation;
    });

    // Logic to flip the hourglass when turned upside down.
    if (_orientation == DeviceOrientation.upright && _topSand == 0) {
      _flipSand();
    } else if (_orientation == DeviceOrientation.upsideDown && _bottomSand == 0) {
      _flipSand();
    }

    // Start or stop the flow based on orientation.
    if (_orientation == DeviceOrientation.upright ||
        _orientation == DeviceOrientation.upsideDown) {
      _startFlow();
    } else {
      _stopFlow();
    }
  }

  void _flipSand() {
    setState(() {
      int temp = _topSand;
      _topSand = _bottomSand;
      _bottomSand = temp;

      // Recalculate time left based on the new "active" bulb
      int activeSand =
          (_orientation == DeviceOrientation.upright) ? _topSand : _bottomSand;
      if (activeSand == 0) {
        _timeLeftInSeconds = 0.0;
      } else {
        _timeLeftInSeconds =
            _totalDurationInSeconds * (activeSand / _totalSand);
      }
    });
  }

  void _startFlow() {
    // Don't start a new timer if one is already running.
    if (_isFlowing) return;

    // Check if sand can flow in the current orientation.
    if (_orientation == DeviceOrientation.upright && _topSand == 0) return;
    if (_orientation == DeviceOrientation.upsideDown && _bottomSand == 0) {
      return;
    }

    _isFlowing = true;
    // Start a periodic timer to move the sand.
    _sandTimer = Timer.periodic(_sandTickDuration, _tick);
  }

  void _stopFlow() {
    _sandTimer?.cancel();
    _isFlowing = false;
  }

  void _tick(Timer timer) {
    // This function runs every time the timer "ticks".
    if (!mounted) {
      timer.cancel();
      return;
    }

    bool isFlowing = false;
    int activeSand = 0;

    // Handle sand flow for upright orientation
    if (_orientation == DeviceOrientation.upright) {
      if (_topSand > 0) {
        _topSand--;
        _bottomSand++;
        activeSand = _topSand;
        isFlowing = true;
      }
      // Handle sand flow for upside-down orientation
    } else if (_orientation == DeviceOrientation.upsideDown) {
      if (_bottomSand > 0) {
        _bottomSand--;
        _topSand++;
        activeSand = _bottomSand;
        isFlowing = true;
      }
    }

    if (isFlowing) {
      setState(() {
        _timeLeftInSeconds =
            _totalDurationInSeconds * (activeSand / _totalSand);
      });
    } else {
      // Stop flowing if tilted or empty
      _stopFlow();
      setState(() {
        _timeLeftInSeconds = 0.0;
      });
    }
  }

  // Format seconds into MM:SS string
  String _formatTime(double seconds) {
    // Ceil to show 0:01 instead of 0:00 for the last bit
    int totalSeconds = seconds.ceil();
    if (totalSeconds < 0) totalSeconds = 0;

    int min = totalSeconds ~/ 60;
    int sec = totalSeconds % 60;

    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // Show the dialog to edit the time
  void _showTimeEditDialog() {
    // Use a temporary variable for the picker
    Duration newDuration = Duration(seconds: _totalDurationInSeconds.round());
    showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to update the slider's label in the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Hourglass Time'),
              contentPadding: const EdgeInsets.only(top: 12.0),
              content: SizedBox(
                height: 180,
                width: double.maxFinite, // <--- This is the fix
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.ms, // Minutes and Seconds
                  initialTimerDuration: newDuration,
                  onTimerDurationChanged: (value) {
                    setDialogState(() {
                      newDuration = value;
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Set'),
                  onPressed: () {
                    setState(() {
                      double newTime = newDuration.inSeconds.toDouble();
                      if (newTime < 1.0) newTime = 1.0; // Min 1 second

                      _totalDurationInSeconds = newTime;
                      _updateTickDuration(); // Apply the new time

                      // Reset sand
                      _topSand = _totalSand;
                      _bottomSand = 0;
                      _timeLeftInSeconds = _totalDurationInSeconds;

                      // Restart flow
                      _stopFlow();
                      if (_orientation == DeviceOrientation.upright ||
                          _orientation == DeviceOrientation.upsideDown) {
                        _startFlow();
                      }
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the fill fraction for each bulb.
    double topFraction = _topSand / _totalSand;
    double bottomFraction = _bottomSand / _totalSand;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            'Total: ${_totalDurationInSeconds.toStringAsFixed(0)}s'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTimeEditDialog,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(_timeLeftInSeconds),
              style: const TextStyle(
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.w200,
                fontFamily: 'monospace', // Gives it a nice "digital" look
              ),
            ),
            const SizedBox(height: 20),
            PixelHourglass(
              topSandFraction: topFraction,
              bottomSandFraction: bottomFraction,
              totalGridCells: _gridCells,
            ),
          ],
        ),
      ),
    );
  }
}

// A widget to render the hourglass shape with pixel bulbs.
class PixelHourglass extends StatelessWidget {
  const PixelHourglass({
    super.key,
    required this.topSandFraction,
    required this.bottomSandFraction,
    required this.totalGridCells,
  });

  final double topSandFraction;
  final double bottomSandFraction;
  final int totalGridCells;

  @override
  Widget build(BuildContext context) {
    // Calculate the number of "full" pixels in each bulb.
    final int topFullCells = (topSandFraction * totalGridCells).round();
    final int bottomFullCells = (bottomSandFraction * totalGridCells).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Bulb
        _PixelBulb(
          sandCellCount: topFullCells,
          totalCellCount: totalGridCells,
          isTop: true,
        ),
        // Neck of the hourglass
        Container(
          width: 20, // Wider neck for pixel style
          height: 20,
          color: Colors.grey[850],
        ),
        // Bottom Bulb
        _PixelBulb(
          sandCellCount: bottomFullCells,
          totalCellCount: totalGridCells,
          isTop: false,
        ),
      ],
    );
  }
}

// A widget to render one bulb (top or bottom) of the hourglass.
class _PixelBulb extends StatelessWidget {
  const _PixelBulb({
    required this.sandCellCount,
    required this.totalCellCount,
    required this.isTop,
  });

  final int sandCellCount;
  final int totalCellCount;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    // Use a fixed-size container to hold the grid.
    return Container(
      width: 200,
      height: 200,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling
        itemCount: totalCellCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, // 8x8 grid
        ),
        itemBuilder: (context, index) {
          bool isFull;

          if (isTop) {
            // In the top bulb, sand drains from the bottom.
            // We fill pixels from the top down.
            isFull = index < sandCellCount;
          } else {
            // In the bottom bulb, sand fills from the bottom up.
            isFull = index >= (totalCellCount - sandCellCount);
          }

          return _Pixel(isFull: isFull);
        },
      ),
    );
  }
}

// A single "pixel" in our grid.
class _Pixel extends StatelessWidget {
  const _Pixel({required this.isFull});

  final bool isFull;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.5), // Creates the grid line effect
      decoration: BoxDecoration(
        color: isFull
            ? Colors.white
            : const Color(0xFF222222), // "On" vs "Off"
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}