import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Store this securely in production
  static const String _apiKey = 'YOUR_OPENAI_API_KEY_HERE';

  Future<Map<String, dynamic>> parseTaskFromText(String taskText) async {
    if (_apiKey == 'YOUR_OPENAI_API_KEY_HERE') {
      // Fallback parsing for demo purposes
      return _fallbackParsing(taskText);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a task parsing assistant. Extract task information from natural language input and return a JSON object with the following fields:
- task: The main task description (string)
- subject: The subject/category if mentioned (string or null)
- due_date: The due date if mentioned (ISO 8601 string or null)

If no due date is specified, return null for due_date.
Only return the JSON object, no additional text.'''
            },
            {
              'role': 'user',
              'content': 'Parse this task: "$taskText"'
            }
          ],
          'max_tokens': 150,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return jsonDecode(content);
      } else {
        throw Exception('Failed to parse task: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to simple parsing
      return _fallbackParsing(taskText);
    }
  }

  Map<String, dynamic> _fallbackParsing(String taskText) {
    String task = taskText;
    String? subject;
    DateTime? dueDate;

    // Simple subject detection
    final subjects = ['math', 'physics', 'chemistry', 'biology', 'english', 'history'];
    for (final sub in subjects) {
      if (taskText.toLowerCase().contains(sub)) {
        subject = sub.toUpperCase();
        break;
      }
    }

    // Simple due date detection
    final now = DateTime.now();
    if (taskText.toLowerCase().contains('today')) {
      dueDate = now;
    } else if (taskText.toLowerCase().contains('tomorrow')) {
      dueDate = now.add(const Duration(days: 1));
    } else if (taskText.toLowerCase().contains('next week')) {
      dueDate = now.add(const Duration(days: 7));
    } else if (taskText.toLowerCase().contains('friday')) {
      final daysUntilFriday = (5 - now.weekday) % 7;
      dueDate = now.add(Duration(days: daysUntilFriday == 0 ? 7 : daysUntilFriday));
    }

    return {
      'task': task,
      'subject': subject,
      'due_date': dueDate?.toIso8601String(),
    };
  }

  Future<String> getStudyRecommendation(String mood, String subject) async {
    if (_apiKey == 'YOUR_OPENAI_API_KEY_HERE') {
      return _fallbackRecommendation(mood, subject);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a study productivity assistant. Provide brief, helpful study recommendations based on the user\'s mood and subject. Keep responses under 50 words.'
            },
            {
              'role': 'user',
              'content': 'I feel $mood and need to study $subject. What do you recommend?'
            }
          ],
          'max_tokens': 80,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return _fallbackRecommendation(mood, subject);
      }
    } catch (e) {
      return _fallbackRecommendation(mood, subject);
    }
  }

  String _fallbackRecommendation(String mood, String subject) {
    if (mood.toLowerCase().contains('tired')) {
      return 'Start with light review or flashcards. Take frequent breaks and consider shorter study sessions.';
    } else if (mood.toLowerCase().contains('stressed')) {
      return 'Begin with easier topics to build confidence. Use the Pomodoro technique with relaxing breaks.';
    } else if (mood.toLowerCase().contains('motivated')) {
      return 'Perfect time to tackle challenging problems! Use longer focus sessions and dive deep into $subject.';
    } else {
      return 'Start with a 25-minute Pomodoro session reviewing key concepts in $subject. Stay consistent!';
    }
  }
}