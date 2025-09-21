import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/student_schedule.dart';
import '../widgets/glass_card.dart';

class WeeklyStudyPreferencesScreen extends StatefulWidget {
  const WeeklyStudyPreferencesScreen({super.key});

  @override
  State<WeeklyStudyPreferencesScreen> createState() => _WeeklyStudyPreferencesScreenState();
}

class _WeeklyStudyPreferencesScreenState extends State<WeeklyStudyPreferencesScreen> {
  // Map to store preferred study times for each day (1=Monday, 7=Sunday)
  Map<int, List<StudyTimeSlot>> weeklyPreferences = {};

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  void _initializePreferences() {
    // Initialize with empty preferences for all days
    for (int day = 1; day <= 7; day++) {
      weeklyPreferences[day] = [];
    }

    // Load existing preferences if any
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final existingWindows = scheduleProvider.schedule.freeTimeWindows;

    existingWindows.forEach((day, times) {
      weeklyPreferences[day] = times.map((time) => StudyTimeSlot(
        startTime: time,
        endTime: _addHoursToTime(time, 1), // Default 1 hour sessions
        isPreferred: true,
      )).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Study Schedule'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: _savePreferences,
            icon: const Icon(Icons.save),
            tooltip: 'Save Preferences',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set Your Study Times',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us when you prefer to study each day. We\'ll create your study plan around these times and avoid scheduling during your busy periods.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...List.generate(7, (index) {
                final day = index + 1; // 1=Monday, 7=Sunday
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildDayPreferences(day),
                );
              }),
              const SizedBox(height: 16),
              _buildQuickSetupButtons(),
              const SizedBox(height: 24),
              _buildPreviewCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateStudyPlan,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate Plan'),
      ),
    );
  }

  Widget _buildDayPreferences(int day) {
    final dayName = _getDayName(day);
    final dayPreferences = weeklyPreferences[day] ?? [];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _addStudyTime(day),
                icon: const Icon(Icons.add_circle_outline),
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dayPreferences.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No study times set for ${dayName.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: dayPreferences.asMap().entries.map((entry) {
                final index = entry.key;
                final timeSlot = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildTimeSlotCard(day, index, timeSlot),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotCard(int day, int index, StudyTimeSlot timeSlot) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _editTimeSlot(day, index, timeSlot),
              child: Text(
                '${_formatTime(timeSlot.startTime)} - ${_formatTime(timeSlot.endTime)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          Text(
            '${timeSlot.duration.inMinutes} min',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeTimeSlot(day, index),
            icon: const Icon(Icons.close),
            iconSize: 18,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetupButtons() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Setup',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickSetupButton(
                'Morning Person',
                'Add 7-9 AM slots',
                () => _applyQuickSetup('morning'),
              ),
              _buildQuickSetupButton(
                'Afternoon Study',
                'Add 2-4 PM slots',
                () => _applyQuickSetup('afternoon'),
              ),
              _buildQuickSetupButton(
                'Evening Study',
                'Add 6-8 PM slots',
                () => _applyQuickSetup('evening'),
              ),
              _buildQuickSetupButton(
                'Flexible Schedule',
                'Multiple time slots',
                () => _applyQuickSetup('flexible'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetupButton(String title, String subtitle, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final totalSlots = weeklyPreferences.values.fold<int>(
      0, (sum, slots) => sum + slots.length,
    );
    final totalHours = weeklyPreferences.values.fold<int>(
      0, (sum, slots) => sum + slots.fold<int>(0, (slotSum, slot) => slotSum + slot.duration.inMinutes),
    );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$totalSlots',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Study Slots',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${(totalHours / 60).toStringAsFixed(1)}h',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Per Week',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${(totalHours / (7 * 60)).toStringAsFixed(1)}h',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Per Day',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          if (totalSlots > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Perfect! You\'re ready to generate a personalized study plan.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addStudyTime(int day) {
    showDialog(
      context: context,
      builder: (context) => _TimePickerDialog(
        onTimeSelected: (startTime, endTime) {
          setState(() {
            weeklyPreferences[day]!.add(StudyTimeSlot(
              startTime: startTime,
              endTime: endTime,
              isPreferred: true,
            ));
          });
        },
      ),
    );
  }

  void _editTimeSlot(int day, int index, StudyTimeSlot currentSlot) {
    showDialog(
      context: context,
      builder: (context) => _TimePickerDialog(
        initialStartTime: currentSlot.startTime,
        initialEndTime: currentSlot.endTime,
        onTimeSelected: (startTime, endTime) {
          setState(() {
            weeklyPreferences[day]![index] = StudyTimeSlot(
              startTime: startTime,
              endTime: endTime,
              isPreferred: true,
            );
          });
        },
      ),
    );
  }

  void _removeTimeSlot(int day, int index) {
    setState(() {
      weeklyPreferences[day]!.removeAt(index);
    });
  }

  void _applyQuickSetup(String type) {
    setState(() {
      switch (type) {
        case 'morning':
          for (int day = 1; day <= 7; day++) {
            weeklyPreferences[day] = [
              StudyTimeSlot(
                startTime: const TimeOfDay(hour: 7, minute: 0),
                endTime: const TimeOfDay(hour: 9, minute: 0),
                isPreferred: true,
              ),
            ];
          }
          break;
        case 'afternoon':
          for (int day = 1; day <= 7; day++) {
            weeklyPreferences[day] = [
              StudyTimeSlot(
                startTime: const TimeOfDay(hour: 14, minute: 0),
                endTime: const TimeOfDay(hour: 16, minute: 0),
                isPreferred: true,
              ),
            ];
          }
          break;
        case 'evening':
          for (int day = 1; day <= 7; day++) {
            weeklyPreferences[day] = [
              StudyTimeSlot(
                startTime: const TimeOfDay(hour: 18, minute: 0),
                endTime: const TimeOfDay(hour: 20, minute: 0),
                isPreferred: true,
              ),
            ];
          }
          break;
        case 'flexible':
          for (int day = 1; day <= 7; day++) {
            weeklyPreferences[day] = [
              StudyTimeSlot(
                startTime: const TimeOfDay(hour: 9, minute: 0),
                endTime: const TimeOfDay(hour: 11, minute: 0),
                isPreferred: true,
              ),
              StudyTimeSlot(
                startTime: const TimeOfDay(hour: 15, minute: 0),
                endTime: const TimeOfDay(hour: 17, minute: 0),
                isPreferred: true,
              ),
            ];
          }
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quick setup applied! You can still customize individual days.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _savePreferences() {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);

    // Convert StudyTimeSlot to TimeOfDay for the schedule provider
    weeklyPreferences.forEach((day, timeSlots) {
      final times = timeSlots.map((slot) => slot.startTime).toList();
      scheduleProvider.setFreeTimeWindows(day, times);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Study preferences saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _generateStudyPlan() {
    _savePreferences(); // Save first

    Navigator.of(context).pushNamed('/study-planner');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Study Planner to generate your personalized plan!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _getDayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  TimeOfDay _addHoursToTime(TimeOfDay time, int hours) {
    final totalMinutes = time.hour * 60 + time.minute + (hours * 60);
    return TimeOfDay(hour: (totalMinutes ~/ 60) % 24, minute: totalMinutes % 60);
  }
}

class StudyTimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isPreferred;

  StudyTimeSlot({
    required this.startTime,
    required this.endTime,
    this.isPreferred = true,
  });

  Duration get duration {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return Duration(minutes: endMinutes - startMinutes);
  }
}

class _TimePickerDialog extends StatefulWidget {
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final Function(TimeOfDay startTime, TimeOfDay endTime) onTimeSelected;

  const _TimePickerDialog({
    this.initialStartTime,
    this.initialEndTime,
    required this.onTimeSelected,
  });

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  @override
  void initState() {
    super.initState();
    startTime = widget.initialStartTime ?? const TimeOfDay(hour: 9, minute: 0);
    endTime = widget.initialEndTime ?? const TimeOfDay(hour: 11, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Study Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: Text('Start Time: ${_formatTime(startTime)}'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: startTime,
              );
              if (time != null) {
                setState(() => startTime = time);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time_filled),
            title: Text('End Time: ${_formatTime(endTime)}'),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: endTime,
              );
              if (time != null) {
                setState(() => endTime = time);
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Duration: ${_calculateDuration(startTime, endTime)} minutes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isValidTimeRange(startTime, endTime)) {
              widget.onTimeSelected(startTime, endTime);
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('End time must be after start time'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes - startMinutes;
  }

  bool _isValidTimeRange(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes > startMinutes;
  }
}