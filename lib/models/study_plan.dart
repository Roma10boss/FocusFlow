import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/student_schedule.dart';

enum StudySessionType {
  lecture,
  reading,
  practice,
  review,
  project,
  breakTime
}

class StudySession {
  final String id;
  final String title;
  final String? subject;
  final DateTime startTime;
  final DateTime endTime;
  final StudySessionType type;
  final String? notes;
  final bool isCompleted;
  final List<String> taskIds; // Related tasks

  StudySession({
    required this.id,
    required this.title,
    this.subject,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.notes,
    this.isCompleted = false,
    this.taskIds = const [],
  });

  Duration get duration => endTime.difference(startTime);

  StudySession copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    StudySessionType? type,
    String? notes,
    bool? isCompleted,
    List<String>? taskIds,
  }) {
    return StudySession(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      taskIds: taskIds ?? this.taskIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.name,
      'notes': notes,
      'isCompleted': isCompleted,
      'taskIds': taskIds,
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    return StudySession(
      id: json['id'],
      title: json['title'],
      subject: json['subject'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: StudySessionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => StudySessionType.lecture,
      ),
      notes: json['notes'],
      isCompleted: json['isCompleted'] ?? false,
      taskIds: List<String>.from(json['taskIds'] ?? []),
    );
  }

  String get typeLabel {
    switch (type) {
      case StudySessionType.lecture: return 'Lecture';
      case StudySessionType.reading: return 'Reading';
      case StudySessionType.practice: return 'Practice';
      case StudySessionType.review: return 'Review';
      case StudySessionType.project: return 'Project';
      case StudySessionType.breakTime: return 'Break';
    }
  }
}

class WeeklyStudyPlan {
  final String id;
  final DateTime weekStart;
  final List<StudySession> sessions;
  final Map<String, int> subjectHours; // Subject -> planned hours
  final String? notes;

  WeeklyStudyPlan({
    required this.id,
    required this.weekStart,
    this.sessions = const [],
    this.subjectHours = const {},
    this.notes,
  });

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  Map<DateTime, List<StudySession>> get sessionsByDay {
    final Map<DateTime, List<StudySession>> dayMap = {};

    for (final session in sessions) {
      final day = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      dayMap[day] = (dayMap[day] ?? [])..add(session);
    }

    return dayMap;
  }

  Duration get totalPlannedTime {
    return sessions.fold(
      Duration.zero,
      (total, session) => total + session.duration,
    );
  }

  Duration get completedTime {
    return sessions
        .where((session) => session.isCompleted)
        .fold(Duration.zero, (total, session) => total + session.duration);
  }

  double get completionPercentage {
    if (sessions.isEmpty) return 0.0;
    final completed = sessions.where((s) => s.isCompleted).length;
    return completed / sessions.length;
  }

  WeeklyStudyPlan copyWith({
    String? id,
    DateTime? weekStart,
    List<StudySession>? sessions,
    Map<String, int>? subjectHours,
    String? notes,
  }) {
    return WeeklyStudyPlan(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      sessions: sessions ?? this.sessions,
      subjectHours: subjectHours ?? this.subjectHours,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStart': weekStart.toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
      'subjectHours': subjectHours,
      'notes': notes,
    };
  }

  factory WeeklyStudyPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyStudyPlan(
      id: json['id'],
      weekStart: DateTime.parse(json['weekStart']),
      sessions: (json['sessions'] as List?)
          ?.map((s) => StudySession.fromJson(s))
          .toList() ?? [],
      subjectHours: Map<String, int>.from(json['subjectHours'] ?? {}),
      notes: json['notes'],
    );
  }
}

class StudyPlanGenerator {
  static WeeklyStudyPlan generateFromTasks(
    List<Task> tasks,
    DateTime weekStart, {
    Map<String, int> preferredHours = const {},
    List<String> busyTimeSlots = const [], // Deprecated - use studentSchedule instead
    StudentSchedule? studentSchedule,
  }) {
    final sessions = <StudySession>[];

    // Sort tasks by due date and priority
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) {
        // First by due date, then by priority
        final dateComparison = a.dueDate.compareTo(b.dueDate);
        if (dateComparison != 0) return dateComparison;
        return b.priority.compareTo(a.priority);
      });

    // Smart scheduling based on student availability and preferences
    if (studentSchedule != null) {
      sessions.addAll(_generateSmartSessions(weekStart, sortedTasks, studentSchedule));
    } else {
      // Fallback to basic scheduling for backwards compatibility
      sessions.addAll(_generateBasicSessions(weekStart, sortedTasks));
    }

    return WeeklyStudyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weekStart: weekStart,
      sessions: sessions,
      subjectHours: _calculateSubjectHours(sessions),
    );
  }

  static List<StudySession> _generateSessionsForTimeSlot(
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
    List<Task> tasks,
  ) {
    final sessions = <StudySession>[];
    final availableMinutes = _timeOfDayDifference(startTime, endTime);

    if (availableMinutes < 30) return sessions; // Need at least 30 minutes

    var currentTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Find tasks due this week or soon after
    final weekEnd = date.add(const Duration(days: 14)); // Include next 2 weeks
    final relevantTasks = tasks.where((task) {
      // Include tasks that are not completed
      if (task.isCompleted) return false;

      // Include tasks due within the next 2 weeks (or overdue by 1 day)
      return task.dueDate.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
             task.dueDate.isBefore(weekEnd);
    }).toList();

    // Add a general study session if no specific tasks are found
    if (relevantTasks.isEmpty) {
      // Create generic study sessions throughout the available time
      while (currentTime.add(const Duration(minutes: 45)).isBefore(endDateTime)) {
        sessions.add(StudySession(
          id: 'general_${currentTime.millisecondsSinceEpoch}',
          title: 'General Study Time',
          subject: 'Review',
          startTime: currentTime,
          endTime: currentTime.add(const Duration(minutes: 45)),
          type: StudySessionType.review,
        ));
        currentTime = currentTime.add(const Duration(minutes: 60)); // 45 min + 15 min break
      }
      return sessions;
    }

    for (final task in relevantTasks) {
      if (currentTime.add(const Duration(minutes: 30)).isAfter(endDateTime)) {
        break; // No more time
      }

      final sessionDuration = _calculateSessionDuration(task);
      final sessionEnd = currentTime.add(sessionDuration);

      if (sessionEnd.isAfter(endDateTime)) {
        // Adjust to fit remaining time
        final remainingTime = endDateTime.difference(currentTime);
        if (remainingTime.inMinutes >= 25) {
          sessions.add(StudySession(
            id: '${task.id}_${currentTime.millisecondsSinceEpoch}',
            title: 'Study: ${task.title}',
            subject: task.subject,
            startTime: currentTime,
            endTime: currentTime.add(remainingTime),
            type: _getSessionTypeForTask(task),
            taskIds: [task.id],
          ));
        }
        break;
      }

      sessions.add(StudySession(
        id: '${task.id}_${currentTime.millisecondsSinceEpoch}',
        title: 'Study: ${task.title}',
        subject: task.subject,
        startTime: currentTime,
        endTime: sessionEnd,
        type: _getSessionTypeForTask(task),
        taskIds: [task.id],
      ));

      currentTime = sessionEnd.add(const Duration(minutes: 10)); // 10-minute break
    }

    return sessions;
  }

  static Duration _calculateSessionDuration(Task task) {
    // Use estimated time if available, otherwise default based on category
    if (task.estimatedTime != null) {
      return task.estimatedTime!;
    }

    switch (task.category) {
      case TaskCategory.reading:
        return const Duration(minutes: 45);
      case TaskCategory.homework:
        return const Duration(minutes: 60);
      case TaskCategory.project:
        return const Duration(minutes: 90);
      case TaskCategory.exam:
        return const Duration(minutes: 120);
      case TaskCategory.lab:
        return const Duration(minutes: 180);
      case TaskCategory.quiz:
        return const Duration(minutes: 30);
      case TaskCategory.review:
        return const Duration(minutes: 45);
      default:
        return const Duration(minutes: 60);
    }
  }

  static StudySessionType _getSessionTypeForTask(Task task) {
    switch (task.category) {
      case TaskCategory.reading:
        return StudySessionType.reading;
      case TaskCategory.homework:
        return StudySessionType.practice;
      case TaskCategory.project:
        return StudySessionType.project;
      case TaskCategory.exam:
        return StudySessionType.review;
      case TaskCategory.lab:
        return StudySessionType.practice;
      case TaskCategory.quiz:
        return StudySessionType.review;
      case TaskCategory.review:
        return StudySessionType.review;
      default:
        return StudySessionType.lecture;
    }
  }

  static int _timeOfDayDifference(TimeOfDay start, TimeOfDay end) {
    return (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
  }

  // Smart session generation using student schedule and learning
  static List<StudySession> _generateSmartSessions(
    DateTime weekStart,
    List<Task> tasks,
    StudentSchedule studentSchedule,
  ) {
    final sessions = <StudySession>[];

    // Generate sessions for each day of the week
    for (int day = 0; day < 7; day++) {
      final currentDate = weekStart.add(Duration(days: day));
      final weekday = currentDate.weekday;

      // Get available time slots for this day
      final availableSlots = studentSchedule.getAvailableSlots(weekday);

      for (final slot in availableSlots) {
        // Find the best task for this time slot
        final optimalTask = _findOptimalTaskForSlot(slot, tasks, studentSchedule);

        if (optimalTask != null) {
          final sessionDuration = _calculateSessionDuration(optimalTask);
          final adjustedDuration = Duration(
            minutes: (sessionDuration.inMinutes)
                .clamp(30, slot.duration.inMinutes - 10), // Leave 10 min buffer
          );

          final sessionStart = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            slot.startTime.hour,
            slot.startTime.minute,
          );

          sessions.add(StudySession(
            id: '${optimalTask.id}_${sessionStart.millisecondsSinceEpoch}',
            title: 'Study: ${optimalTask.title}',
            subject: optimalTask.subject,
            startTime: sessionStart,
            endTime: sessionStart.add(adjustedDuration),
            type: _getSessionTypeForTask(optimalTask),
            taskIds: [optimalTask.id],
            notes: 'Optimized based on your study patterns',
          ));

          // Remove task from consideration if fully scheduled
          tasks.remove(optimalTask);
        } else {
          // Create a general study session if no specific task fits
          final sessionStart = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            slot.startTime.hour,
            slot.startTime.minute,
          );

          final duration = Duration(
            minutes: slot.duration.inMinutes.clamp(30, 60),
          );

          sessions.add(StudySession(
            id: 'general_${sessionStart.millisecondsSinceEpoch}',
            title: 'Review & Practice',
            subject: 'General',
            startTime: sessionStart,
            endTime: sessionStart.add(duration),
            type: StudySessionType.review,
            notes: 'Free time - perfect for review or catch-up',
          ));
        }
      }
    }

    return sessions;
  }

  // Fallback basic session generation
  static List<StudySession> _generateBasicSessions(
    DateTime weekStart,
    List<Task> tasks,
  ) {
    final sessions = <StudySession>[];

    // Generate study sessions for weekdays only (more efficient)
    for (int day = 0; day < 5; day++) { // Only Monday to Friday
      final currentDate = weekStart.add(Duration(days: day));

      // Limit to 2 sessions per day to reduce computation
      final morningSessions = _generateSessionsForTimeSlot(
        currentDate,
        const TimeOfDay(hour: 9, minute: 0),
        const TimeOfDay(hour: 11, minute: 30), // Shorter time slot
        tasks.take(3).toList(), // Limit tasks per session
      );

      final afternoonSessions = _generateSessionsForTimeSlot(
        currentDate,
        const TimeOfDay(hour: 14, minute: 0),
        const TimeOfDay(hour: 16, minute: 30), // Shorter time slot
        tasks.skip(3).take(3).toList(), // Different tasks
      );

      sessions.addAll(morningSessions);
      sessions.addAll(afternoonSessions);
    }

    return sessions;
  }

  // Find the most suitable task for a given time slot
  static Task? _findOptimalTaskForSlot(
    TimeSlot slot,
    List<Task> availableTasks,
    StudentSchedule studentSchedule,
  ) {
    if (availableTasks.isEmpty) return null;

    Task? bestTask;
    double bestScore = 0.0;

    for (final task in availableTasks) {
      double score = 0.0;

      // Priority scoring (30% weight)
      score += (task.priority / 3.0) * 0.3;

      // Due date urgency (25% weight)
      final daysUntilDue = task.dueDate.difference(DateTime.now()).inDays;
      if (daysUntilDue <= 1) {
        score += 0.25; // Very urgent
      } else if (daysUntilDue <= 3) {
        score += 0.20; // Urgent
      } else if (daysUntilDue <= 7) {
        score += 0.15; // Moderately urgent
      }

      // Difficulty vs available time (20% weight)
      final taskDuration = _calculateSessionDuration(task);
      final timeRatio = taskDuration.inMinutes / slot.duration.inMinutes;
      if (timeRatio >= 0.7 && timeRatio <= 1.2) {
        score += 0.20; // Good time fit
      } else if (timeRatio < 0.7) {
        score += 0.10; // Task too short for slot
      }

      // Historical productivity at this time (25% weight)
      final timeKey = '${slot.weekdays.first}-${slot.startTime.hour}';
      final pastProductivity = studentSchedule.subjectProductivityByTime[timeKey];
      if (pastProductivity != null) {
        score += pastProductivity * 0.25;
      } else {
        score += 0.125; // Neutral score if no data
      }

      if (score > bestScore) {
        bestScore = score;
        bestTask = task;
      }
    }

    return bestTask;
  }

  static Map<String, int> _calculateSubjectHours(List<StudySession> sessions) {
    final Map<String, int> subjectHours = {};

    for (final session in sessions) {
      final subject = session.subject ?? 'No Subject';
      subjectHours[subject] = (subjectHours[subject] ?? 0) +
          session.duration.inMinutes;
    }

    // Convert minutes to hours
    return subjectHours.map((subject, minutes) =>
        MapEntry(subject, (minutes / 60).round()));
  }
}

