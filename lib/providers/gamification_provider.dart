import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/achievement.dart';
import '../models/task.dart';

class GamificationProvider with ChangeNotifier {
  UserProgress _userProgress = UserProgress();
  List<Achievement> _availableAchievements = Achievement.getDefaultAchievements();
  static const String _progressKey = 'user_progress';
  static const String _achievementsKey = 'achievements';

  GamificationProvider() {
    _loadProgress();
  }

  UserProgress get userProgress => _userProgress;
  List<Achievement> get availableAchievements => _availableAchievements;
  List<Achievement> get unlockedAchievements => _availableAchievements.where((a) => a.isUnlocked).toList();

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user progress
      final progressJson = prefs.getString(_progressKey);
      if (progressJson != null) {
        _userProgress = UserProgress.fromJson(jsonDecode(progressJson));
      }

      // Load achievements
      final achievementsJson = prefs.getString(_achievementsKey);
      if (achievementsJson != null) {
        final List<dynamic> achievementsList = jsonDecode(achievementsJson);
        _availableAchievements = achievementsList.map((json) => Achievement.fromJson(json)).toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading gamification progress: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_progressKey, jsonEncode(_userProgress.toJson()));
      await prefs.setString(_achievementsKey, jsonEncode(_availableAchievements.map((a) => a.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving gamification progress: $e');
    }
  }

  void onTaskCompleted(Task task) {
    // Add points for completing task
    final points = task.pointsValue;
    _addPoints(points);

    // Update task completion count
    _userProgress = _userProgress.copyWith(
      totalTasksCompleted: _userProgress.totalTasksCompleted + 1,
      lastActivityDate: DateTime.now(),
    );

    // Update streak
    _updateStreak();

    // Check for achievements
    _checkAchievements();

    _saveProgress();
    notifyListeners();
  }

  void onFocusSessionCompleted(Duration sessionTime) {
    // Add points for focus time (1 point per minute)
    _addPoints(sessionTime.inMinutes);

    // Update total focus time
    _userProgress = _userProgress.copyWith(
      totalFocusTime: _userProgress.totalFocusTime + sessionTime,
      lastActivityDate: DateTime.now(),
    );

    // Check for achievements
    _checkAchievements();

    _saveProgress();
    notifyListeners();
  }

  void _addPoints(int points) {
    final newTotalPoints = _userProgress.totalPoints + points;
    final newLevel = (newTotalPoints / 1000).floor() + 1;

    _userProgress = _userProgress.copyWith(
      totalPoints: newTotalPoints,
      level: newLevel > _userProgress.level ? newLevel : _userProgress.level,
    );
  }

  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActivity = _userProgress.lastActivityDate;

    if (lastActivity == null) {
      // First activity
      _userProgress = _userProgress.copyWith(currentStreak: 1);
    } else {
      final lastActivityDate = DateTime(lastActivity.year, lastActivity.month, lastActivity.day);
      final daysDifference = today.difference(lastActivityDate).inDays;

      if (daysDifference == 0) {
        // Same day, streak continues
        return;
      } else if (daysDifference == 1) {
        // Next day, increment streak
        final newStreak = _userProgress.currentStreak + 1;
        _userProgress = _userProgress.copyWith(
          currentStreak: newStreak,
          longestStreak: newStreak > _userProgress.longestStreak ? newStreak : _userProgress.longestStreak,
        );
      } else {
        // Streak broken
        _userProgress = _userProgress.copyWith(currentStreak: 1);
      }
    }
  }

  void _checkAchievements() {
    final newUnlockedAchievements = <Achievement>[];

    for (int i = 0; i < _availableAchievements.length; i++) {
      final achievement = _availableAchievements[i];
      if (!achievement.isUnlocked && _shouldUnlockAchievement(achievement)) {
        final unlockedAchievement = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        _availableAchievements[i] = unlockedAchievement;
        newUnlockedAchievements.add(unlockedAchievement);
        _addPoints(achievement.points);
      }
    }

    // Show achievement notifications
    for (final achievement in newUnlockedAchievements) {
      _showAchievementNotification(achievement);
    }
  }

  bool _shouldUnlockAchievement(Achievement achievement) {
    switch (achievement.type) {
      case AchievementType.tasksCompleted:
        return _userProgress.totalTasksCompleted >= achievement.targetValue;
      case AchievementType.streak:
        return _userProgress.currentStreak >= achievement.targetValue;
      case AchievementType.focusTime:
        return _userProgress.totalFocusTime.inMinutes >= achievement.targetValue;
      case AchievementType.perfectDay:
return false;
      case AchievementType.earlyBird:
return false;
      case AchievementType.nightOwl:
return false;
      case AchievementType.productivity:
        return _userProgress.level >= achievement.targetValue;
    }
  }

  void _showAchievementNotification(Achievement achievement) {
debugPrint('Achievement Unlocked: ${achievement.title}');
  }

  // Get today's tasks completion for perfect day calculation
  bool checkPerfectDay(List<Task> todayTasks) {
    if (todayTasks.isEmpty) return false;
    return todayTasks.every((task) => task.isCompleted);
  }

  // Reset daily achievements if needed
  void checkDailyReset() {
    final now = DateTime.now();
    final lastActivity = _userProgress.lastActivityDate;

    if (lastActivity != null) {
      final daysDifference = now.difference(lastActivity).inDays;
      if (daysDifference > 1) {
        // Reset streak if more than 1 day gap
        _userProgress = _userProgress.copyWith(currentStreak: 0);
        _saveProgress();
        notifyListeners();
      }
    }
  }
}