class FocusSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final bool isBreak;
  final bool isCompleted;

  FocusSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.isBreak,
    this.isCompleted = false,
  });

  FocusSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    bool? isBreak,
    bool? isCompleted,
  }) {
    return FocusSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      isBreak: isBreak ?? this.isBreak,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Duration get actualDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return duration;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inMilliseconds,
      'isBreak': isBreak,
      'isCompleted': isCompleted,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: Duration(milliseconds: json['duration']),
      isBreak: json['isBreak'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}