import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/focus_provider.dart';
import '../widgets/circular_timer.dart';
import '../widgets/wellness_popup.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  Timer? _timer;
  Duration _remainingTime = const Duration(minutes: 25);

  @override
  void initState() {
    super.initState();
    _remainingTime = Provider.of<FocusProvider>(context, listen: false).sessionDuration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    final focusProvider = Provider.of<FocusProvider>(context, listen: false);
    focusProvider.startSession();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    Provider.of<FocusProvider>(context, listen: false).pauseSession();
  }

  void _resumeTimer() {
    Provider.of<FocusProvider>(context, listen: false).resumeSession();
    _startTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    Provider.of<FocusProvider>(context, listen: false).endSession();
    setState(() {
      _remainingTime = Provider.of<FocusProvider>(context, listen: false).sessionDuration;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    final focusProvider = Provider.of<FocusProvider>(context, listen: false);

    if (focusProvider.currentSession?.isBreak == false) {
      // Focus session completed, start break
      focusProvider.startBreak();
      setState(() {
        _remainingTime = focusProvider.breakDuration;
      });
      _showWellnessBreak();
    } else {
      // Break completed
      focusProvider.endSession();
      setState(() {
        _remainingTime = focusProvider.sessionDuration;
      });
      _showSessionComplete();
    }
  }

  void _showWellnessBreak() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WellnessPopup(),
    );
  }

  void _showSessionComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete!'),
        content: const Text('Great job! You\'ve completed a focus session.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startTimer();
            },
            child: const Text('Start Another'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Consumer<FocusProvider>(
        builder: (context, focusProvider, child) {
          final isSessionActive = focusProvider.isSessionActive;
          final currentSession = focusProvider.currentSession;
          final isBreak = currentSession?.isBreak ?? false;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isBreak
                    ? [
                        Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        Theme.of(context).colorScheme.surface,
                      ]
                    : [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).colorScheme.surface,
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isBreak ? 'Break Time' : 'Focus Time',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isBreak
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isBreak
                        ? 'Take a moment to relax and recharge'
                        : 'Stay focused and minimize distractions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  CircularTimer(
                    remainingTime: _remainingTime,
                    totalTime: isBreak
                        ? focusProvider.breakDuration
                        : focusProvider.sessionDuration,
                    isBreak: isBreak,
                  ),
                  const SizedBox(height: 48),
                  _buildTimerControls(isSessionActive),
                  const SizedBox(height: 32),
                  _buildStats(focusProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerControls(bool isSessionActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!isSessionActive)
          ElevatedButton.icon(
            onPressed: _startTimer,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          )
        else ...[
          ElevatedButton.icon(
            onPressed: _pauseTimer,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _stopTimer,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStats(FocusProvider focusProvider) {
    final totalFocusTime = focusProvider.getTotalFocusTimeToday();
    final completedSessions = focusProvider.sessions
        .where((s) => !s.isBreak && s.isCompleted)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Today\'s Focus',
              '${totalFocusTime.inMinutes}m',
              Icons.timer,
              Colors.blue.shade600,
            ),
            _buildStatItem(
              'Sessions',
              '$completedSessions',
              Icons.check_circle,
              Colors.green.shade600,
            ),
            _buildStatItem(
              'Streak',
              '3',
              Icons.local_fire_department,
              Colors.deepOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? iconColor]) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<FocusProvider>(
        builder: (context, focusProvider, child) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timer Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Focus Duration'),
                subtitle: Text('${focusProvider.sessionDuration.inMinutes} minutes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDurationPicker(
                  context,
                  'Focus Duration',
                  focusProvider.sessionDuration,
                  focusProvider.setSessionDuration,
                ),
              ),
              ListTile(
                title: const Text('Break Duration'),
                subtitle: Text('${focusProvider.breakDuration.inMinutes} minutes'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDurationPicker(
                  context,
                  'Break Duration',
                  focusProvider.breakDuration,
                  focusProvider.setBreakDuration,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDurationPicker(
    BuildContext context,
    String title,
    Duration currentDuration,
    Function(Duration) onChanged,
  ) {
    int minutes = currentDuration.inMinutes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$minutes minutes'),
              Slider(
                value: minutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                onChanged: (value) {
                  setState(() {
                    minutes = value.round();
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onChanged(Duration(minutes: minutes));
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}