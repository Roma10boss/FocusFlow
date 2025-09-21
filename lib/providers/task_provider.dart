import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import 'gamification_provider.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  static const String _tasksKey = 'tasks';

  // Cache for expensive computations
  Map<TaskCategory, List<Task>>? _categoryCache;
  Map<String, List<Task>>? _subjectCache;
  int? _completionRateCache;
  DateTime? _lastCacheUpdate;
  GamificationProvider? _gamificationProvider;

  // Debouncing for notifications
  bool _isUpdating = false;

  TaskProvider() {
    _loadTasks();
  }

  void setGamificationProvider(GamificationProvider provider) {
    _gamificationProvider = provider;
  }

  List<Task> get tasks => _tasks;

  List<Task> get todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDate.isAtSameMomentAs(today) || taskDate.isBefore(today);
    }).toList();
  }

  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_tasksKey);
      if (tasksJson != null) {
        final List<dynamic> tasksList = jsonDecode(tasksJson);
        _tasks = tasksList.map((json) => Task.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList());
      await prefs.setString(_tasksKey, tasksJson);
    } catch (e) {
      debugPrint('Error saving tasks: $e');
    }
  }

  void addTask(Task task) {
    _tasks.add(task);
    _clearCache();
    _saveTasks();
    notifyListeners();
  }

  void updateTask(String id, Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _clearCache();
      _saveTasks();
      notifyListeners();
    }
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks[index];
      final wasCompleted = task.isCompleted;
      _tasks[index] = task.copyWith(
        isCompleted: !task.isCompleted,
        completedAt: !task.isCompleted ? DateTime.now() : null,
      );

      // Notify gamification system if task was just completed
      if (!wasCompleted && _tasks[index].isCompleted) {
        _gamificationProvider?.onTaskCompleted(_tasks[index]);
      }

      _clearCache();
      _saveTasks();
      notifyListeners();
    }
  }

  void addTimeToTask(String id, Duration timeToAdd) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        timeSpent: task.timeSpent + timeToAdd,
      );
      _saveTasks();
      notifyListeners();
    }
  }

  void editTask(String id, {
    String? title,
    String? subject,
    DateTime? dueDate,
    String? notes,
    int? priority,
  }) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        title: title,
        subject: subject,
        dueDate: dueDate,
        notes: notes,
        priority: priority,
      );
      _saveTasks();
      notifyListeners();
    }
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Task> get tasksByPriority {
    final sortedTasks = List<Task>.from(_tasks);
    sortedTasks.sort((a, b) => b.priority.compareTo(a.priority));
    return sortedTasks;
  }

  Duration get totalTimeSpentToday {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return _tasks.where((task) {
      final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
      return taskDate.isAtSameMomentAs(todayDate);
    }).fold(Duration.zero, (total, task) => total + task.timeSpent);
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    _saveTasks();
    notifyListeners();
  }

  // Enhanced filtering and sorting methods
  // Cache management methods
  void _clearCache() {
    _categoryCache = null;
    _subjectCache = null;
    _completionRateCache = null;
    _lastCacheUpdate = null;
  }

  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5; // Cache for 5 minutes
  }

  List<Task> getTasksByCategory(TaskCategory category) {
    return _tasks.where((task) => task.category == category).toList();
  }

  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  List<Task> get overdueTasks => _tasks.where((task) => task.isOverdue).toList();

  List<Task> get upcomingTasks {
    return _tasks.where((task) => !task.isCompleted && !task.isOverdue).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Task> getTasksByTag(String tag) {
    return _tasks.where((task) => task.tags.contains(tag)).toList();
  }

  List<Task> getTasksForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _tasks.where((task) {
      return task.dueDate.isAfter(weekStart) && task.dueDate.isBefore(weekEnd);
    }).toList();
  }

  Map<TaskCategory, List<Task>> get tasksByCategory {
    if (_categoryCache == null || !_isCacheValid()) {
      _categoryCache = {};
      for (final category in TaskCategory.values) {
        _categoryCache![category] = getTasksByCategory(category);
      }
      _lastCacheUpdate = DateTime.now();
    }
    return _categoryCache!;
  }

  Map<String, List<Task>> get tasksBySubject {
    if (_subjectCache == null || !_isCacheValid()) {
      _subjectCache = {};
      for (final task in _tasks) {
        final subject = task.subject ?? 'No Subject';
        _subjectCache![subject] = (_subjectCache![subject] ?? [])..add(task);
      }
      _lastCacheUpdate = DateTime.now();
    }
    return _subjectCache!;
  }

  // Statistics methods
  int get completionRate {
    if (_completionRateCache == null || !_isCacheValid()) {
      if (_tasks.isEmpty) {
        _completionRateCache = 0;
      } else {
        final completed = _tasks.where((task) => task.isCompleted).length;
        _completionRateCache = ((completed / _tasks.length) * 100).round();
      }
      _lastCacheUpdate = DateTime.now();
    }
    return _completionRateCache!;
  }

  Duration get totalTimeSpentThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return _tasks.where((task) {
      return task.createdAt.isAfter(weekStart) && task.createdAt.isBefore(weekEnd);
    }).fold(Duration.zero, (total, task) => total + task.timeSpent);
  }

  Map<TaskCategory, Duration> get timeSpentByCategory {
    final Map<TaskCategory, Duration> timeMap = {};
    for (final category in TaskCategory.values) {
      timeMap[category] = getTasksByCategory(category)
          .fold(Duration.zero, (total, task) => total + task.timeSpent);
    }
    return timeMap;
  }
}