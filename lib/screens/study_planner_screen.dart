import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_plan_provider.dart';
import '../providers/task_provider.dart';
import '../providers/schedule_provider.dart';
import '../models/study_plan.dart';
import '../widgets/glass_card.dart';
import '../screens/weekly_study_preferences_screen.dart';

class StudyPlannerScreen extends StatelessWidget {
  const StudyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Planner'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WeeklyStudyPreferencesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.schedule),
            tooltip: 'Set Study Times',
          ),
          IconButton(
            onPressed: () => _showGeneratePlanDialog(context),
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Generate Smart Plan',
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
        child: Consumer3<StudyPlanProvider, TaskProvider, ScheduleProvider>(
          builder: (context, studyPlanProvider, taskProvider, scheduleProvider, child) {
            final currentPlan = studyPlanProvider.currentWeekPlan;
            final todaysSessions = studyPlanProvider.getTodaysSessions();
            final upcomingSessions = studyPlanProvider.getUpcomingSessions();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeekOverview(context, studyPlanProvider),
                  const SizedBox(height: 24),
                  _buildTodaysSchedule(context, todaysSessions),
                  const SizedBox(height: 24),
                  _buildUpcomingSessions(context, upcomingSessions),
                  const SizedBox(height: 24),
                  _buildWeeklyCalendar(context, studyPlanProvider),
                  const SizedBox(height: 24),
                  _buildSuggestions(context, studyPlanProvider, taskProvider),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSessionDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWeekOverview(BuildContext context, StudyPlanProvider provider) {
    final weeklyProgress = provider.getWeeklyProgress();
    final totalTime = provider.getTotalStudyTimeThisWeek();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'This Week\'s Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${(weeklyProgress * 100).toInt()}% Complete',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${totalTime.inHours}h ${totalTime.inMinutes % 60}m studied this week',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: weeklyProgress,
                    strokeWidth: 6,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule(BuildContext context, List<StudySession> sessions) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Schedule',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${sessions.length} sessions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.free_cancellation_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Free day ahead!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate a study plan or manually add sessions to make the most of your time',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...sessions.map((session) => _buildSessionCard(context, session)),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessions(BuildContext context, List<StudySession> sessions) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Sessions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sessions.take(3).map((session) => _buildSessionCard(context, session)),
          if (sessions.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+${sessions.length - 3} more sessions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, StudySession session) {
    final now = DateTime.now();
    final isActive = now.isAfter(session.startTime) && now.isBefore(session.endTime);
    final isPast = now.isAfter(session.endTime);

    return InkWell(
      onTap: () => _showSessionDetailsDialog(context, session),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTypeColor(session.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTypeIcon(session.type),
              color: _getTypeColor(session.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: session.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (session.subject != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.subject!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!session.isCompleted && !isPast)
            IconButton(
              onPressed: () {
                Provider.of<StudyPlanProvider>(context, listen: false)
                    .completeStudySession(session.id);
              },
              icon: Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          else if (session.isCompleted)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildWeeklyCalendar(BuildContext context, StudyPlanProvider provider) {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly View',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(7, (index) {
              final day = weekStart.add(Duration(days: index));
              final sessions = provider.getSessionsForDay(day);
              final isToday = _isSameDay(day, now);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Column(
                        children: [
                          Text(
                            _getDayName(day.weekday),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${day.day}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: sessions.isEmpty
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Free day',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Add study sessions to optimize your time',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            )
                          : Wrap(
                              spacing: 4,
                              children: sessions.map((session) {
                                final studySession = session as StudySession;
                                return Chip(
                                  label: Text(
                                    studySession.subject ?? studySession.typeLabel,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: _getTypeColor(studySession.type).withOpacity(0.2),
                                  side: BorderSide.none,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(BuildContext context, StudyPlanProvider studyProvider, TaskProvider taskProvider) {
    final suggestions = studyProvider.getSchedulingSuggestions(taskProvider.tasks);

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Suggestions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showGeneratePlanDialog(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final hasPreferences = scheduleProvider.schedule.freeTimeWindows.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Study Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasPreferences) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No study preferences set. We\'ll use default times.',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const WeeklyStudyPreferencesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.schedule),
                label: const Text('Set Study Times First'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
            ],
            Text(
              hasPreferences
                  ? 'This will create a personalized study schedule based on your preferred times, tasks, and deadlines.'
                  : 'This will create a basic study schedule using default times. For best results, set your study preferences first.',
            ),
            if (hasPreferences) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Using your personalized study times',
                      style: TextStyle(color: Colors.green[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final taskProvider = Provider.of<TaskProvider>(context, listen: false);
              final studyPlanProvider = Provider.of<StudyPlanProvider>(context, listen: false);

              // Pass the student schedule to the generator
              studyPlanProvider.generateWeeklyPlan(
                taskProvider.tasks,
                studentSchedule: hasPreferences ? scheduleProvider.schedule : null,
              );
              Navigator.of(context).pop();

              final sessionsCount = studyPlanProvider.currentWeekPlan?.sessions.length ?? 0;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    hasPreferences
                        ? 'Smart study plan generated! Created $sessionsCount sessions based on your preferences.'
                        : 'Basic study plan generated! Created $sessionsCount sessions with default times.',
                  ),
                  backgroundColor: hasPreferences ? Colors.green : Colors.orange,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            child: Text(hasPreferences ? 'Generate Smart Plan' : 'Generate Basic Plan'),
          ),
        ],
      ),
    );
  }

  void _showSessionDetailsDialog(BuildContext context, StudySession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(session.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getTypeIcon(session.type), color: _getTypeColor(session.type)),
                const SizedBox(width: 8),
                Text(session.typeLabel, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            if (session.subject != null) ...[
              Text('Subject: ${session.subject}', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
            ],
            Text('Time: ${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
                 style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Duration: ${session.duration.inMinutes} minutes',
                 style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Status: ${session.isCompleted ? "Completed" : "Pending"}',
                 style: Theme.of(context).textTheme.bodyMedium),
            if (session.notes != null) ...[
              const SizedBox(height: 8),
              Text('Notes: ${session.notes}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!session.isCompleted)
            ElevatedButton(
              onPressed: () {
                Provider.of<StudyPlanProvider>(context, listen: false)
                    .completeStudySession(session.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session marked as completed!')),
                );
              },
              child: const Text('Mark Complete'),
            ),
        ],
      ),
    );
  }

  void _showAddSessionDialog(BuildContext context) {
    // This would show a dialog to add a custom study session
    // For now, just show a simple message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add session feature coming soon!'),
      ),
    );
  }

  // Helper methods
  Color _getTypeColor(StudySessionType type) {
    switch (type) {
      case StudySessionType.lecture:
        return Colors.blue;
      case StudySessionType.reading:
        return Colors.green;
      case StudySessionType.practice:
        return Colors.orange;
      case StudySessionType.review:
        return Colors.purple;
      case StudySessionType.project:
        return Colors.red;
      case StudySessionType.breakTime:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(StudySessionType type) {
    switch (type) {
      case StudySessionType.lecture:
        return Icons.school;
      case StudySessionType.reading:
        return Icons.menu_book;
      case StudySessionType.practice:
        return Icons.edit;
      case StudySessionType.review:
        return Icons.quiz;
      case StudySessionType.project:
        return Icons.engineering;
      case StudySessionType.breakTime:
        return Icons.coffee;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}