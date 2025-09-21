enum TaskCategory { homework, project, exam, reading, lab, quiz, review, other }
enum TaskStatus { pending, inProgress, completed, overdue }

class Task {
  final String id;
  final String title;
  final String? subject;
  final DateTime dueDate; // Now includes time
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Duration timeSpent;
  final Duration? estimatedTime;
  final String? notes;
  final int priority; // 1=Low, 2=Medium, 3=High
  final TaskCategory category;
  final List<String> tags;
  final String? parentTaskId; // For subtasks
  final bool isRecurring;
  final int difficultyLevel; // 1-5 for gamification

  Task({
    required this.id,
    required this.title,
    this.subject,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.timeSpent = Duration.zero,
    this.estimatedTime,
    this.notes,
    this.priority = 2,
    this.category = TaskCategory.other,
    this.tags = const [],
    this.parentTaskId,
    this.isRecurring = false,
    this.difficultyLevel = 3,
  });

  Task copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    Duration? timeSpent,
    Duration? estimatedTime,
    String? notes,
    int? priority,
    TaskCategory? category,
    List<String>? tags,
    String? parentTaskId,
    bool? isRecurring,
    int? difficultyLevel,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      timeSpent: timeSpent ?? this.timeSpent,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      isRecurring: isRecurring ?? this.isRecurring,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'timeSpent': timeSpent.inMinutes,
      'estimatedTime': estimatedTime?.inMinutes,
      'notes': notes,
      'priority': priority,
      'category': category.name,
      'tags': tags,
      'parentTaskId': parentTaskId,
      'isRecurring': isRecurring,
      'difficultyLevel': difficultyLevel,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      subject: json['subject'],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      timeSpent: Duration(minutes: json['timeSpent'] ?? 0),
      estimatedTime: json['estimatedTime'] != null ? Duration(minutes: json['estimatedTime']) : null,
      notes: json['notes'],
      priority: json['priority'] ?? 2,
      category: TaskCategory.values.firstWhere(
        (c) => c.name == (json['category'] ?? 'other'),
        orElse: () => TaskCategory.other,
      ),
      tags: List<String>.from(json['tags'] ?? []),
      parentTaskId: json['parentTaskId'],
      isRecurring: json['isRecurring'] ?? false,
      difficultyLevel: json['difficultyLevel'] ?? 3,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 1: return 'Low';
      case 2: return 'Medium';
      case 3: return 'High';
      default: return 'Medium';
    }
  }

  String get timeSpentFormatted {
    if (timeSpent.inHours > 0) {
      return '${timeSpent.inHours}h ${timeSpent.inMinutes % 60}m';
    }
    return '${timeSpent.inMinutes}m';
  }

  String get categoryLabel {
    switch (category) {
      case TaskCategory.homework: return 'Homework';
      case TaskCategory.project: return 'Project';
      case TaskCategory.exam: return 'Exam';
      case TaskCategory.reading: return 'Reading';
      case TaskCategory.lab: return 'Lab';
      case TaskCategory.quiz: return 'Quiz';
      case TaskCategory.review: return 'Review';
      case TaskCategory.other: return 'Other';
    }
  }

  TaskStatus get status {
    if (isCompleted) return TaskStatus.completed;
    if (DateTime.now().isAfter(dueDate)) return TaskStatus.overdue;
    if (timeSpent.inMinutes > 0) return TaskStatus.inProgress;
    return TaskStatus.pending;
  }

  String get difficultyLabel {
    switch (difficultyLevel) {
      case 1: return 'Very Easy';
      case 2: return 'Easy';
      case 3: return 'Medium';
      case 4: return 'Hard';
      case 5: return 'Very Hard';
      default: return 'Medium';
    }
  }

  int get pointsValue {
    // Points based on difficulty and priority
    return (difficultyLevel * priority * 10);
  }

  Duration get timeUntilDue {
    return dueDate.difference(DateTime.now());
  }

  bool get isOverdue {
    return DateTime.now().isAfter(dueDate) && !isCompleted;
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return taskDate.isAtSameMomentAs(today);
  }

  bool get isDueSoon {
    return timeUntilDue.inHours <= 24 && timeUntilDue.inHours > 0;
  }
}