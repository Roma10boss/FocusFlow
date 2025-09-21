import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/study_plan.dart';
import '../models/task.dart';
import '../models/student_schedule.dart';

class StudyPlanProvider with ChangeNotifier {
  List<WeeklyStudyPlan> _weeklyPlans = [];
  WeeklyStudyPlan? _currentWeekPlan;
  static const String _plansKey = 'study_plans';

  StudyPlanProvider() {
    _loadPlans();
  }

  List<WeeklyStudyPlan> get weeklyPlans => _weeklyPlans;
  WeeklyStudyPlan? get currentWeekPlan => _currentWeekPlan;

  Future<void> _loadPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getString(_plansKey);
      if (plansJson != null) {
        final List<dynamic> plansList = jsonDecode(plansJson);
        _weeklyPlans = plansList.map((json) => WeeklyStudyPlan.fromJson(json)).toList();

        // Set current week plan
        final now = DateTime.now();
        final weekStart = _getWeekStart(now);
        _currentWeekPlan = _weeklyPlans.firstWhere(
          (plan) => _isSameWeek(plan.weekStart, weekStart),
          orElse: () => WeeklyStudyPlan(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            weekStart: weekStart,
          ),
        );

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading study plans: $e');
    }
  }

  Future<void> _savePlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = jsonEncode(_weeklyPlans.map((plan) => plan.toJson()).toList());
      await prefs.setString(_plansKey, plansJson);
    } catch (e) {
      debugPrint('Error saving study plans: $e');
    }
  }

  void generateWeeklyPlan(List<Task> tasks, {Map<String, int> preferredHours = const {}, StudentSchedule? studentSchedule}) {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);

    final generatedPlan = StudyPlanGenerator.generateFromTasks(
      tasks,
      weekStart,
      preferredHours: preferredHours,
      studentSchedule: studentSchedule,
    );

    // Remove existing plan for this week if any
    _weeklyPlans.removeWhere((plan) => _isSameWeek(plan.weekStart, weekStart));

    // Add new plan
    _weeklyPlans.add(generatedPlan);
    _currentWeekPlan = generatedPlan;

    _savePlans();
    notifyListeners();
  }

  void addStudySession(StudySession session) {
    if (_currentWeekPlan == null) {
      final weekStart = _getWeekStart(DateTime.now());
      _currentWeekPlan = WeeklyStudyPlan(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weekStart: weekStart,
      );
      _weeklyPlans.add(_currentWeekPlan!);
    }

    final updatedSessions = List<StudySession>.from(_currentWeekPlan!.sessions)
      ..add(session);

    _currentWeekPlan = _currentWeekPlan!.copyWith(sessions: updatedSessions);

    // Update in the list
    final index = _weeklyPlans.indexWhere((plan) =>
        _isSameWeek(plan.weekStart, _currentWeekPlan!.weekStart));
    if (index != -1) {
      _weeklyPlans[index] = _currentWeekPlan!;
    }

    _savePlans();
    notifyListeners();
  }

  void updateStudySession(String sessionId, StudySession updatedSession) {
    if (_currentWeekPlan == null) return;

    final updatedSessions = _currentWeekPlan!.sessions.map<StudySession>((session) =>
        session.id == sessionId ? updatedSession : session).toList();

    _currentWeekPlan = _currentWeekPlan!.copyWith(sessions: updatedSessions);

    // Update in the list
    final index = _weeklyPlans.indexWhere((plan) =>
        _isSameWeek(plan.weekStart, _currentWeekPlan!.weekStart));
    if (index != -1) {
      _weeklyPlans[index] = _currentWeekPlan!;
    }

    _savePlans();
    notifyListeners();
  }

  void completeStudySession(String sessionId) {
    if (_currentWeekPlan == null) return;

    final sessionIndex = _currentWeekPlan!.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final session = _currentWeekPlan!.sessions[sessionIndex];
    final completedSession = session.copyWith(isCompleted: true);

    updateStudySession(sessionId, completedSession);
  }

  void deleteStudySession(String sessionId) {
    if (_currentWeekPlan == null) return;

    final updatedSessions = _currentWeekPlan!.sessions
        .where((session) => session.id != sessionId)
        .toList();

    _currentWeekPlan = _currentWeekPlan!.copyWith(sessions: updatedSessions);

    // Update in the list
    final index = _weeklyPlans.indexWhere((plan) =>
        _isSameWeek(plan.weekStart, _currentWeekPlan!.weekStart));
    if (index != -1) {
      _weeklyPlans[index] = _currentWeekPlan!;
    }

    _savePlans();
    notifyListeners();
  }

  List<StudySession> getSessionsForDay(DateTime day) {
    if (_currentWeekPlan == null) return [];

    final dayStart = DateTime(day.year, day.month, day.day);
    return _currentWeekPlan!.sessions.where((session) {
      final sessionDay = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      return sessionDay.isAtSameMomentAs(dayStart);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<StudySession> getTodaysSessions() {
    return getSessionsForDay(DateTime.now());
  }

  List<StudySession> getUpcomingSessions() {
    if (_currentWeekPlan == null) return [];

    final now = DateTime.now();
    return _currentWeekPlan!.sessions
        .where((session) => session.startTime.isAfter(now) && !session.isCompleted)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Map<String, Duration> getSubjectTimeThisWeek() {
    if (_currentWeekPlan == null) return {};

    final Map<String, Duration> subjectTime = {};
    for (final session in _currentWeekPlan!.sessions) {
      if (session.isCompleted) {
        final subject = session.subject ?? 'No Subject';
        subjectTime[subject] = (subjectTime[subject] ?? Duration.zero) + session.duration;
      }
    }
    return subjectTime;
  }

  Duration getTotalStudyTimeThisWeek() {
    if (_currentWeekPlan == null) return Duration.zero;

    return _currentWeekPlan!.sessions
        .where((session) => session.isCompleted)
        .fold(Duration.zero, (total, session) => total + session.duration);
  }

  double getWeeklyProgress() {
    if (_currentWeekPlan == null || _currentWeekPlan!.sessions.isEmpty) return 0.0;

    final completed = _currentWeekPlan!.sessions.where((s) => s.isCompleted).length;
    return completed / _currentWeekPlan!.sessions.length;
  }

  // Helper methods
  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final week1Start = _getWeekStart(date1);
    final week2Start = _getWeekStart(date2);
    return week1Start.isAtSameMomentAs(week2Start);
  }

  // Get smart scheduling suggestions
  List<String> getSchedulingSuggestions(List<Task> tasks) {
    final suggestions = <String>[];

    // Check for unscheduled high-priority tasks
    final highPriorityTasks = tasks.where((task) =>
        task.priority == 3 && !task.isCompleted && task.isDueSoon).toList();

    if (highPriorityTasks.isNotEmpty) {
suggestions.add('Schedule ${highPriorityTasks.length} high-priority tasks due soon');
    }

    // Check for exam preparation
    final examTasks = tasks.where((task) =>
        task.category == TaskCategory.exam && !task.isCompleted).toList();

    if (examTasks.isNotEmpty) {
suggestions.add('Create study sessions for ${examTasks.length} upcoming exams');
    }

    // Check for subject balance
    final subjects = tasks.map((task) => task.subject).whereType<String>().toSet();
    if (subjects.length > 3) {
      suggestions.add('⚖️ Balance study time across ${subjects.length} subjects');
    }

    // Check for time conflicts
    if (_currentWeekPlan != null) {
      final conflictingSessions = _findTimeConflicts(_currentWeekPlan!.sessions);
      if (conflictingSessions.isNotEmpty) {
        suggestions.add('⚠️ Resolve ${conflictingSessions.length} time conflicts in your schedule');
      }
    }

    return suggestions;
  }

  List<StudySession> _findTimeConflicts(List<StudySession> sessions) {
    final conflicts = <StudySession>[];
    final sortedSessions = List<StudySession>.from(sessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (int i = 0; i < sortedSessions.length - 1; i++) {
      final current = sortedSessions[i];
      final next = sortedSessions[i + 1];

      if (current.endTime.isAfter(next.startTime)) {
        conflicts.add(current);
        conflicts.add(next);
      }
    }

    return conflicts;
  }
}