import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class NotificationProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _taskRemindersEnabled = true;
  bool _breakRemindersEnabled = true;
  int _reminderMinutesBefore = 30;

  static const String _notificationsKey = 'notifications_enabled';
  static const String _taskRemindersKey = 'task_reminders_enabled';
  static const String _breakRemindersKey = 'break_reminders_enabled';
  static const String _reminderTimeKey = 'reminder_minutes_before';

  NotificationProvider() {
    _loadSettings();
  }

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  bool get breakRemindersEnabled => _breakRemindersEnabled;
  int get reminderMinutesBefore => _reminderMinutesBefore;

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
      _taskRemindersEnabled = prefs.getBool(_taskRemindersKey) ?? true;
      _breakRemindersEnabled = prefs.getBool(_breakRemindersKey) ?? true;
      _reminderMinutesBefore = prefs.getInt(_reminderTimeKey) ?? 30;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, _notificationsEnabled);
      await prefs.setBool(_taskRemindersKey, _taskRemindersEnabled);
      await prefs.setBool(_breakRemindersKey, _breakRemindersEnabled);
      await prefs.setInt(_reminderTimeKey, _reminderMinutesBefore);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  void setTaskRemindersEnabled(bool enabled) {
    _taskRemindersEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  void setBreakRemindersEnabled(bool enabled) {
    _breakRemindersEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  void setReminderTime(int minutes) {
    _reminderMinutesBefore = minutes;
    _saveSettings();
    notifyListeners();
  }

  // Smart notification logic
  void scheduleTaskReminder(Task task) {
    if (!_notificationsEnabled || !_taskRemindersEnabled) return;

    final reminderTime = task.dueDate.subtract(Duration(minutes: _reminderMinutesBefore));
    final now = DateTime.now();

    if (reminderTime.isAfter(now)) {
      _scheduleNotification(
        id: task.id.hashCode,
        title: 'Task Reminder',
        body: '${task.title} is due in $_reminderMinutesBefore minutes!',
        scheduledDate: reminderTime,
      );
    }
  }

  void scheduleOverdueReminder(Task task) {
    if (!_notificationsEnabled || !_taskRemindersEnabled) return;

    final now = DateTime.now();
    if (task.dueDate.isBefore(now) && !task.isCompleted) {
      final hoursOverdue = now.difference(task.dueDate).inHours;

      // Send overdue notification
      _sendImmediateNotification(
        id: '${task.id}_overdue'.hashCode,
        title: 'Overdue Task',
        body: '${task.title} is $hoursOverdue hours overdue!',
      );
    }
  }

  void scheduleBreakReminder() {
    if (!_notificationsEnabled || !_breakRemindersEnabled) return;

    // Schedule a break reminder for every hour of continuous work
    final now = DateTime.now();
    final breakTime = now.add(const Duration(hours: 1));

    _scheduleNotification(
      id: 'break_reminder'.hashCode,
      title: 'Take a Break!',
      body: 'You\'ve been working for an hour. Time for a 5-minute break!',
      scheduledDate: breakTime,
    );
  }

  void scheduleStudySessionReminder(DateTime sessionTime, String subject) {
    if (!_notificationsEnabled) return;

    final reminderTime = sessionTime.subtract(const Duration(minutes: 10));
    final now = DateTime.now();

    if (reminderTime.isAfter(now)) {
      _scheduleNotification(
        id: sessionTime.hashCode,
        title: 'Study Session Starting',
        body: 'Your $subject study session starts in 10 minutes!',
        scheduledDate: reminderTime,
      );
    }
  }

  void sendAchievementNotification(String title, String description) {
    if (!_notificationsEnabled) return;

    _sendImmediateNotification(
      id: 'achievement_${DateTime.now().millisecondsSinceEpoch}'.hashCode,
title: 'Achievement Unlocked!',
      body: '$title - $description',
    );
  }

  void sendMotivationalNotification() {
    if (!_notificationsEnabled) return;

final motivationalMessages = [
      'You\'re doing great! Keep up the momentum!',
      'Small steps lead to big achievements!',
      'Focus on progress, not perfection!',
      'Every task completed is a victory!',
      'You\'ve got this! Stay focused!',
      'Consistency beats perfection!',
      'Transform your dreams into plans!',
    ];

    final random = DateTime.now().millisecond;
    final message = motivationalMessages[random % motivationalMessages.length];

    _sendImmediateNotification(
      id: 'motivation_${DateTime.now().millisecondsSinceEpoch}'.hashCode,
      title: 'Stay Motivated!',
      body: message,
    );
  }

  void scheduleWeeklyProgressReport() {
    if (!_notificationsEnabled) return;

    final now = DateTime.now();
    final nextSunday = now.add(Duration(days: 7 - now.weekday));
    final reportTime = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 18, 0);

    _scheduleNotification(
      id: 'weekly_report'.hashCode,
      title: 'Weekly Progress Report',
      body: 'Check out your productivity insights for this week!',
      scheduledDate: reportTime,
    );
  }

  void cancelTaskNotification(String taskId) {
    _cancelNotification(taskId.hashCode);
  }

  void cancelAllNotifications() {
    // This would cancel all pending notifications
    debugPrint('All notifications cancelled');
  }

  // Private methods for actual notification implementation
  void _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) {
    // In a real implementation, this would use flutter_local_notifications
    debugPrint('Scheduled notification: $title at $scheduledDate');

    // For now, just log the notification
    // In production, you would integrate with flutter_local_notifications:
    /*
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_flow_channel',
          'FocusFlow Notifications',
          channelDescription: 'Task reminders and productivity notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
    */
  }

  void _sendImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) {
    debugPrint('Immediate notification: $title - $body');
    // This would send an immediate notification
  }

  void _cancelNotification(int id) {
    debugPrint('Cancelled notification with id: $id');
    // This would cancel a specific notification
  }

  // Smart notification suggestions based on user patterns
  List<String> getSmartSuggestions(List<Task> tasks) {
    final suggestions = <String>[];
    final now = DateTime.now();

    // Check for tasks due today
    final todayTasks = tasks.where((task) =>
      !task.isCompleted &&
      task.isDueToday
    ).toList();

    if (todayTasks.isNotEmpty) {
      suggestions.add('You have ${todayTasks.length} tasks due today. Start with the highest priority one!');
    }

    // Check for overdue tasks
    final overdueTasks = tasks.where((task) => task.isOverdue).toList();
    if (overdueTasks.isNotEmpty) {
      suggestions.add('You have ${overdueTasks.length} overdue tasks. Consider rescheduling or breaking them into smaller parts.');
    }

    // Check for upcoming deadlines
    final upcomingTasks = tasks.where((task) =>
      !task.isCompleted &&
      task.timeUntilDue.inHours <= 24 &&
      task.timeUntilDue.inHours > 0
    ).toList();

    if (upcomingTasks.isNotEmpty) {
      suggestions.add('${upcomingTasks.length} tasks are due within 24 hours. Plan your day accordingly!');
    }

    // Productivity tips based on time of day
    final hour = now.hour;
    if (hour >= 9 && hour <= 11) {
suggestions.add('Morning is great for tackling complex tasks when your mind is fresh!');
    } else if (hour >= 14 && hour <= 16) {
suggestions.add('Afternoon slump? Try a 5-minute break or a quick walk to re-energize!');
    } else if (hour >= 20 && hour <= 22) {
suggestions.add('Evening is perfect for planning tomorrow and reviewing today\'s progress!');
    }

    return suggestions;
  }

  // Check if it's time for a motivational notification
  bool shouldSendMotivationalNotification(int completedTasksToday, Duration focusTimeToday) {
    final hour = DateTime.now().hour;

    // Send motivation if user has been inactive or needs encouragement
    if (completedTasksToday == 0 && hour > 10) {
      return true; // No tasks completed and it's after 10 AM
    }

    if (focusTimeToday.inMinutes < 30 && hour > 14) {
      return true; // Low focus time and it's afternoon
    }

    if (completedTasksToday >= 3) {
      return true; // Celebrate good progress
    }

    return false;
  }
}