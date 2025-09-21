import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/focus_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/task_provider.dart';
import '../providers/gamification_provider.dart';
import '../models/task.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildWeeklyOverview(context),
            const SizedBox(height: 24),
            _buildTaskAnalytics(context),
            const SizedBox(height: 24),
            _buildFocusChart(context),
            const SizedBox(height: 24),
            _buildCategoryChart(context),
            const SizedBox(height: 24),
            _buildMoodChart(context),
            const SizedBox(height: 24),
            _buildInsights(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview(BuildContext context) {
    return Consumer4<FocusProvider, MoodProvider, TaskProvider, GamificationProvider>(
      builder: (context, focusProvider, moodProvider, taskProvider, gamificationProvider, child) {
        final weeklySessions = focusProvider.getWeeklySessions();
        final weeklyFocusTime = weeklySessions
            .where((s) => !s.isBreak)
            .fold(Duration.zero, (total, session) => total + session.duration);
        final averageMood = moodProvider.averageMoodThisWeek;
        final completionRate = taskProvider.completionRate;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildOverviewStat(
                        context,
                        'Total Focus',
                        '${weeklyFocusTime.inHours}h ${weeklyFocusTime.inMinutes % 60}m',
                        Icons.timer,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildOverviewStat(
                        context,
                        'Sessions',
                        '${weeklySessions.where((s) => !s.isBreak).length}',
                        Icons.check_circle,
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Expanded(
                      child: _buildOverviewStat(
                        context,
                        'Completion',
                        '$completionRate%',
                        Icons.task_alt,
                        Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildFocusChart(BuildContext context) {
    return Consumer<FocusProvider>(
      builder: (context, focusProvider, child) {
        final weeklySessions = focusProvider.getWeeklySessions();
        final dailyFocusTime = _calculateDailyFocusTime(weeklySessions);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Focus Time',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 180, // 3 hours max
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              return Text(days[value.toInt()]);
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text('${value.toInt()}h');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: dailyFocusTime.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodChart(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        final weeklyMoods = moodProvider.getWeeklyMoods();
        final dailyMoods = _calculateDailyMoods(weeklyMoods);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood Trend',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      maxY: 5,
                      minY: 1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailyMoods.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value.toDouble());
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.secondary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              if (value.toInt() < days.length) {
                                return Text(days[value.toInt()]);
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const moods = ['😢', '😕', '😐', '😊', '😄'];
                              if (value.toInt() >= 1 && value.toInt() <= 5) {
                                return Text(moods[value.toInt() - 1]);
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsights(BuildContext context) {
    return Consumer2<FocusProvider, MoodProvider>(
      builder: (context, focusProvider, moodProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInsightItem(
                  context,
                  Icons.track_changes,
                  'Focus Goal',
                  'You\'re on track to reach your 2-hour daily goal!',
                  Colors.blue.shade600,
                ),
                _buildInsightItem(
                  context,
                  Icons.trending_up,
                  'Productivity Trend',
                  'Your focus time has increased by 15% this week.',
                  Colors.green.shade600,
                ),
                _buildInsightItem(
                  context,
                  Icons.mood,
                  'Mood & Focus',
                  'You tend to be more focused when you\'re in a good mood.',
                  const Color(0xFF7C3AED),
                ),
                _buildInsightItem(
                  context,
                  Icons.local_fire_department,
                  'Streak',
                  'Keep it up! You\'re on a 3-day focus streak.',
                  Colors.deepOrange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    [Color? iconColor]
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: iconColor ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<int> _calculateDailyFocusTime(List<dynamic> weeklySessions) {
    // Create a list for 7 days (Monday to Sunday)
    final dailyMinutes = List.filled(7, 0);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    for (final session in weeklySessions) {
      if (session.isBreak) continue;

      final sessionDay = session.startTime.difference(weekStart).inDays;
      if (sessionDay >= 0 && sessionDay < 7) {
        dailyMinutes[sessionDay] = (dailyMinutes[sessionDay] + session.duration.inMinutes).toInt();
      }
    }

    return dailyMinutes;
  }

  List<int> _calculateDailyMoods(List<dynamic> weeklyMoods) {
    // Create a list for 7 days with default mood of 3 (neutral)
    final dailyMoods = List.filled(7, 3);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    for (final mood in weeklyMoods) {
      final moodDay = mood.date.difference(weekStart).inDays;
      if (moodDay >= 0 && moodDay < 7) {
        dailyMoods[moodDay] = mood.moodLevel;
      }
    }

    return dailyMoods;
  }

  Widget _buildTaskAnalytics(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final tasks = taskProvider.tasks;
        final completedTasks = taskProvider.completedTasks;
        final overdueTasks = taskProvider.overdueTasks;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTaskStat(
                        context,
                        'Total Tasks',
                        '${tasks.length}',
                        Icons.assignment,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildTaskStat(
                        context,
                        'Completed',
                        '${completedTasks.length}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildTaskStat(
                        context,
                        'Overdue',
                        '${overdueTasks.length}',
                        Icons.schedule,
                        Colors.red,
                      ),
                    ),
                    Expanded(
                      child: _buildTaskStat(
                        context,
                        'Success Rate',
                        '${taskProvider.completionRate}%',
                        Icons.trending_up,
                        Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryChart(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final timeByCategory = taskProvider.timeSpentByCategory;
        final hasData = timeByCategory.values.any((duration) => duration.inMinutes > 0);

        if (!hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'Time by Category',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'No data available yet.\nStart completing tasks to see insights!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }

        final List<Color> colors = [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.secondary,
          Theme.of(context).colorScheme.tertiary,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.indigo,
        ];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time by Category',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: timeByCategory.entries
                                .where((entry) => entry.value.inMinutes > 0)
                                .toList()
                                .asMap()
                                .entries
                                .map((entry) {
                              final index = entry.key;
                              final categoryEntry = entry.value;
                              final totalMinutes = timeByCategory.values
                                  .fold(0, (sum, duration) => sum + duration.inMinutes);
                              final percentage = (categoryEntry.value.inMinutes / totalMinutes * 100);

                              return PieChartSectionData(
                                color: colors[index % colors.length],
                                value: categoryEntry.value.inMinutes.toDouble(),
                                title: '${percentage.toStringAsFixed(0)}%',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: timeByCategory.entries
                              .where((entry) => entry.value.inMinutes > 0)
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final categoryEntry = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      categoryEntry.key.name.substring(0, 1).toUpperCase() +
                                          categoryEntry.key.name.substring(1),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  Text(
                                    '${categoryEntry.value.inHours}h ${categoryEntry.value.inMinutes % 60}m',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}