enum AchievementType {
  streak,
  tasksCompleted,
  focusTime,
  perfectDay,
  earlyBird,
  nightOwl,
  productivity,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final int targetValue;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.targetValue,
    required this.points,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    int? targetValue,
    int? points,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      points: points ?? this.points,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.name,
      'targetValue': targetValue,
      'points': points,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
      type: AchievementType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AchievementType.productivity,
      ),
      targetValue: json['targetValue'],
      points: json['points'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }

  static List<Achievement> getDefaultAchievements() {
    return [
      Achievement(
        id: 'first_task',
        title: 'Getting Started',
        description: 'Complete your first task',
icon: 'target',
        type: AchievementType.tasksCompleted,
        targetValue: 1,
        points: 50,
      ),
      Achievement(
        id: 'streak_3',
        title: 'On Fire',
        description: 'Complete tasks for 3 days in a row',
icon: 'fire',
        type: AchievementType.streak,
        targetValue: 3,
        points: 100,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Complete tasks for 7 days in a row',
icon: 'bolt',
        type: AchievementType.streak,
        targetValue: 7,
        points: 250,
      ),
      Achievement(
        id: 'tasks_10',
        title: 'Task Master',
        description: 'Complete 10 tasks',
icon: 'check',
        type: AchievementType.tasksCompleted,
        targetValue: 10,
        points: 150,
      ),
      Achievement(
        id: 'tasks_50',
        title: 'Productivity Pro',
        description: 'Complete 50 tasks',
icon: 'trophy',
        type: AchievementType.tasksCompleted,
        targetValue: 50,
        points: 500,
      ),
      Achievement(
        id: 'focus_2h',
        title: 'Deep Focus',
        description: 'Focus for 2 hours in a day',
icon: 'brain',
        type: AchievementType.focusTime,
        targetValue: 120, // minutes
        points: 200,
      ),
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Complete a task before 8 AM',
icon: 'bird',
        type: AchievementType.earlyBird,
        targetValue: 1,
        points: 100,
      ),
      Achievement(
        id: 'perfect_day',
        title: 'Perfect Day',
        description: 'Complete all tasks for the day',
icon: 'star',
        type: AchievementType.perfectDay,
        targetValue: 1,
        points: 300,
      ),
    ];
  }
}

class UserProgress {
  final int totalPoints;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final int totalTasksCompleted;
  final Duration totalFocusTime;
  final List<Achievement> unlockedAchievements;
  final DateTime? lastActivityDate;

  UserProgress({
    this.totalPoints = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalTasksCompleted = 0,
    this.totalFocusTime = Duration.zero,
    this.unlockedAchievements = const [],
    this.lastActivityDate,
  });

  int get pointsForNextLevel => (level * 1000);
  int get progressToNextLevel => totalPoints % 1000;
  double get progressPercentage => progressToNextLevel / pointsForNextLevel;

  UserProgress copyWith({
    int? totalPoints,
    int? level,
    int? currentStreak,
    int? longestStreak,
    int? totalTasksCompleted,
    Duration? totalFocusTime,
    List<Achievement>? unlockedAchievements,
    DateTime? lastActivityDate,
  }) {
    return UserProgress(
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'level': level,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalTasksCompleted': totalTasksCompleted,
      'totalFocusTime': totalFocusTime.inMinutes,
      'unlockedAchievements': unlockedAchievements.map((a) => a.toJson()).toList(),
      'lastActivityDate': lastActivityDate?.toIso8601String(),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      totalPoints: json['totalPoints'] ?? 0,
      level: json['level'] ?? 1,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalTasksCompleted: json['totalTasksCompleted'] ?? 0,
      totalFocusTime: Duration(minutes: json['totalFocusTime'] ?? 0),
      unlockedAchievements: (json['unlockedAchievements'] as List?)
          ?.map((a) => Achievement.fromJson(a))
          .toList() ?? [],
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate'])
          : null,
    );
  }
}