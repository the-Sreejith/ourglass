import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

  static const int _totalSand = 100;
  static const int _gridCells = 64;

  double _totalDurationInSeconds = 15.0;
  late Duration _sandTickDuration;
  double _timeLeftInSeconds = 0.0;

  int _topSand = _totalSand;
  int _bottomSand = 0;

  @override
  void initState() {
    super.initState();
    _timeLeftInSeconds = _totalDurationInSeconds;
    _updateTickDuration();

    _sensorService.start();
    _sensorSubscription = _sensorService.orientationStream.listen(
      _handleOrientationChange,
    );

    _startFlow();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _sensorService.dispose();
    _sandTimer?.cancel();
    super.dispose();
  }

  void _updateTickDuration() {
    if (_totalDurationInSeconds < 1) _totalDurationInSeconds = 1;

    final int tickMillis = (_totalDurationInSeconds * 1000) ~/ _totalSand;

    _sandTickDuration = Duration(milliseconds: tickMillis > 0 ? tickMillis : 1);

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

    if (_orientation == DeviceOrientation.upright && _topSand == 0) {
      _flipSand();
    } else if (_orientation == DeviceOrientation.upsideDown &&
        _bottomSand == 0) {
      _flipSand();
    }

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

      int activeSand = (_orientation == DeviceOrientation.upright)
          ? _topSand
          : _bottomSand;
      if (activeSand == 0) {
        _timeLeftInSeconds = 0.0;
      } else {
        _timeLeftInSeconds =
            _totalDurationInSeconds * (activeSand / _totalSand);
      }
    });
  }

  void _startFlow() {
    if (_isFlowing) return;

    if (_orientation == DeviceOrientation.upright && _topSand == 0) return;
    if (_orientation == DeviceOrientation.upsideDown && _bottomSand == 0) {
      return;
    }

    _isFlowing = true;

    _sandTimer = Timer.periodic(_sandTickDuration, _tick);
  }

  void _stopFlow() {
    _sandTimer?.cancel();
    _isFlowing = false;
  }

  void _tick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    bool isFlowing = false;
    int activeSand = 0;

    if (_orientation == DeviceOrientation.upright) {
      if (_topSand > 0) {
        _topSand--;
        _bottomSand++;
        activeSand = _topSand;
        isFlowing = true;
      }
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
      _stopFlow();
      setState(() {
        _timeLeftInSeconds = 0.0;
      });
    }
  }

  String _formatTime(double seconds) {
    int totalSeconds = seconds.ceil();
    if (totalSeconds < 0) totalSeconds = 0;

    int min = totalSeconds ~/ 60;
    int sec = totalSeconds % 60;

    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showTimeEditDialog() {
    Duration newDuration = Duration(seconds: _totalDurationInSeconds.round());
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Set Hourglass Time'),
              contentPadding: const EdgeInsets.only(top: 12.0),
              content: SizedBox(
                height: 180,
                width: double.maxFinite,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.ms,
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
                      if (newTime < 1.0) newTime = 1.0;

                      _totalDurationInSeconds = newTime;
                      _updateTickDuration();

                      _topSand = _totalSand;
                      _bottomSand = 0;
                      _timeLeftInSeconds = _totalDurationInSeconds;

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
    double topFraction = _topSand / _totalSand;
    double bottomFraction = _bottomSand / _totalSand;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showTimeEditDialog,
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            GestureDetector(
              onTap: _showTimeEditDialog,
              child: Text(
                _formatTime(_timeLeftInSeconds),
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.w200,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 80),
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

class PixelHourglass extends StatelessWidget {
  const PixelHourglass({
    super.key,
    required this.topSandFraction,
    required this.bottomSandFraction,
    required this.totalGridCells
  });

  final double topSandFraction;
  final double bottomSandFraction;
  final int totalGridCells;

  @override
  Widget build(BuildContext context) {
    final int topFullCells = (topSandFraction * totalGridCells).round();
    final int bottomFullCells = (bottomSandFraction * totalGridCells).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PixelBulb(
          key: const ValueKey('top'),
          sandCellCount: topFullCells,
          totalCellCount: totalGridCells,
          isTop: false,
        ),

        const SizedBox(height: 90),

        _PixelBulb(
          key: const ValueKey('bottom'),
          sandCellCount: bottomFullCells,
          totalCellCount: totalGridCells,
          isTop: true,
        ),
      ],
    );
  }
}

class _PixelBulb extends StatelessWidget {
  const _PixelBulb({
    super.key,
    required this.sandCellCount,
    required this.totalCellCount,
    required this.isTop,
  });

  final int sandCellCount;
  final int totalCellCount;
  final bool isTop;

  static final Map<int, int> _fillOrderMap = _buildFillOrderMap();

  static Map<int, int> _buildFillOrderMap() {
    const int gridWidth = 8;
    const int totalCells = 64;
    List<int> sortedIndices = List.generate(totalCells, (i) => i);
    sortedIndices.sort((a, b) {
      int levelA = (a ~/ gridWidth) + (a % gridWidth);
      int levelB = (b ~/ gridWidth) + (b % gridWidth);
      if (levelA != levelB) {
        return levelA.compareTo(levelB);
      } else {
        return (a ~/ gridWidth).compareTo(b ~/ gridWidth);
      }
    });

    final Map<int, int> map = {};
    for (int i = 0; i < sortedIndices.length; i++) {
      map[sortedIndices[i]] = i;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: pi / 4,
      child: Container(
        width: 200,
        height: 200,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemBuilder: (context, index) {
            final int fillPriority = _fillOrderMap[index]!;
            final bool isFull =
                fillPriority >= (totalCellCount - sandCellCount);
            return _Pixel(isFull: !isFull);
          },
        ),
      ),
    );
  }
}

class _Pixel extends StatelessWidget {
  const _Pixel({required this.isFull});

  final bool isFull;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: isFull ? Colors.white : const Color(0xFF222222),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
