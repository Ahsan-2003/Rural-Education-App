import 'package:flutter/material.dart';
import 'package:rural_education_app/models/lesson.dart';
import 'package:rural_education_app/services/database_service.dart';

class QuizScreen extends StatefulWidget {
  final Lesson lesson;
  final Quiz quiz;
  final String studentId;
  final String studentName;

  const QuizScreen({
    super.key,
    required this.lesson,
    required this.quiz,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<String, String> _selectedAnswers = {};
  int? _score;
  int _totalQuestions = 0;
  bool _submitted = false;
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _totalQuestions = widget.quiz.questions.length;
    print('📝 Quiz started: ${widget.quiz.id} (${_totalQuestions} questions)');
  }

  // Submit quiz and calculate score
  void _submitQuiz() {
    int correct = 0;
    for (final question in widget.quiz.questions) {
      if (_selectedAnswers[question.id] == question.correctAnswer) {
        correct++;
      }
    }

    setState(() {
      _score = correct;
      _submitted = true;
    });

    // Save quiz score to database
    DatabaseService.saveProgress(
      studentId: widget.studentId,
      lessonId: widget.lesson.id,
      status: 'completed',
      quizScore: correct,
    );

    print('✅ Quiz submitted: Score $correct/$_totalQuestions');

    // Show result in snackbar
    final percentage = (correct / _totalQuestions) * 100;
    String message;
    Color color;

    if (percentage == 100) {
      message = '🏆 Perfect! $correct/$_totalQuestions - Excellent work!';
      color = Colors.green;
    } else if (percentage >= 60) {
      message = '👍 Good job! $correct/$_totalQuestions - Keep it up!';
      color = Colors.orange;
    } else {
      message = '📚 Score: $correct/$_totalQuestions - Review and try again!';
      color = Colors.red;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Get answer status for a question
  bool _isAnswerCorrect(Question question) {
    return _selectedAnswers[question.id] == question.correctAnswer;
  }

  // Get color for option button
  Color? _getOptionColor(Question question, String option) {
    if (!_submitted) return null;

    if (option == question.correctAnswer) {
      return Colors.green.shade100;
    }
    if (_selectedAnswers[question.id] == option &&
        option != question.correctAnswer) {
      return Colors.red.shade100;
    }
    return null;
  }

  // Build individual question widget
  Widget _buildQuestion(Question question, int index) {
    final isAnswered = _selectedAnswers.containsKey(question.id);
    final isCorrect = _submitted && _isAnswerCorrect(question);
    final isWrong = _submitted && !_isAnswerCorrect(question) && isAnswered;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _submitted
            ? BorderSide(color: isCorrect ? Colors.green : Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _submitted
                        ? (isCorrect ? Colors.green : Colors.red)
                        : Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _submitted
                        ? Icon(
                            isCorrect ? Icons.check : Icons.close,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Question text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${index + 1} of $_totalQuestions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Question type badge
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: question.type == 'mcq'
                    ? Colors.blue.shade50
                    : Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                question.type == 'mcq' ? 'Multiple Choice' : 'True / False',
                style: TextStyle(
                  fontSize: 10,
                  color: question.type == 'mcq'
                      ? Colors.blue.shade700
                      : Colors.purple.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Options
            ...question.options.map((option) {
              final isSelected = _selectedAnswers[question.id] == option;
              final optionColor = _getOptionColor(question, option);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color:
                      optionColor ??
                      (isSelected ? Colors.green.shade50 : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<String>(
                  title: Text(
                    option,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _submitted && option == question.correctAnswer
                          ? Colors.green.shade700
                          : null,
                    ),
                  ),
                  value: option,
                  groupValue: _selectedAnswers[question.id],
                  onChanged: _submitted
                      ? null
                      : (value) {
                          setState(() {
                            _selectedAnswers[question.id] = value!;
                          });
                        },
                  activeColor: Colors.green.shade700,
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }),

            // Show result after submission
            if (_submitted) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCorrect
                            ? 'Correct! Well done! 🎉'
                            : 'Correct answer: ${question.correctAnswer}',
                        style: TextStyle(
                          color: isCorrect
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Text(
                        '+1 point',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answeredCount = _selectedAnswers.length;
    final allAnswered = answeredCount == _totalQuestions;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: ${widget.lesson.title}'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ==========================================
          // PROGRESS HEADER
          // ==========================================
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              children: [
                // Progress text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: $answeredCount/$_totalQuestions',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      allAnswered ? '✅ Ready to submit!' : 'Keep going...',
                      style: TextStyle(
                        color: allAnswered ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: answeredCount / _totalQuestions,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      allAnswered ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(answeredCount / _totalQuestions * 100).toInt()}% completed',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // ==========================================
          // QUESTIONS LIST
          // ==========================================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.quiz.questions.length,
              itemBuilder: (context, index) {
                return _buildQuestion(widget.quiz.questions[index], index);
              },
            ),
          ),

          // ==========================================
          // BOTTOM ACTIONS
          // ==========================================
          if (!_submitted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: allAnswered ? _submitQuiz : null,
                        icon: const Icon(Icons.check),
                        label: Text(
                          allAnswered ? 'Submit Quiz' : 'Answer All Questions',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allAnswered
                              ? Colors.green.shade700
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ==========================================
          // RESULTS AFTER SUBMISSION
          // ==========================================
          if (_submitted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _score == _totalQuestions
                    ? Colors.green.shade50
                    : _score! >= _totalQuestions / 2
                    ? Colors.orange.shade50
                    : Colors.red.shade50,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Score display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _score == _totalQuestions
                              ? Icons.emoji_events
                              : Icons.grade,
                          color: _score == _totalQuestions
                              ? Colors.amber
                              : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Score: $_score / $_totalQuestions',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _score == _totalQuestions
                          ? 'Perfect! Outstanding work! 🏆'
                          : _score! >= _totalQuestions / 2
                          ? 'Good effort! Keep learning! 📚'
                          : 'Review the material and try again! 💪',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Reset quiz
                              setState(() {
                                _selectedAnswers.clear();
                                _score = null;
                                _submitted = false;
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // Back to lesson viewer
                              Navigator.pop(context); // Back to lesson list
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Done'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
