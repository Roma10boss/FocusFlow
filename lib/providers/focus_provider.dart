import 'package:flutter/foundation.dart';
import '../models/focus_session.dart';

class FocusProvider with ChangeNotifier {
  List<FocusSession> _sessions = [];
  FocusSession? _currentSession;
  bool _isSessionActive = false;
  Duration _sessionDuration = const Duration(minutes: 25);
  Duration _breakDuration = const Duration(minutes: 5);

  List<FocusSession> get sessions => _sessions;
  FocusSession? get currentSession => _currentSession;
  bool get isSessionActive => _isSessionActive;
  Duration get sessionDuration => _sessionDuration;
  Duration get breakDuration => _breakDuration;

  void startSession() {
    _currentSession = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      duration: _sessionDuration,
      isBreak: false,
    );
    _isSessionActive = true;
    notifyListeners();
  }

  void startBreak() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        isCompleted: true,
      );
      _sessions.add(_currentSession!);
    }

    _currentSession = FocusSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      duration: _breakDuration,
      isBreak: true,
    );
    notifyListeners();
  }

  void endSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        isCompleted: true,
      );
      _sessions.add(_currentSession!);
      _currentSession = null;
    }
    _isSessionActive = false;
    notifyListeners();
  }

  void pauseSession() {
    _isSessionActive = false;
    notifyListeners();
  }

  void resumeSession() {
    _isSessionActive = true;
    notifyListeners();
  }

  Duration getTotalFocusTimeToday() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final todaySessions = _sessions.where((session) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      return sessionDate.isAtSameMomentAs(todayDate) && !session.isBreak;
    });

    return todaySessions.fold(
      Duration.zero,
      (total, session) => total + session.duration,
    );
  }

  List<FocusSession> getWeeklySessions() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _sessions.where((session) {
      return session.startTime.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  void setSessionDuration(Duration duration) {
    _sessionDuration = duration;
    notifyListeners();
  }

  void setBreakDuration(Duration duration) {
    _breakDuration = duration;
    notifyListeners();
  }
}