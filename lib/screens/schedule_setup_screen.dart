import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/student_schedule.dart';
import '../widgets/glass_card.dart';

class ScheduleSetupScreen extends StatefulWidget {
  const ScheduleSetupScreen({super.key});

  @override
  State<ScheduleSetupScreen> createState() => _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends State<ScheduleSetupScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _classFormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);
  ScheduleType _selectedType = ScheduleType.class_;
  List<int> _selectedDays = [];
  List<StudyPreference> _selectedPreferences = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Setup'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Quick Setup'),
            Tab(icon: Icon(Icons.school), text: 'Classes'),
            Tab(icon: Icon(Icons.favorite), text: 'Preferences'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildQuickSetupTab(),
            _buildClassesTab(),
            _buildPreferencesTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Schedule Setup',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a template that matches your lifestyle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickSetupCard(
            'Morning Person',
            'Early riser who studies best 6-10 AM',
            'morning_person',
            Icons.wb_sunny,
          ),
          const SizedBox(height: 16),
          _buildQuickSetupCard(
            'Night Owl',
            'Studies best in the evening 7-11 PM',
            'night_owl',
            Icons.nights_stay,
          ),
          const SizedBox(height: 16),
          _buildQuickSetupCard(
            'Typical Student',
            'Standard class schedule with flexible study times',
            'typical_student',
            Icons.school,
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              children: [
                const Icon(Icons.info_outline, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Smart Learning',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'FocusFlow learns from your study patterns to suggest optimal times. '
                  'The more you use it, the smarter it gets!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSetupCard(String title, String description, String type, IconData icon) {
    return GlassCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Provider.of<ScheduleProvider>(context, listen: false).setupQuickSchedule(type);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title schedule applied!'),
              backgroundColor: Colors.green,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassesTab() {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Classes & Commitments',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAddClassDialog(),
                    icon: const Icon(Icons.add_circle),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (scheduleProvider.schedule.busySlots.isEmpty)
                GlassCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No classes added yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your classes, work schedule, or other commitments to get personalized study time suggestions.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...scheduleProvider.schedule.busySlots.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildClassCard(entry.value, entry.key),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassCard(TimeSlot slot, int index) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(slot.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(slot.type),
                color: _getTypeColor(slot.type),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.title ?? 'Untitled',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDays(slot.weekdays),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (slot.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          slot.location!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Provider.of<ScheduleProvider>(context, listen: false).removeBusySlot(index);
              },
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Preferences',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us when you study best',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferred Study Times',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: StudyPreference.values.map((pref) {
                        final isSelected = _selectedPreferences.contains(pref);
                        return FilterChip(
                          label: Text(_getPreferenceLabel(pref)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedPreferences.add(pref);
                              } else {
                                _selectedPreferences.remove(pref);
                              }
                            });
                            scheduleProvider.updateStudyPreferences(_selectedPreferences);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Preferences',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Preferred session length: 45 minutes'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.pause, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Break between sessions: 15 minutes'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<ScheduleProvider>(
      builder: (context, scheduleProvider, child) {
        final analytics = scheduleProvider.getStudyAnalytics();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Pattern Analytics',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn from your study habits',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (analytics.containsKey('message'))
                GlassCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.insights,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        analytics['message'],
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Sessions',
                        '${analytics['totalSessions']}',
                        Icons.event_note,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Completion',
                        '${analytics['completionRate'].round()}%',
                        Icons.check_circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Average Productivity',
                  '${(analytics['avgProductivity'] as double).toStringAsFixed(1)}/5.0',
                  Icons.trending_up,
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peak Productivity Hours',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(analytics['peakHours'] as List).map((hour) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${hour['hour']}:00'),
                            Text('${(hour['avgRating'] as double).toStringAsFixed(1)}/5.0'),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                if (analytics['recommendations'] != null) ...[
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalized Recommendations',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(analytics['recommendations'] as List<String>).map(
                          (rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(rec)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Class/Commitment'),
        content: Form(
          key: _classFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ScheduleType>(
                  value: _selectedType,
                  onChanged: (type) => setState(() => _selectedType = type!),
                  items: ScheduleType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeLabel(type)),
                    );
                  }).toList(),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text('Start: ${_formatTime(_startTime)}'),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (time != null) {
                            setState(() => _startTime = time);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text('End: ${_formatTime(_endTime)}'),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (time != null) {
                            setState(() => _endTime = time);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Days of the week:'),
                Wrap(
                  children: [
                    for (int i = 1; i <= 7; i++)
                      FilterChip(
                        label: Text(_getDayAbbrev(i)),
                        selected: _selectedDays.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(i);
                            } else {
                              _selectedDays.remove(i);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_classFormKey.currentState!.validate() && _selectedDays.isNotEmpty) {
                final slot = TimeSlot(
                  startTime: _startTime,
                  endTime: _endTime,
                  weekdays: _selectedDays,
                  type: _selectedType,
                  title: _titleController.text,
                  location: _locationController.text.isEmpty ? null : _locationController.text,
                );

                Provider.of<ScheduleProvider>(context, listen: false).addBusySlot(slot);

                _titleController.clear();
                _locationController.clear();
                _selectedDays.clear();
                _startTime = const TimeOfDay(hour: 9, minute: 0);
                _endTime = const TimeOfDay(hour: 10, minute: 30);

                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.class_: return Colors.blue;
      case ScheduleType.work: return Colors.green;
      case ScheduleType.meal: return Colors.orange;
      case ScheduleType.sleep: return Colors.purple;
      case ScheduleType.commute: return Colors.grey;
      case ScheduleType.personal: return Colors.teal;
      case ScheduleType.unavailable: return Colors.red;
    }
  }

  IconData _getTypeIcon(ScheduleType type) {
    switch (type) {
      case ScheduleType.class_: return Icons.school;
      case ScheduleType.work: return Icons.work;
      case ScheduleType.meal: return Icons.restaurant;
      case ScheduleType.sleep: return Icons.bed;
      case ScheduleType.commute: return Icons.commute;
      case ScheduleType.personal: return Icons.person;
      case ScheduleType.unavailable: return Icons.block;
    }
  }

  String _getTypeLabel(ScheduleType type) {
    switch (type) {
      case ScheduleType.class_: return 'Class';
      case ScheduleType.work: return 'Work';
      case ScheduleType.meal: return 'Meal';
      case ScheduleType.sleep: return 'Sleep';
      case ScheduleType.commute: return 'Commute';
      case ScheduleType.personal: return 'Personal';
      case ScheduleType.unavailable: return 'Unavailable';
    }
  }

  String _getPreferenceLabel(StudyPreference pref) {
    switch (pref) {
      case StudyPreference.earlyMorning: return 'Early Morning (6-9 AM)';
      case StudyPreference.lateMorning: return 'Late Morning (9-12 PM)';
      case StudyPreference.earlyAfternoon: return 'Early Afternoon (12-3 PM)';
      case StudyPreference.lateAfternoon: return 'Late Afternoon (3-6 PM)';
      case StudyPreference.evening: return 'Evening (6-9 PM)';
      case StudyPreference.night: return 'Night (9 PM+)';
      case StudyPreference.noPreference: return 'No Preference';
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDays(List<int> days) {
    final dayNames = days.map(_getDayAbbrev).join(', ');
    return dayNames;
  }

  String _getDayAbbrev(int day) {
    const abbrevs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbrevs[day - 1];
  }
}