import 'package:flutter/material.dart';
import 'dart:math' as math;

class WellnessPopup extends StatelessWidget {
  const WellnessPopup({super.key});

  static const List<Map<String, String>> _wellnessTips = [
    {
      'title': 'Hydrate',
      'description': 'Drink a glass of water to stay refreshed',
    },
    {
      'title': 'Deep Breathing',
      'description': 'Take 3 deep breaths to reset your mind',
    },
    {
      'title': 'Quick Walk',
      'description': 'Take a 2-minute walk to get your blood flowing',
    },
    {
      'title': 'Eye Rest',
      'description': 'Look away from your screen and focus on something distant',
    },
    {
      'title': 'Stretch',
      'description': 'Do some light stretches to relieve tension',
    },
    {
      'title': 'Healthy Snack',
      'description': 'Grab a nutritious snack to fuel your brain',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final randomTip = _wellnessTips[math.Random().nextInt(_wellnessTips.length)];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Break Time!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.self_improvement,
                    size: 48,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    randomTip['title']!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    randomTip['description']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip Break'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _startBreakTimer(context);
                    },
                    child: const Text('Start Break'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startBreakTimer(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _BreakTimerDialog(),
    );
  }
}

class _BreakTimerDialog extends StatefulWidget {
  const _BreakTimerDialog();

  @override
  State<_BreakTimerDialog> createState() => _BreakTimerDialogState();
}

class _BreakTimerDialogState extends State<_BreakTimerDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  Duration _remainingTime = const Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _remainingTime,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onBreakComplete();
      }
    });

    _animationController.forward();
    _startCountdown();
  }

  void _startCountdown() {
    Stream.periodic(const Duration(seconds: 1), (i) => i).listen((count) {
      if (mounted) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });

        if (_remainingTime.inSeconds <= 0) {
          _onBreakComplete();
        }
      }
    });
  }

  void _onBreakComplete() {
    if (mounted) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Break Complete!'),
          content: const Text('Time to get back to focusing!'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Break in Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _animationController.value,
                        strokeWidth: 8,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(_remainingTime),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        Text(
                          'remaining',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('End Break Early'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}