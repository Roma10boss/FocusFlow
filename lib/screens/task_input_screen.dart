import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/task_template_provider.dart';
import '../models/task.dart';
import '../services/ai_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/task_list_widget.dart';

class TaskInputScreen extends StatefulWidget {
  const TaskInputScreen({super.key});

  @override
  State<TaskInputScreen> createState() => _TaskInputScreenState();
}

class _TaskInputScreenState extends State<TaskInputScreen> {
  final _controller = TextEditingController();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)).copyWith(hour: 23, minute: 59);
  String? _selectedSubject;
  int _selectedPriority = 2;
  TaskCategory _selectedCategory = TaskCategory.other;
  int _selectedDifficulty = 3;
  Duration? _estimatedTime;
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  final List<String> _subjects = [
    'Math',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Computer Science',
    'Art',
    'Music',
    'Other'
  ];

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _controller.text.trim(),
        subject: _selectedSubject,
        dueDate: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        priority: _selectedPriority,
        category: _selectedCategory,
        difficultyLevel: _selectedDifficulty,
        estimatedTime: _estimatedTime,
        tags: List.from(_tags),
        createdAt: DateTime.now(),
      );

      if (mounted) {
        Provider.of<TaskProvider>(context, listen: false).addTask(task);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Task "${task.title}" added successfully!')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Clear form after successful creation
        _controller.clear();
        _notesController.clear();
        _tagController.clear();
        setState(() {
          _selectedSubject = null;
          _selectedPriority = 2;
          _selectedCategory = TaskCategory.other;
          _selectedDifficulty = 3;
          _estimatedTime = null;
          _tags.clear();
          _selectedDate = DateTime.now().add(const Duration(days: 1)).copyWith(hour: 23, minute: 59);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error adding task: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Manage Tasks'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF050315),
                    const Color(0xFF0F0B1A),
                    const Color(0xFF1E1B2E),
                    const Color(0xFF0F0B1A),
                  ]
                : [
                    const Color(0xFFFDF2F8),
                    const Color(0xFFF3E8FF),
                    const Color(0xFFEDE9FE),
                    const Color(0xFFFDF2F8),
                  ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'What do you need to do?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Describe your task naturally. We\'ll automatically detect subjects and due dates.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Task',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Task title',
                        border: OutlineInputBorder(),
                        labelText: 'Task Title',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a task title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No subject'),
                        ),
                        ..._subjects.map((subject) => DropdownMenuItem(
                          value: subject.toUpperCase(),
                          child: Text(subject),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TaskCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name.substring(0, 1).toUpperCase() +
                                    category.name.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value ?? TaskCategory.other;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Low')),
                        DropdownMenuItem(value: 2, child: Text('Medium')),
                        DropdownMenuItem(value: 3, child: Text('High')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value ?? 2;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedDifficulty,
                      decoration: const InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Very Easy')),
                        DropdownMenuItem(value: 2, child: Text('Easy')),
                        DropdownMenuItem(value: 3, child: Text('Medium')),
                        DropdownMenuItem(value: 4, child: Text('Hard')),
                        DropdownMenuItem(value: 5, child: Text('Very Hard')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value ?? 3;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                          );
                          if (time != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date & Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.schedule),
                        ),
                        child: Text(_formatDate(_selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final result = await showDialog<Duration>(
                          context: context,
                          builder: (context) => _EstimatedTimeDialog(initialTime: _estimatedTime),
                        );
                        if (result != null) {
                          setState(() {
                            _estimatedTime = result;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Estimated Time',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(_estimatedTime != null
                          ? '${_estimatedTime!.inHours}h ${_estimatedTime!.inMinutes % 60}m'
                          : 'Tap to set estimated time'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            labelText: 'Add Tags',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final tag = _tagController.text.trim();
                                if (tag.isNotEmpty && !_tags.contains(tag)) {
                                  setState(() {
                                    _tags.add(tag);
                                    _tagController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          onFieldSubmitted: (value) {
                            final tag = value.trim();
                            if (tag.isNotEmpty && !_tags.contains(tag)) {
                              setState(() {
                                _tags.add(tag);
                                _tagController.clear();
                              });
                            }
                          },
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _tags.map((tag) => Chip(
                              label: Text(tag),
                              onDeleted: () {
                                setState(() {
                                  _tags.remove(tag);
                                });
                              },
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _isLoading ? null : _addTask,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.add_task,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                const SizedBox(width: 12),
                                Text(
                                  _isLoading ? 'Creating Task...' : 'Create Task',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildQuickTemplates(),
              const SizedBox(height: 24),
              _buildExamples(),
              const SizedBox(height: 24),
              _buildTasksList(),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildQuickTemplates() {
    return Consumer<TaskTemplateProvider>(
      builder: (context, templateProvider, child) {
        final popularTemplates = templateProvider.getPopularTemplates();

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Templates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: popularTemplates.map((template) => GestureDetector(
                  onTap: () => _useTemplate(template),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForCategory(template.category),
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          template.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examples:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildExampleChip('"Study math for 2 hours today"'),
            _buildExampleChip('"Submit physics report by Friday"'),
            _buildExampleChip('"Review chemistry notes tomorrow"'),
            _buildExampleChip('"Finish history essay"'),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          _controller.text = example.replaceAll('"', '');
        },
        child: Chip(
          label: Text(example),
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.tasks;

        if (allTasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Tasks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TaskListWidget(tasks: allTasks),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    final timeString = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (dateOnly.isAtSameMomentAs(today)) {
      return 'Today at $timeString';
    } else if (dateOnly.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow at $timeString';
    } else {
      return '${date.day}/${date.month}/${date.year} at $timeString';
    }
  }

  void _useTemplate(template) {
    setState(() {
      _controller.text = template.title;
      _selectedSubject = template.subject;
      _selectedCategory = template.category;
      _selectedPriority = template.priority;
      _selectedDifficulty = template.difficultyLevel;
      _estimatedTime = template.estimatedTime;
      _notesController.text = template.notes ?? '';
      _tags.clear();
      _tags.addAll(template.tags);

      // Set due date based on template
      if (template.dueDaysFromNow != null) {
        _selectedDate = DateTime.now().add(Duration(days: template.dueDaysFromNow!))
            .copyWith(hour: 23, minute: 59);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied template: ${template.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  IconData _getIconForCategory(TaskCategory category) {
    switch (category) {
      case TaskCategory.homework:
        return Icons.assignment;
      case TaskCategory.project:
        return Icons.engineering;
      case TaskCategory.exam:
        return Icons.quiz;
      case TaskCategory.reading:
        return Icons.menu_book;
      case TaskCategory.lab:
        return Icons.science;
      case TaskCategory.quiz:
        return Icons.help_outline;
      case TaskCategory.review:
        return Icons.rate_review;
      case TaskCategory.other:
        return Icons.task_alt;
    }
  }
}

class _EstimatedTimeDialog extends StatefulWidget {
  final Duration? initialTime;

  const _EstimatedTimeDialog({this.initialTime});

  @override
  State<_EstimatedTimeDialog> createState() => _EstimatedTimeDialogState();
}

class _EstimatedTimeDialogState extends State<_EstimatedTimeDialog> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    _hours = widget.initialTime?.inHours ?? 1;
    _minutes = (widget.initialTime?.inMinutes ?? 30) % 60;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Estimated Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_hours}h ${_minutes}m'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Hours'),
                    Slider(
                      value: _hours.toDouble(),
                      min: 0,
                      max: 8,
                      divisions: 8,
                      onChanged: (value) {
                        setState(() {
                          _hours = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text('Minutes'),
                    Slider(
                      value: _minutes.toDouble(),
                      min: 0,
                      max: 59,
                      divisions: 11,
                      onChanged: (value) {
                        setState(() {
                          _minutes = (value / 5).round() * 5;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(Duration(hours: _hours, minutes: _minutes));
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}