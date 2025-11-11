// hourglass_screen.dart
import 'package:flutter/material.dart';
import 'sensor_service.dart';
import 'dart:async';

class HourglassScreen extends StatefulWidget {
  const HourglassScreen({Key? key}) : super(key: key);

  @override
  State<HourglassScreen> createState() => _HourglassScreenState();
}

class _HourglassScreenState extends State<HourglassScreen> {
  final SensorService _sensorService = SensorService();

  // Grid dimensions (matching the image pattern)
  static const int gridSize = 50;
  static const int totalPixels = gridSize * gridSize;

  List<List<bool>> topGrid = [];
  List<List<bool>> bottomGrid = [];

  int _remainingSeconds = 60;
  Timer? _countdownTimer;
  Timer? _sandFlowTimer;
  bool _isFlowing = false;
  bool _isPaused = false;
  double _currentDirection = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeGrids();
    _sensorService.startListening(_onTiltChanged);
  }

  void _initializeGrids() {
    // Fill top grid completely
    topGrid = List.generate(
      gridSize,
      (i) => List.generate(gridSize, (j) => true),
    );

    // Empty bottom grid
    bottomGrid = List.generate(
      gridSize,
      (i) => List.generate(gridSize, (j) => false),
    );
  }

  void _onTiltChanged(double direction, bool isFlowing) {
    setState(() {
      _currentDirection = direction;
      _isFlowing = isFlowing;

      if (isFlowing && !_isPaused) {
        if (_countdownTimer == null || !_countdownTimer!.isActive) {
          _startTimer();
        }
        if (_sandFlowTimer == null || !_sandFlowTimer!.isActive) {
          _startSandFlow(direction > 0);
        }
      } else {
        _sandFlowTimer?.cancel();
        _sandFlowTimer = null;
      }
    });
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _countdownTimer?.cancel();
          _sandFlowTimer?.cancel();
          _isPaused = true;
        }
      });
    });
  }

  void _startSandFlow(bool topToBottom) {
    _sandFlowTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPaused && _isFlowing) {
        setState(() {
          _flowSand(topToBottom);
        });
      }
    });
  }

  void _flowSand(bool topToBottom) {
    if (topToBottom) {
      // Flow from top to bottom
      int topCount = _countFilledPixels(topGrid);
      int bottomCount = _countFilledPixels(bottomGrid);

      if (topCount > 0 && bottomCount < totalPixels) {
        _removePixelFromGrid(topGrid);
        _addPixelToGrid(bottomGrid);
      }
    } else {
      // Flow from bottom to top
      int bottomCount = _countFilledPixels(bottomGrid);
      int topCount = _countFilledPixels(topGrid);

      if (bottomCount > 0 && topCount < totalPixels) {
        _removePixelFromGrid(bottomGrid);
        _addPixelToGrid(topGrid);
      }
    }
  }

  int _countFilledPixels(List<List<bool>> grid) {
    int count = 0;
    for (var row in grid) {
      for (var pixel in row) {
        if (pixel) count++;
      }
    }
    return count;
  }

  void _removePixelFromGrid(List<List<bool>> grid) {
    // Remove from bottom up (gravity effect)
    for (int i = gridSize - 1; i >= 0; i--) {
      for (int j = gridSize - 1; j >= 0; j--) {
        if (grid[i][j]) {
          grid[i][j] = false;
          return;
        }
      }
    }
  }

  void _addPixelToGrid(List<List<bool>> grid) {
    // Add from bottom up (gravity effect)
    for (int i = gridSize - 1; i >= 0; i--) {
      for (int j = 0; j < gridSize; j++) {
        if (!grid[i][j]) {
          grid[i][j] = true;
          return;
        }
      }
    }
  }

  void _reset() {
    setState(() {
      _initializeGrids();
      _remainingSeconds = 60;
      _isPaused = false;
      _currentDirection = 0.0;
      _countdownTimer?.cancel();
      _countdownTimer = null;
      _sandFlowTimer?.cancel();
      _sandFlowTimer = null;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _countdownTimer?.cancel();
        _sandFlowTimer?.cancel();
      } else if (_isFlowing) {
        _startTimer();
        _startSandFlow(_currentDirection > 0);
      }
    });
  }

  @override
  void dispose() {
    _sensorService.dispose();
    _countdownTimer?.cancel();
    _sandFlowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isPaused
                    ? 'PAUSED'
                    : (_isFlowing ? 'FLOWING...' : 'TILT TO START'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isFlowing ? Colors.greenAccent : Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              // const SizedBox(height: 10),
              // Direction indicator
              // Text(
              //   'Direction: ${_currentDirection.toStringAsFixed(2)}',
              //   style: TextStyle(
              //     fontSize: 14,
              //     color: Colors.white60,
              //     fontFamily: 'monospace',
              //   ),
              // ),
              const SizedBox(height: 20),
              _buildPixelatedHourglass(),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(_isPaused ? 'Resume' : 'Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPixelatedHourglass() {
    const double pixelSize = 5.0;
    const double pixelGap = 0.5;
    const double neckHeight = 40.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top grid
        _buildPixelGrid(topGrid, pixelSize, pixelGap),

        // Neck/connector
        Container(
          width: pixelSize * 2,
          height: neckHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
          ),
          child: _isFlowing && !_isPaused
              ? Center(
                  child: Container(
                    width: 4,
                    height: neckHeight,
                    color: Colors.white,
                  ),
                )
              : null,
        ),

        // Bottom grid
        _buildPixelGrid(bottomGrid, pixelSize, pixelGap),
      ],
    );
  }

  Widget _buildPixelGrid(
    List<List<bool>> grid,
    double pixelSize,
    double pixelGap,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: List.generate(gridSize, (i) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(gridSize, (j) {
              return Container(
                width: pixelSize,
                height: pixelSize,
                margin: EdgeInsets.all(pixelGap / 2),
                decoration: BoxDecoration(
                  color: grid[i][j]
                      ? Colors.white
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: grid[i][j]
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
