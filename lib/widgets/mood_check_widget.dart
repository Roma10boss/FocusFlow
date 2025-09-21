import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mood_provider.dart';

class MoodCheckWidget extends StatefulWidget {
  const MoodCheckWidget({super.key});

  @override
  State<MoodCheckWidget> createState() => _MoodCheckWidgetState();
}

class _MoodCheckWidgetState extends State<MoodCheckWidget> {
  int? _selectedMood;

  @override
  void initState() {
    super.initState();
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    _selectedMood = moodProvider.todayMood?.moodLevel;
  }

  void _selectMood(int mood) {
    setState(() {
      _selectedMood = mood;
    });

    Provider.of<MoodProvider>(context, listen: false).updateTodayMood(mood, null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mood updated to ${_getMoodLabel(mood)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😊';
      case 4:
        return '😄';
      default:
        return '😊';
    }
  }

  String _getMoodLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Happy';
      case 4:
        return 'Very Happy';
      default:
        return 'Happy';
    }
  }

  String _getMoodShortLabel(int mood) {
    switch (mood) {
      case 1:
        return 'Down';
      case 2:
        return 'Low';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      default:
        return 'Good';
    }
  }

  String _getMoodSuggestion(int mood) {
    switch (mood) {
      case 1:
        return 'Take it easy today. Try shorter 15-min sessions with extra breaks.';
      case 2:
        return 'Start with something simple to build momentum. You\'ve got this!';
      case 3:
        return 'Perfect for steady focus. Try a standard 25-minute session.';
      case 4:
        return 'Great energy! This is perfect for tackling challenging tasks.';
      default:
        return 'Ready to focus and be productive?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            final mood = index + 1;
            final isSelected = _selectedMood == mood;

            return GestureDetector(
              onTap: () => _selectMood(mood),
              child: AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 150), // Optimized for 120Hz
                curve: Curves.easeOutQuart, // Smooth curve for high refresh rate
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200), // Faster for 120Hz
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getMoodEmoji(mood),
                        style: TextStyle(
                          fontSize: isSelected ? 28 : 24,
                          height: 1.0, // Normalize line height
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getMoodShortLabel(mood),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.0, // Normalize line height
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200), // Optimized for 120Hz
          switchInCurve: Curves.easeOutQuart,
          switchOutCurve: Curves.easeInQuart,
          child: _selectedMood != null
              ? Container(
                  key: ValueKey(_selectedMood),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Feeling ${_getMoodLabel(_selectedMood!).toLowerCase()}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMoodSuggestion(_selectedMood!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Container(
                  key: const ValueKey('empty'),
                  height: 50,
                  child: Center(
                    child: Text(
                      'Tap an emoji to log your mood',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}