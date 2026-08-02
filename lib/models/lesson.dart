// =============================================
// LESSON MODEL
// =============================================
class Lesson {
  final String id;
  final String title;
  final String content;
  final int order;
  final Quiz? quiz;

  Lesson({
    required this.id,
    required this.title,
    required this.content,
    required this.order,
    this.quiz,
  });

  // FIXED: Better fromJson with null safety
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      content: json['content'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      quiz: json['quiz'] != null
          ? Quiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'order': order,
      'quiz': quiz?.toJson(),
    };
  }

  @override
  String toString() => 'Lesson(id: $id, title: $title, order: $order)';
}

// =============================================
// QUIZ MODEL
// =============================================
class Quiz {
  final String id;
  final List<Question> questions;

  Quiz({required this.id, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String? ?? '',
      questions: json['questions'] != null
          ? (json['questions'] as List)
                .map((q) => Question.fromJson(q as Map<String, dynamic>))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'questions': questions.map((q) => q.toJson()).toList()};
  }
}

// =============================================
// QUESTION MODEL
// =============================================
class Question {
  final String id;
  final String type;
  final String text;
  final List<String> options;
  final String correctAnswer;
  final int points;

  Question({
    required this.id,
    required this.type,
    required this.text,
    required this.options,
    required this.correctAnswer,
    this.points = 1,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'mcq',
      text: json['text'] as String? ?? '',
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : [],
      correctAnswer: json['correctAnswer'] as String? ?? '',
      points: json['points'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'text': text,
      'options': options,
      'correctAnswer': correctAnswer,
      'points': points,
    };
  }
}
