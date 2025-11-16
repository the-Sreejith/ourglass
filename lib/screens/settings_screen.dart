import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ourglass/providers/settings_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showColorPicker(
    BuildContext context,
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ColorOption(
                  color: Colors.white,
                  label: 'White',
                  isSelected: currentColor == Colors.white,
                  onTap: () {
                    onColorChanged(Colors.white);
                    Navigator.pop(context);
                  },
                ),
                _ColorOption(
                  color: Colors.amber,
                  label: 'Amber',
                  isSelected: currentColor == Colors.amber,
                  onTap: () {
                    onColorChanged(Colors.amber);
                    Navigator.pop(context);
                  },
                ),
                _ColorOption(
                  color: Colors.orange,
                  label: 'Orange',
                  isSelected: currentColor == Colors.orange,
                  onTap: () {
                    onColorChanged(Colors.orange);
                    Navigator.pop(context);
                  },
                ),
                _ColorOption(
                  color: Colors.red,
                  label: 'Red',
                  isSelected: currentColor == Colors.red,
                  onTap: () {
                    onColorChanged(Colors.red);
                    Navigator.pop(context);
                  },
                ),
                _ColorOption(
                  color: Colors.blue,
                  label: 'Blue',
                  isSelected: currentColor == Colors.blue,
                  onTap: () {
                    onColorChanged(Colors.blue);
                    Navigator.pop(context);
                  },
                ),
                _ColorOption(
                  color: Colors.green,
                  label: 'Green',
                  isSelected: currentColor == Colors.green,
                  onTap: () {
                    onColorChanged(Colors.green);
                    Navigator.pop(context);
                  },
                ),
                _ColorOption(
                  color: Colors.purple,
                  label: 'Purple',
                  isSelected: currentColor == Colors.purple,
                  onTap: () {
                    onColorChanged(Colors.purple);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<HourglassSettings>(
        builder: (context, settings, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text(
                  'Sound When Timer Finishes',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Play sound when timer completes',
                  style: TextStyle(color: Colors.grey),
                ),
                value: settings.soundEnabled,
                onChanged: (bool value) {
                  settings.updateSoundEnabled(value);
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.grey[600],
              ),
              SwitchListTile(
                title: const Text(
                  'Start Timer in Tilted Angles',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Allow timer to start even when device is tilted',
                  style: TextStyle(color: Colors.grey),
                ),
                value: settings.startInTiltedAngles,
                onChanged: (bool value) {
                  settings.updateStartInTiltedAngles(value);
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.grey[600],
              ),
              SwitchListTile(
                title: const Text(
                  'Show Start/Pause and Reset Buttons',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Display control buttons on the hourglass screen',
                  style: TextStyle(color: Colors.grey),
                ),
                value: settings.showButtons,
                onChanged: (bool value) {
                  settings.updateShowButtons(value);
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.grey[600],
              ),
              ListTile(
                title: const Text(
                  'Default Timer Value',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${settings.totalDurationInSeconds.round()} seconds',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  _showTimerPicker(context, settings);
                },
              ),
              ListTile(
                title: const Text(
                  'Sand Color',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Color of the hourglass sand',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: settings.sandColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                onTap: () {
                  _showColorPicker(
                    context,
                    'Sand Color',
                    settings.sandColor,
                    (color) => settings.updateSandColor(color),
                  );
                },
              ),
              ListTile(
                title: const Text(
                  'Empty Cell Color',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Color of empty hourglass cells',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: settings.emptyColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                onTap: () {
                  _showColorPicker(
                    context,
                    'Empty Cell Color',
                    settings.emptyColor,
                    (color) => settings.updateEmptyColor(color),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTimerPicker(BuildContext context, HourglassSettings settings) {
    Duration currentDuration = Duration(
      seconds: settings.totalDurationInSeconds.round(),
    );
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Duration newDuration = currentDuration;
            return AlertDialog(
              title: const Text('Default Timer Value'),
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
                    double newTime = newDuration.inSeconds.toDouble();
                    if (newTime < 1.0) newTime = 1.0;
                    settings.updateDuration(newTime);
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
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}
