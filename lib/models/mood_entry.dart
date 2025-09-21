class MoodEntry {
  final String id;
  final DateTime date;
  final int moodLevel; // 1-5 scale
  final String? notes;

  MoodEntry({
    required this.id,
    required this.date,
    required this.moodLevel,
    this.notes,
  });

  MoodEntry copyWith({
    String? id,
    DateTime? date,
    int? moodLevel,
    String? notes,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      moodLevel: moodLevel ?? this.moodLevel,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'moodLevel': moodLevel,
      'notes': notes,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      moodLevel: json['moodLevel'],
      notes: json['notes'],
    );
  }

  String get moodEmoji {
    switch (moodLevel) {
      case 1:
        return '😢';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  String get moodLabel {
    switch (moodLevel) {
      case 1:
        return 'Very Sad';
      case 2:
        return 'Sad';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very Happy';
      default:
        return 'Neutral';
    }
  }
}