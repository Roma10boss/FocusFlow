import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task_template.dart';
import '../models/task.dart';

class TaskTemplateProvider with ChangeNotifier {
  List<TaskTemplate> _templates = [];
  static const String _templatesKey = 'task_templates';

  TaskTemplateProvider() {
    _loadTemplates();
  }

  List<TaskTemplate> get templates => _templates;
  List<TaskTemplate> get defaultTemplates => TaskTemplate.getDefaultTemplates();

  Future<void> _loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString(_templatesKey);
      if (templatesJson != null) {
        final List<dynamic> templatesList = jsonDecode(templatesJson);
        _templates = templatesList.map((json) => TaskTemplate.fromJson(json)).toList();
      } else {
        // Load default templates on first run
        _templates = TaskTemplate.getDefaultTemplates();
        _saveTemplates();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading task templates: $e');
      // Fallback to default templates
      _templates = TaskTemplate.getDefaultTemplates();
      notifyListeners();
    }
  }

  Future<void> _saveTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = jsonEncode(_templates.map((template) => template.toJson()).toList());
      await prefs.setString(_templatesKey, templatesJson);
    } catch (e) {
      debugPrint('Error saving task templates: $e');
    }
  }

  void addTemplate(TaskTemplate template) {
    _templates.add(template);
    _saveTemplates();
    notifyListeners();
  }

  void updateTemplate(String templateId, TaskTemplate updatedTemplate) {
    final index = _templates.indexWhere((template) => template.id == templateId);
    if (index != -1) {
      _templates[index] = updatedTemplate;
      _saveTemplates();
      notifyListeners();
    }
  }

  void deleteTemplate(String templateId) {
    _templates.removeWhere((template) => template.id == templateId);
    _saveTemplates();
    notifyListeners();
  }

  TaskTemplate? getTemplateById(String templateId) {
    try {
      return _templates.firstWhere((template) => template.id == templateId);
    } catch (e) {
      return null;
    }
  }

  List<TaskTemplate> getTemplatesByCategory(TaskCategory category) {
    return _templates.where((template) => template.category == category).toList();
  }

  List<TaskTemplate> getTemplatesBySubject(String subject) {
    return _templates.where((template) => template.subject == subject).toList();
  }

  List<TaskTemplate> searchTemplates(String query) {
    final lowerQuery = query.toLowerCase();
    return _templates.where((template) =>
      template.name.toLowerCase().contains(lowerQuery) ||
      template.title.toLowerCase().contains(lowerQuery) ||
      (template.subject?.toLowerCase().contains(lowerQuery) ?? false) ||
      template.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }

  Task createTaskFromTemplate(String templateId, {DateTime? customDueDate, String? customSubject}) {
    final template = getTemplateById(templateId);
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    final task = template.createTask(customDueDate: customDueDate);
    if (customSubject != null) {
      return task.copyWith(subject: customSubject);
    }
    return task;
  }

  List<Task> createTasksFromTemplate(String templateId, {DateTime? customDueDate, String? customSubject}) {
    final template = getTemplateById(templateId);
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    final tasks = template.createTaskWithSubtasks(customDueDate: customDueDate);
    if (customSubject != null) {
      return tasks.map((task) => task.copyWith(subject: customSubject)).toList();
    }
    return tasks;
  }

  // Get frequently used templates
  List<TaskTemplate> getPopularTemplates() {
    // In a real app, you'd track usage statistics
    // For now, return some commonly used templates
    return _templates.where((template) =>
      template.id == 'study_session_math' ||
      template.id == 'reading_assignment' ||
      template.id == 'quick_review' ||
      template.id == 'practice_quiz'
    ).toList();
  }

  // Get templates for a specific subject
  List<TaskTemplate> getTemplatesForSubject(String subject) {
    return _templates.where((template) =>
      template.subject?.toLowerCase() == subject.toLowerCase()
    ).toList();
  }

  // Create a template from an existing task
  void createTemplateFromTask(Task task, String templateName) {
    final template = TaskTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: templateName,
      title: task.title,
      subject: task.subject,
      category: task.category,
      priority: task.priority,
      difficultyLevel: task.difficultyLevel,
      estimatedTime: task.estimatedTime,
      tags: List.from(task.tags),
      notes: task.notes,
      isRecurring: task.isRecurring,
    );

    addTemplate(template);
  }

  // Reset to default templates
  void resetToDefaults() {
    _templates = TaskTemplate.getDefaultTemplates();
    _saveTemplates();
    notifyListeners();
  }

  // Get suggestions based on current tasks and patterns
  List<TaskTemplate> getSuggestedTemplates(List<Task> currentTasks) {
    final suggestions = <TaskTemplate>[];

    // Analyze current tasks to suggest relevant templates
    final subjects = currentTasks.map((task) => task.subject).whereType<String>().toSet();
    final categories = currentTasks.map((task) => task.category).toSet();

    // Suggest templates for subjects that have tasks
    for (final subject in subjects) {
      final subjectTemplates = getTemplatesForSubject(subject);
      suggestions.addAll(subjectTemplates.take(2)); // Limit to 2 per subject
    }

    // Suggest templates for categories that are commonly used
    for (final category in categories) {
      final categoryTemplates = getTemplatesByCategory(category);
      suggestions.addAll(categoryTemplates.take(1)); // Limit to 1 per category
    }

    // Add some popular templates if we don't have many suggestions
    if (suggestions.length < 3) {
      suggestions.addAll(getPopularTemplates().take(3 - suggestions.length));
    }

    // Remove duplicates
    final uniqueSuggestions = <TaskTemplate>[];
    final seenIds = <String>{};
    for (final template in suggestions) {
      if (!seenIds.contains(template.id)) {
        uniqueSuggestions.add(template);
        seenIds.add(template.id);
      }
    }

    return uniqueSuggestions.take(5).toList(); // Limit to 5 suggestions
  }
}