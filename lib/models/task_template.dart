import 'task.dart';

class TaskTemplate {
  final String id;
  final String name;
  final String title;
  final String? subject;
  final TaskCategory category;
  final int priority;
  final int difficultyLevel;
  final Duration? estimatedTime;
  final List<String> tags;
  final String? notes;
  final bool isRecurring;
  final int? dueDaysFromNow; // How many days from creation should this be due
  final List<TaskTemplate> subtaskTemplates;

  TaskTemplate({
    required this.id,
    required this.name,
    required this.title,
    this.subject,
    this.category = TaskCategory.other,
    this.priority = 2,
    this.difficultyLevel = 3,
    this.estimatedTime,
    this.tags = const [],
    this.notes,
    this.isRecurring = false,
    this.dueDaysFromNow,
    this.subtaskTemplates = const [],
  });

  Task createTask({DateTime? customDueDate}) {
    final now = DateTime.now();
    final dueDate = customDueDate ??
        (dueDaysFromNow != null
            ? now.add(Duration(days: dueDaysFromNow!))
            : now.add(const Duration(days: 1)));

    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      subject: subject,
      dueDate: dueDate,
      category: category,
      priority: priority,
      difficultyLevel: difficultyLevel,
      estimatedTime: estimatedTime,
      tags: List.from(tags),
      notes: notes,
      isRecurring: isRecurring,
      createdAt: now,
    );
  }

  List<Task> createTaskWithSubtasks({DateTime? customDueDate}) {
    final tasks = <Task>[];
    final mainTask = createTask(customDueDate: customDueDate);
    tasks.add(mainTask);

    // Create subtasks
    for (final subtaskTemplate in subtaskTemplates) {
      final subtask = subtaskTemplate.createTask(customDueDate: customDueDate);
      final updatedSubtask = subtask.copyWith(
        parentTaskId: mainTask.id,
        title: '${mainTask.title} - ${subtask.title}',
      );
      tasks.add(updatedSubtask);
    }

    return tasks;
  }

  TaskTemplate copyWith({
    String? id,
    String? name,
    String? title,
    String? subject,
    TaskCategory? category,
    int? priority,
    int? difficultyLevel,
    Duration? estimatedTime,
    List<String>? tags,
    String? notes,
    bool? isRecurring,
    int? dueDaysFromNow,
    List<TaskTemplate>? subtaskTemplates,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      dueDaysFromNow: dueDaysFromNow ?? this.dueDaysFromNow,
      subtaskTemplates: subtaskTemplates ?? this.subtaskTemplates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'subject': subject,
      'category': category.name,
      'priority': priority,
      'difficultyLevel': difficultyLevel,
      'estimatedTime': estimatedTime?.inMinutes,
      'tags': tags,
      'notes': notes,
      'isRecurring': isRecurring,
      'dueDaysFromNow': dueDaysFromNow,
      'subtaskTemplates': subtaskTemplates.map((t) => t.toJson()).toList(),
    };
  }

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      subject: json['subject'],
      category: TaskCategory.values.firstWhere(
        (c) => c.name == (json['category'] ?? 'other'),
        orElse: () => TaskCategory.other,
      ),
      priority: json['priority'] ?? 2,
      difficultyLevel: json['difficultyLevel'] ?? 3,
      estimatedTime: json['estimatedTime'] != null
          ? Duration(minutes: json['estimatedTime'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      notes: json['notes'],
      isRecurring: json['isRecurring'] ?? false,
      dueDaysFromNow: json['dueDaysFromNow'],
      subtaskTemplates: (json['subtaskTemplates'] as List?)
          ?.map((t) => TaskTemplate.fromJson(t))
          .toList() ?? [],
    );
  }

  static List<TaskTemplate> getDefaultTemplates() {
    return [
      // Study Session Templates
      TaskTemplate(
        id: 'study_session_math',
        name: 'Math Study Session',
        title: 'Study Math',
        subject: 'Math',
        category: TaskCategory.homework,
        priority: 2,
        difficultyLevel: 3,
        estimatedTime: const Duration(hours: 1),
        tags: ['study', 'math'],
        notes: 'Review notes and practice problems',
        dueDaysFromNow: 1,
      ),
      TaskTemplate(
        id: 'reading_assignment',
        name: 'Reading Assignment',
        title: 'Complete Reading Assignment',
        category: TaskCategory.reading,
        priority: 2,
        difficultyLevel: 2,
        estimatedTime: const Duration(minutes: 45),
        tags: ['reading', 'assignment'],
        dueDaysFromNow: 3,
      ),

      // Project Templates
      TaskTemplate(
        id: 'research_project',
        name: 'Research Project',
        title: 'Research Project',
        category: TaskCategory.project,
        priority: 3,
        difficultyLevel: 4,
        estimatedTime: const Duration(hours: 8),
        tags: ['research', 'project'],
        dueDaysFromNow: 14,
        subtaskTemplates: [
          TaskTemplate(
            id: 'research_phase',
            name: 'Research Phase',
            title: 'Research and gather sources',
            category: TaskCategory.reading,
            priority: 3,
            difficultyLevel: 3,
            estimatedTime: const Duration(hours: 3),
            tags: ['research'],
            dueDaysFromNow: 7,
          ),
          TaskTemplate(
            id: 'outline_phase',
            name: 'Create Outline',
            title: 'Create project outline',
            category: TaskCategory.project,
            priority: 3,
            difficultyLevel: 3,
            estimatedTime: const Duration(hours: 1),
            tags: ['outline'],
            dueDaysFromNow: 10,
          ),
          TaskTemplate(
            id: 'writing_phase',
            name: 'Writing Phase',
            title: 'Write first draft',
            category: TaskCategory.project,
            priority: 3,
            difficultyLevel: 4,
            estimatedTime: const Duration(hours: 4),
            tags: ['writing'],
            dueDaysFromNow: 12,
          ),
        ],
      ),

      // Exam Preparation
      TaskTemplate(
        id: 'exam_prep',
        name: 'Exam Preparation',
        title: 'Prepare for Exam',
        category: TaskCategory.exam,
        priority: 3,
        difficultyLevel: 4,
        estimatedTime: const Duration(hours: 6),
        tags: ['exam', 'study'],
        dueDaysFromNow: 7,
        subtaskTemplates: [
          TaskTemplate(
            id: 'review_notes',
            name: 'Review Notes',
            title: 'Review all class notes',
            category: TaskCategory.review,
            priority: 3,
            difficultyLevel: 3,
            estimatedTime: const Duration(hours: 2),
            tags: ['review', 'notes'],
            dueDaysFromNow: 5,
          ),
          TaskTemplate(
            id: 'practice_problems',
            name: 'Practice Problems',
            title: 'Complete practice problems',
            category: TaskCategory.homework,
            priority: 3,
            difficultyLevel: 4,
            estimatedTime: const Duration(hours: 3),
            tags: ['practice'],
            dueDaysFromNow: 3,
          ),
          TaskTemplate(
            id: 'final_review',
            name: 'Final Review',
            title: 'Final review session',
            category: TaskCategory.review,
            priority: 3,
            difficultyLevel: 3,
            estimatedTime: const Duration(hours: 1),
            tags: ['review'],
            dueDaysFromNow: 1,
          ),
        ],
      ),

      // Lab Assignment
      TaskTemplate(
        id: 'lab_assignment',
        name: 'Lab Assignment',
        title: 'Complete Lab Assignment',
        category: TaskCategory.lab,
        priority: 2,
        difficultyLevel: 3,
        estimatedTime: const Duration(hours: 3),
        tags: ['lab', 'assignment'],
        dueDaysFromNow: 7,
      ),

      // Quick Templates
      TaskTemplate(
        id: 'quick_review',
        name: 'Quick Review',
        title: 'Quick Review Session',
        category: TaskCategory.review,
        priority: 1,
        difficultyLevel: 2,
        estimatedTime: const Duration(minutes: 30),
        tags: ['review', 'quick'],
        dueDaysFromNow: 1,
      ),
      TaskTemplate(
        id: 'practice_quiz',
        name: 'Practice Quiz',
        title: 'Take Practice Quiz',
        category: TaskCategory.quiz,
        priority: 2,
        difficultyLevel: 3,
        estimatedTime: const Duration(minutes: 45),
        tags: ['quiz', 'practice'],
        dueDaysFromNow: 2,
      ),

      // Weekly Templates
      TaskTemplate(
        id: 'weekly_review',
        name: 'Weekly Review',
        title: 'Weekly Subject Review',
        category: TaskCategory.review,
        priority: 2,
        difficultyLevel: 2,
        estimatedTime: const Duration(hours: 1, minutes: 30),
        tags: ['weekly', 'review'],
        isRecurring: true,
        dueDaysFromNow: 7,
      ),
    ];
  }
}