import 'package:flutter/material.dart';

enum ScheduleType {
  class_,
  work,
  meal,
  sleep,
  commute,
  personal,
  unavailable
}

enum StudyPreference {
  earlyMorning,   // 6-9 AM
  lateMorning,    // 9-12 PM
  earlyAfternoon, // 12-3 PM
  lateAfternoon,  // 3-6 PM
  evening,        // 6-9 PM
  night,          // 9 PM+
  noPreference
}

enum EnergyLevel {
  veryLow,
  low,
  medium,
  high,
  veryHigh
}

class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<int> weekdays; // 1=Monday, 7=Sunday
  final ScheduleType type;
  final String? title;
  final String? location;
  final bool isRecurring;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.weekdays,
    required this.type,
    this.title,
    this.location,
    this.isRecurring = true,
  });

  Duration get duration => Duration(
    hours: endTime.hour - startTime.hour,
    minutes: endTime.minute - startTime.minute,
  );

  bool conflictsWith(TimeSlot other, int weekday) {
    if (!weekdays.contains(weekday) || !other.weekdays.contains(weekday)) {
      return false;
    }

    final thisStart = startTime.hour * 60 + startTime.minute;
    final thisEnd = endTime.hour * 60 + endTime.minute;
    final otherStart = other.startTime.hour * 60 + other.startTime.minute;
    final otherEnd = other.endTime.hour * 60 + other.endTime.minute;

    return !(thisEnd <= otherStart || thisStart >= otherEnd);
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'weekdays': weekdays,
      'type': type.name,
      'title': title,
      'location': location,
      'isRecurring': isRecurring,
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: TimeOfDay(
        hour: json['startTime']['hour'],
        minute: json['startTime']['minute'],
      ),
      endTime: TimeOfDay(
        hour: json['endTime']['hour'],
        minute: json['endTime']['minute'],
      ),
      weekdays: List<int>.from(json['weekdays']),
      type: ScheduleType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'],
      location: json['location'],
      isRecurring: json['isRecurring'] ?? true,
    );
  }
}

class StudentStudySession {
  final DateTime dateTime;
  final Duration duration;
  final bool wasCompleted;
  final double productivityRating; // 1-5 scale
  final EnergyLevel energyLevel;
  final String? subject;
  final List<String> distractions;

  StudentStudySession({
    required this.dateTime,
    required this.duration,
    required this.wasCompleted,
    required this.productivityRating,
    required this.energyLevel,
    this.subject,
    this.distractions = const [],
  });

  TimeOfDay get timeOfDay => TimeOfDay.fromDateTime(dateTime);
  int get weekday => dateTime.weekday;

  Map<String, dynamic> toJson() {
    return {
      'dateTime': dateTime.toIso8601String(),
      'duration': duration.inMinutes,
      'wasCompleted': wasCompleted,
      'productivityRating': productivityRating,
      'energyLevel': energyLevel.name,
      'subject': subject,
      'distractions': distractions,
    };
  }

  factory StudentStudySession.fromJson(Map<String, dynamic> json) {
    return StudentStudySession(
      dateTime: DateTime.parse(json['dateTime']),
      duration: Duration(minutes: json['duration']),
      wasCompleted: json['wasCompleted'],
      productivityRating: json['productivityRating'].toDouble(),
      energyLevel: EnergyLevel.values.firstWhere((e) => e.name == json['energyLevel']),
      subject: json['subject'],
      distractions: List<String>.from(json['distractions'] ?? []),
    );
  }
}

class StudentSchedule {
  final String id;
  final List<TimeSlot> busySlots; // Classes, work, etc.
  final List<StudyPreference> preferredStudyTimes;
  final Map<int, List<TimeOfDay>> freeTimeWindows; // weekday -> available times
  final Duration preferredStudyDuration;
  final Duration minimumBreakBetweenSessions;
  final List<StudentStudySession> pastStudySessions;
  final Map<String, double> subjectProductivityByTime; // "Monday-9" -> 0.8

  StudentSchedule({
    required this.id,
    this.busySlots = const [],
    this.preferredStudyTimes = const [],
    this.freeTimeWindows = const {},
    this.preferredStudyDuration = const Duration(minutes: 45),
    this.minimumBreakBetweenSessions = const Duration(minutes: 15),
    this.pastStudySessions = const [],
    this.subjectProductivityByTime = const {},
  });

  // Find all available time slots for a given day
  List<TimeSlot> getAvailableSlots(int weekday, {Duration? minDuration}) {
    final available = <TimeSlot>[];
    final duration = minDuration ?? preferredStudyDuration;

    // Default available times if none specified
    final defaultTimes = freeTimeWindows[weekday] ?? [
      const TimeOfDay(hour: 8, minute: 0),
      const TimeOfDay(hour: 12, minute: 0),
      const TimeOfDay(hour: 16, minute: 0),
      const TimeOfDay(hour: 19, minute: 0),
    ];

    for (final startTime in defaultTimes) {
      final endTime = _addDurationToTime(startTime, duration);
      final slot = TimeSlot(
        startTime: startTime,
        endTime: endTime,
        weekdays: [weekday],
        type: ScheduleType.personal,
        title: 'Available Study Time',
      );

      // Check if this slot conflicts with any busy slots
      final hasConflict = busySlots.any((busy) => busy.conflictsWith(slot, weekday));

      if (!hasConflict) {
        available.add(slot);
      }
    }

    return available;
  }

  // Get optimal study time based on past performance
  TimeSlot? getOptimalStudyTime(int weekday, String? subject) {
    final availableSlots = getAvailableSlots(weekday);
    if (availableSlots.isEmpty) return null;

    // Score each slot based on past productivity
    TimeSlot? bestSlot;
    double bestScore = 0.0;

    for (final slot in availableSlots) {
      double score = _calculateTimeSlotScore(slot, subject);
      if (score > bestScore) {
        bestScore = score;
        bestSlot = slot;
      }
    }

    return bestSlot;
  }

  double _calculateTimeSlotScore(TimeSlot slot, String? subject) {
    double score = 0.5; // Base score

    // Check past productivity at this time
    final timeKey = '${slot.weekdays.first}-${slot.startTime.hour}';
    final pastProductivity = subjectProductivityByTime[timeKey];
    if (pastProductivity != null) {
      score = pastProductivity;
    }

    // Boost score for preferred study times
    final timeCategory = _categorizeTime(slot.startTime);
    if (preferredStudyTimes.contains(timeCategory)) {
      score += 0.2;
    }

    // Consider energy patterns from past sessions
    final energyAtTime = _getAverageEnergyAtTime(slot.startTime, slot.weekdays.first);
    score += (energyAtTime.index / EnergyLevel.values.length) * 0.3;

    return score.clamp(0.0, 1.0);
  }

  StudyPreference _categorizeTime(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 9) return StudyPreference.earlyMorning;
    if (hour >= 9 && hour < 12) return StudyPreference.lateMorning;
    if (hour >= 12 && hour < 15) return StudyPreference.earlyAfternoon;
    if (hour >= 15 && hour < 18) return StudyPreference.lateAfternoon;
    if (hour >= 18 && hour < 21) return StudyPreference.evening;
    return StudyPreference.night;
  }

  EnergyLevel _getAverageEnergyAtTime(TimeOfDay time, int weekday) {
    final relevantSessions = pastStudySessions.where((session) =>
      session.weekday == weekday &&
      (session.timeOfDay.hour - time.hour).abs() <= 1
    ).toList();

    if (relevantSessions.isEmpty) return EnergyLevel.medium;

    final avgEnergy = relevantSessions
        .map((s) => s.energyLevel.index)
        .reduce((a, b) => a + b) / relevantSessions.length;

    return EnergyLevel.values[avgEnergy.round().clamp(0, EnergyLevel.values.length - 1)];
  }

  TimeOfDay _addDurationToTime(TimeOfDay time, Duration duration) {
    final totalMinutes = time.hour * 60 + time.minute + duration.inMinutes;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  StudentSchedule copyWith({
    String? id,
    List<TimeSlot>? busySlots,
    List<StudyPreference>? preferredStudyTimes,
    Map<int, List<TimeOfDay>>? freeTimeWindows,
    Duration? preferredStudyDuration,
    Duration? minimumBreakBetweenSessions,
    List<StudentStudySession>? pastStudySessions,
    Map<String, double>? subjectProductivityByTime,
  }) {
    return StudentSchedule(
      id: id ?? this.id,
      busySlots: busySlots ?? this.busySlots,
      preferredStudyTimes: preferredStudyTimes ?? this.preferredStudyTimes,
      freeTimeWindows: freeTimeWindows ?? this.freeTimeWindows,
      preferredStudyDuration: preferredStudyDuration ?? this.preferredStudyDuration,
      minimumBreakBetweenSessions: minimumBreakBetweenSessions ?? this.minimumBreakBetweenSessions,
      pastStudySessions: pastStudySessions ?? this.pastStudySessions,
      subjectProductivityByTime: subjectProductivityByTime ?? this.subjectProductivityByTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'busySlots': busySlots.map((slot) => slot.toJson()).toList(),
      'preferredStudyTimes': preferredStudyTimes.map((pref) => pref.name).toList(),
      'freeTimeWindows': freeTimeWindows.map(
        (weekday, times) => MapEntry(
          weekday.toString(),
          times.map((time) => {'hour': time.hour, 'minute': time.minute}).toList(),
        ),
      ),
      'preferredStudyDuration': preferredStudyDuration.inMinutes,
      'minimumBreakBetweenSessions': minimumBreakBetweenSessions.inMinutes,
      'pastStudySessions': pastStudySessions.map((session) => session.toJson()).toList(),
      'subjectProductivityByTime': subjectProductivityByTime,
    };
  }

  factory StudentSchedule.fromJson(Map<String, dynamic> json) {
    return StudentSchedule(
      id: json['id'],
      busySlots: (json['busySlots'] as List?)
          ?.map((slot) => TimeSlot.fromJson(slot))
          .toList() ?? [],
      preferredStudyTimes: (json['preferredStudyTimes'] as List?)
          ?.map((pref) => StudyPreference.values.firstWhere((e) => e.name == pref))
          .toList() ?? [],
      freeTimeWindows: (json['freeTimeWindows'] as Map<String, dynamic>?)?.map(
        (weekday, times) => MapEntry(
          int.parse(weekday),
          (times as List).map((time) => TimeOfDay(hour: time['hour'], minute: time['minute'])).toList(),
        ),
      ) ?? {},
      preferredStudyDuration: Duration(minutes: json['preferredStudyDuration'] ?? 45),
      minimumBreakBetweenSessions: Duration(minutes: json['minimumBreakBetweenSessions'] ?? 15),
      pastStudySessions: (json['pastStudySessions'] as List?)
          ?.map((session) => StudentStudySession.fromJson(session))
          .toList() ?? [],
      subjectProductivityByTime: Map<String, double>.from(json['subjectProductivityByTime'] ?? {}),
    );
  }
}