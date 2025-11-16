import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ourglass/screens/settings_screen.dart';
import 'package:ourglass/services/sensor_service.dart';
import 'package:ourglass/providers/settings_provider.dart';
import 'package:ourglass/widgets/pixel_hourglass.dart';

class HourglassPage extends StatefulWidget {
  const HourglassPage({super.key});

  @override
  State<HourglassPage> createState() => _HourglassPageState();
}

class _HourglassPageState extends State<HourglassPage> {
  final SensorService _sensorService = SensorService();
  StreamSubscription? _sensorSubscription;
  Timer? _sandTimer;

  // 0 = tilted, 1 = upright, -1 = upside down
  int _orientation = 0;
  bool _isFlowing = false;
  bool _isManuallyPaused = false;
  bool _hasPlayedSound = false;

  static const int _totalSand = 100;
  static const int _gridCells = 64;

  double _totalDurationInSeconds =
      15.0; // Local state, initialized from provider
  late Duration _sandTickDuration;
  double _timeLeftInSeconds = 0.0;

  int _topSand = _totalSand;
  int _bottomSand = 0;

  @override
  void initState() {
    super.initState();
    // Initialize local state from the pre-loaded provider
    final settings = context.read<HourglassSettings>();
    _totalDurationInSeconds = settings.totalDurationInSeconds;

    _timeLeftInSeconds = _totalDurationInSeconds;
    _updateTickDuration();

    _sensorService.start();
    _sensorSubscription = _sensorService.orientationStream.listen(
      _handleOrientationChange,
    );

    // Listen to settings changes
    settings.addListener(_onSettingsChanged);

    _startFlow();
  }

  void _onSettingsChanged() {
    final settings = context.read<HourglassSettings>();
    if (settings.totalDurationInSeconds != _totalDurationInSeconds) {
      setState(() {
        _totalDurationInSeconds = settings.totalDurationInSeconds;
        _updateTickDuration();
      });
    }
  }

  @override
  void dispose() {
    final settings = context.read<HourglassSettings>();
    settings.removeListener(_onSettingsChanged);
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

  // Updated to handle int (1, -1, 0) instead of enum
  void _handleOrientationChange(int newOrientation) {
    if (newOrientation == _orientation) return;

    final settings = context.read<HourglassSettings>();

    setState(() {
      _orientation = newOrientation;
    });

    if (_orientation == 1 && _topSand == 0) {
      _flipSand();
    } else if (_orientation == -1 && _bottomSand == 0) {
      _flipSand();
    }

    // 1 = upright, -1 = upsideDown, 0 = tilted
    if (_orientation == 1 || _orientation == -1) {
      if (!_isManuallyPaused) {
        _startFlow();
      }
    } else {
      // Only stop if tilted angles are not allowed
      if (!settings.startInTiltedAngles) {
        _stopFlow();
      } else if (!_isManuallyPaused) {
        // If tilted angles are allowed, keep flowing
        _startFlow();
      }
    }
  }

  void _flipSand() {
    setState(() {
      int temp = _topSand;
      _topSand = _bottomSand;
      _bottomSand = temp;

      // 1 = upright
      int activeSand = (_orientation == 1) ? _topSand : _bottomSand;
      if (activeSand == 0) {
        _timeLeftInSeconds = 0.0;
      } else {
        _timeLeftInSeconds =
            _totalDurationInSeconds * (activeSand / _totalSand);
      }

      // Reset sound flag when flipping (new timer cycle)
      _hasPlayedSound = false;
    });
  }

  void _startFlow() {
    if (_isFlowing || _isManuallyPaused) return;

    final settings = context.read<HourglassSettings>();

    // Check orientation requirements
    if (!settings.startInTiltedAngles && _orientation == 0) {
      return;
    }

    if (_orientation == 1 && _topSand == 0) {
      // Timer finished, reset sound flag for next run
      _hasPlayedSound = false;
      return;
    }
    if (_orientation == -1 && _bottomSand == 0) {
      // Timer finished, reset sound flag for next run
      _hasPlayedSound = false;
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

    if (_orientation == 1) {
      // Upright
      if (_topSand > 0) {
        _topSand--;
        _bottomSand++;
        activeSand = _topSand;
        isFlowing = true;
      }
    } else if (_orientation == -1) {
      // Upside Down
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

      // Play sound when timer finishes
      final settings = context.read<HourglassSettings>();
      if (settings.soundEnabled && !_hasPlayedSound) {
        _hasPlayedSound = true;
        SystemSound.play(SystemSoundType.alert);
      }
    }
  }

  void _togglePause() {
    setState(() {
      _isManuallyPaused = !_isManuallyPaused;
      if (_isManuallyPaused) {
        _stopFlow();
      } else {
        _startFlow();
      }
    });
  }

  void _resetTimer() {
    final settings = context.read<HourglassSettings>();
    setState(() {
      // Use current settings value for duration
      _totalDurationInSeconds = settings.totalDurationInSeconds;
      _updateTickDuration();

      _topSand = _totalSand;
      _bottomSand = 0;
      _timeLeftInSeconds = _totalDurationInSeconds;
      _hasPlayedSound = false;
      _isManuallyPaused = false;
      _stopFlow();

      // Restart if orientation allows
      if (_orientation == 1 || _orientation == -1) {
        _startFlow();
      } else if (settings.startInTiltedAngles) {
        _startFlow();
      }
    });
  }

  String _formatTime(double seconds) {
    int totalSeconds = seconds.ceil();
    if (totalSeconds < 0) totalSeconds = 0;

    int min = totalSeconds ~/ 60;
    int sec = totalSeconds % 60;

    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  void _showTimeEditDialog() {
    // Use the current local state to initialize the picker
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
                    // 1. Get the provider (but don't listen)
                    final settings = context.read<HourglassSettings>();

                    double newTime = newDuration.inSeconds.toDouble();
                    if (newTime < 1.0) newTime = 1.0;

                    // 2. Update and save the preference via the provider
                    settings.updateDuration(newTime);

                    // 3. Update the local state to reset the timer
                    setState(() {
                      _totalDurationInSeconds = newTime;
                      _updateTickDuration();

                      _topSand = _totalSand;
                      _bottomSand = 0;
                      _timeLeftInSeconds = _totalDurationInSeconds;

                      _stopFlow();
                      if (_orientation == 1 || _orientation == -1) {
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

    return Consumer<HourglassSettings>(
      builder: (context, settings, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
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
                  orientation: _orientation,
                  isFalling: _isFlowing,
                  sandColor: settings.sandColor,
                  emptyColor: settings.emptyColor,
                ),
                if (settings.showButtons) ...[
                  const SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isManuallyPaused ? Icons.play_arrow : Icons.pause,
                          size: 32,
                        ),
                        color: Colors.white,
                        onPressed: _togglePause,
                      ),
                      const SizedBox(width: 80),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 32),
                        color: Colors.white,
                        onPressed: _resetTimer,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
