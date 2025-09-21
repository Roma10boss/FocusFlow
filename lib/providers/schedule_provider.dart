import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/student_schedule.dart';

class ScheduleProvider with ChangeNotifier {
  StudentSchedule _schedule = StudentSchedule(id: 'default');
  static const String _scheduleKey = 'student_schedule';

  ScheduleProvider() {
    _loadSchedule();
  }

  StudentSchedule get schedule => _schedule;

  Future<void> _loadSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduleJson = prefs.getString(_scheduleKey);
      if (scheduleJson != null) {
        final Map<String, dynamic> data = jsonDecode(scheduleJson);
        _schedule = StudentSchedule.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    }
  }

  Future<void> _saveSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduleJson = jsonEncode(_schedule.toJson());
      await prefs.setString(_scheduleKey, scheduleJson);
    } catch (e) {
      debugPrint('Error saving schedule: $e');
    }
  }

  // Add a busy time slot (class, work, etc.)
  void addBusySlot(TimeSlot slot) {
    final updatedSlots = List<TimeSlot>.from(_schedule.busySlots)..add(slot);
    _schedule = _schedule.copyWith(busySlots: updatedSlots);
    _saveSchedule();
    notifyListeners();
  }

  // Remove a busy slot
  void removeBusySlot(int index) {
    final updatedSlots = List<TimeSlot>.from(_schedule.busySlots)..removeAt(index);
    _schedule = _schedule.copyWith(busySlots: updatedSlots);
    _saveSchedule();
    notifyListeners();
  }

  // Update study preferences
  void updateStudyPreferences(List<StudyPreference> preferences) {
    _schedule = _schedule.copyWith(preferredStudyTimes: preferences);
    _saveSchedule();
    notifyListeners();
  }

  // Set free time windows for a specific day
  void setFreeTimeWindows(int weekday, List<TimeOfDay> times) {
    final updatedWindows = Map<int, List<TimeOfDay>>.from(_schedule.freeTimeWindows);
    updatedWindows[weekday] = times;
    _schedule = _schedule.copyWith(freeTimeWindows: updatedWindows);
    _saveSchedule();
    notifyListeners();
  }

  // Record a completed study session for pattern learning
  void recordStudySession(StudentStudySession session) {
    final updatedSessions = List<StudentStudySession>.from(_schedule.pastStudySessions)..add(session);

    // Update productivity mapping
    final timeKey = '${session.weekday}-${session.timeOfDay.hour}';
    final updatedProductivity = Map<String, double>.from(_schedule.subjectProductivityByTime);
    updatedProductivity[timeKey] = session.productivityRating / 5.0; // Normalize to 0-1

    _schedule = _schedule.copyWith(
      pastStudySessions: updatedSessions,
      subjectProductivityByTime: updatedProductivity,
    );

    _saveSchedule();
    notifyListeners();
  }

  // Get available study slots for a specific day
  List<TimeSlot> getAvailableSlots(int weekday, {Duration? minDuration}) {
    return _schedule.getAvailableSlots(weekday, minDuration: minDuration);
  }

  // Get the optimal study time for a subject
  TimeSlot? getOptimalStudyTime(int weekday, String? subject) {
    return _schedule.getOptimalStudyTime(weekday, subject);
  }

  // Smart suggestions based on patterns
  List<String> getSmartSuggestions() {
    final suggestions = <String>[];

    // Analyze past sessions for patterns
    if (_schedule.pastStudySessions.isNotEmpty) {
      final recentSessions = _schedule.pastStudySessions
          .where((s) => DateTime.now().difference(s.dateTime).inDays <= 30)
          .toList();

      if (recentSessions.isNotEmpty) {
        // Find most productive time
        final productivityByHour = <int, double>{};
        for (final session in recentSessions) {
          final hour = session.timeOfDay.hour;
          productivityByHour[hour] = (productivityByHour[hour] ?? 0) + session.productivityRating;
        }

        final bestHour = productivityByHour.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

suggestions.add('You\'re most productive at ${bestHour}:00. Try scheduling more sessions then!');

        // Check for low energy patterns
        final lowEnergySessions = recentSessions
            .where((s) => s.energyLevel.index <= 1)
            .toList();

        if (lowEnergySessions.length > recentSessions.length * 0.3) {
suggestions.add('Consider shorter sessions or better breaks - you seem to have low energy often.');
        }

        // Subject-specific patterns
        final subjectStats = <String, List<double>>{};
        for (final session in recentSessions) {
          if (session.subject != null) {
            subjectStats[session.subject!] = (subjectStats[session.subject!] ?? [])
              ..add(session.productivityRating);
          }
        }

        subjectStats.forEach((subject, ratings) {
          final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
          if (avgRating < 3.0) {
suggestions.add('Consider changing your $subject study approach - recent sessions had lower ratings.');
          }
        });
      }
    }

    // Check for schedule conflicts
    final conflicts = _findScheduleConflicts();
    if (conflicts.isNotEmpty) {
      suggestions.add('⚠️ You have ${conflicts.length} potential schedule conflicts to resolve.');
    }

    // Suggest optimal times if none set
    if (_schedule.preferredStudyTimes.isEmpty) {
suggestions.add('Set your preferred study times in settings for better schedule suggestions!');
    }

    return suggestions;
  }

  List<String> _findScheduleConflicts() {
    final conflicts = <String>[];

    for (int i = 0; i < _schedule.busySlots.length; i++) {
      for (int j = i + 1; j < _schedule.busySlots.length; j++) {
        final slot1 = _schedule.busySlots[i];
        final slot2 = _schedule.busySlots[j];

        for (final weekday in slot1.weekdays) {
          if (slot1.conflictsWith(slot2, weekday)) {
            conflicts.add('${slot1.title} conflicts with ${slot2.title} on ${_getDayName(weekday)}');
          }
        }
      }
    }

    return conflicts;
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  // Import schedule from calendar or other source
  Future<void> importScheduleFromCalendar() async {
    // This would integrate with device calendar
    // For now, just a placeholder for future implementation
    debugPrint('Calendar import feature - coming soon!');
  }

  // Quick setup for common student schedules
  void setupQuickSchedule(String scheduleType) {
    List<TimeSlot> commonSlots = [];

    switch (scheduleType) {
      case 'morning_person':
        _schedule = _schedule.copyWith(
          preferredStudyTimes: [StudyPreference.earlyMorning, StudyPreference.lateMorning],
          freeTimeWindows: {
            1: [TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 8, minute: 0)], // Monday
            2: [TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 8, minute: 0)], // Tuesday
            3: [TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 8, minute: 0)], // Wednesday
            4: [TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 8, minute: 0)], // Thursday
            5: [TimeOfDay(hour: 6, minute: 0), TimeOfDay(hour: 8, minute: 0)], // Friday
          },
        );
        break;

      case 'night_owl':
        _schedule = _schedule.copyWith(
          preferredStudyTimes: [StudyPreference.evening, StudyPreference.night],
          freeTimeWindows: {
            1: [TimeOfDay(hour: 19, minute: 0), TimeOfDay(hour: 21, minute: 0)], // Monday
            2: [TimeOfDay(hour: 19, minute: 0), TimeOfDay(hour: 21, minute: 0)], // Tuesday
            3: [TimeOfDay(hour: 19, minute: 0), TimeOfDay(hour: 21, minute: 0)], // Wednesday
            4: [TimeOfDay(hour: 19, minute: 0), TimeOfDay(hour: 21, minute: 0)], // Thursday
            5: [TimeOfDay(hour: 19, minute: 0), TimeOfDay(hour: 21, minute: 0)], // Friday
          },
        );
        break;

      case 'typical_student':
        commonSlots = [
          TimeSlot(
            startTime: TimeOfDay(hour: 9, minute: 0),
            endTime: TimeOfDay(hour: 12, minute: 0),
            weekdays: [1, 3, 5], // MWF classes
            type: ScheduleType.class_,
            title: 'Morning Classes',
          ),
          TimeSlot(
            startTime: TimeOfDay(hour: 14, minute: 0),
            endTime: TimeOfDay(hour: 16, minute: 0),
            weekdays: [2, 4], // TTh classes
            type: ScheduleType.class_,
            title: 'Afternoon Classes',
          ),
        ];
        _schedule = _schedule.copyWith(
          busySlots: commonSlots,
          preferredStudyTimes: [StudyPreference.lateMorning, StudyPreference.lateAfternoon],
        );
        break;
    }

    _saveSchedule();
    notifyListeners();
  }

  // Analytics for study patterns
  Map<String, dynamic> getStudyAnalytics() {
    if (_schedule.pastStudySessions.isEmpty) {
      return {'message': 'No study data yet - complete some sessions to see analytics!'};
    }

    final recentSessions = _schedule.pastStudySessions
        .where((s) => DateTime.now().difference(s.dateTime).inDays <= 30)
        .toList();

    final totalSessions = recentSessions.length;
    final completedSessions = recentSessions.where((s) => s.wasCompleted).length;
    final avgProductivity = recentSessions.isNotEmpty
        ? recentSessions.map((s) => s.productivityRating).reduce((a, b) => a + b) / totalSessions
        : 0.0;

    // Find peak productivity hours
    final productivityByHour = <int, List<double>>{};
    for (final session in recentSessions) {
      final hour = session.timeOfDay.hour;
      productivityByHour[hour] = (productivityByHour[hour] ?? [])..add(session.productivityRating);
    }

    final peakHours = productivityByHour.entries
        .map((e) => {
          'hour': e.key,
          'avgRating': e.value.reduce((a, b) => a + b) / e.value.length,
          'sessionCount': e.value.length,
        })
        .toList()
      ..sort((a, b) => (b['avgRating'] as double).compareTo(a['avgRating'] as double));

    return {
      'totalSessions': totalSessions,
      'completionRate': totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0,
      'avgProductivity': avgProductivity,
      'peakHours': peakHours.take(3).toList(),
      'bestDay': _getBestStudyDay(recentSessions),
      'recommendations': _getPersonalizedRecommendations(recentSessions),
    };
  }

  String _getBestStudyDay(List<StudentStudySession> sessions) {
    final dayStats = <int, List<double>>{};
    for (final session in sessions) {
      dayStats[session.weekday] = (dayStats[session.weekday] ?? [])..add(session.productivityRating);
    }

    if (dayStats.isEmpty) return 'Not enough data';

    final bestDay = dayStats.entries
        .map((e) => {
          'weekday': e.key,
          'avgRating': e.value.reduce((a, b) => a + b) / e.value.length,
        })
        .reduce((a, b) => (a['avgRating'] as double) > (b['avgRating'] as double) ? a : b);

    return _getDayName(bestDay['weekday'] as int);
  }

  List<String> _getPersonalizedRecommendations(List<StudentStudySession> sessions) {
    final recommendations = <String>[];

    // Session length analysis
    final avgDuration = sessions.isNotEmpty
        ? sessions.map((s) => s.duration.inMinutes).reduce((a, b) => a + b) / sessions.length
        : 45;

    if (avgDuration > 90) {
      recommendations.add('Consider shorter sessions (45-60 min) for better focus');
    } else if (avgDuration < 30) {
      recommendations.add('Try longer sessions (45+ min) for deeper focus');
    }

    // Energy level patterns
    final lowEnergyCount = sessions.where((s) => s.energyLevel.index <= 1).length;
    if (lowEnergyCount > sessions.length * 0.4) {
      recommendations.add('Schedule sessions when you have higher energy levels');
    }

    // Completion rate
    final completionRate = sessions.where((s) => s.wasCompleted).length / sessions.length;
    if (completionRate < 0.7) {
      recommendations.add('Try setting smaller, more achievable study goals');
    }

    return recommendations;
  }
}