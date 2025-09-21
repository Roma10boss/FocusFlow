import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';

class MoodProvider with ChangeNotifier {
  List<MoodEntry> _moodEntries = [];
  MoodEntry? _todayMood;

  List<MoodEntry> get moodEntries => _moodEntries;
  MoodEntry? get todayMood => _todayMood;

  void addMoodEntry(MoodEntry entry) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Remove existing entry for today if it exists
    _moodEntries.removeWhere((entry) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return entryDate.isAtSameMomentAs(todayDate);
    });

    _moodEntries.add(entry);
    _todayMood = entry;
    notifyListeners();
  }

  void updateTodayMood(int moodLevel, String? notes) {
    final today = DateTime.now();
    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: today,
      moodLevel: moodLevel,
      notes: notes,
    );
    addMoodEntry(entry);
  }

  List<MoodEntry> getWeeklyMoods() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _moodEntries.where((entry) {
      return entry.date.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  double get averageMoodThisWeek {
    final weeklyMoods = getWeeklyMoods();
    if (weeklyMoods.isEmpty) return 0.0;
    final sum = weeklyMoods.fold(0, (sum, entry) => sum + entry.moodLevel);
    return sum / weeklyMoods.length;
  }
}