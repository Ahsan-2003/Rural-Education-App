import 'package:flutter/material.dart';
import 'package:rural_education_app/models/lesson.dart';
import 'package:rural_education_app/screens/lesson_viewer_screen.dart';
import 'package:rural_education_app/services/database_service.dart'; // NEW

class LessonListScreen extends StatefulWidget {
  final String studentName;
  final String? classCode;
  final String studentId; // NEW: Added studentId
  final VoidCallback onLogout;
  final List<Lesson> lessons;
  // Add these parameters to the class:
  final String subjectName; // NEW
  final String subjectIcon; // NEW

  // Update constructor:
  const LessonListScreen({
    super.key,
    required this.studentName,
    required this.classCode,
    required this.studentId,
    required this.onLogout,
    required this.lessons,
    this.subjectName = 'Mathematics', // Default
    this.subjectIcon = '📐', // Default
  });

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  Map<String, bool> _completedLessons = {};
  Map<String, int?> _quizScores = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  // NEW: Load progress from database
  void _loadProgress() {
    final progressMap = <String, bool>{};
    final scoreMap = <String, int?>{};

    for (final lesson in widget.lessons) {
      final progress = DatabaseService.getProgress(widget.studentId, lesson.id);
      progressMap[lesson.id] =
          progress != null && progress['status'] == 'completed';
      scoreMap[lesson.id] = progress?['quizScore'];
    }

    setState(() {
      _completedLessons = progressMap;
      _quizScores = scoreMap;
    });

    print('📊 LessonList: Loaded progress for ${widget.studentName}');
    DatabaseService.debugPrintProgress(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedLessons.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.studentName.toUpperCase()}! 👋'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          // NEW: Progress counter in app bar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completedCount/${widget.lessons.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Switch Profile',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // HEADER SECTION
          // ==========================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '📐 ${widget.studentName}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  '${widget.subjectName} - Grade 5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Student info
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      widget.studentName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.classCode != null) ...[
                      const SizedBox(width: 16),
                      const Icon(Icons.school, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Class ${widget.classCode}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Stats row
                Row(
                  children: [
                    _buildStatBox('${widget.lessons.length}', 'Lessons'),
                    const SizedBox(width: 12),
                    _buildStatBox('$completedCount', 'Completed'),
                    const SizedBox(width: 12),
                    _buildStatBox('15', 'Questions'),
                  ],
                ),
              ],
            ),
          ),

          // ==========================================
          // LESSON LIST
          // ==========================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Lessons (${widget.lessons.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap to start →',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.lessons.length,
              itemBuilder: (context, index) {
                final lesson = widget.lessons[index];
                final hasQuiz = lesson.quiz != null;
                final questionCount = lesson.quiz?.questions.length ?? 0;
                final isCompleted = _completedLessons[lesson.id] ?? false;
                final quizScore = _quizScores[lesson.id];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isCompleted
                        ? BorderSide(color: Colors.green.shade300, width: 2)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      print('📖 Opening lesson: ${lesson.title}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonViewerScreen(
                            lesson: lesson,
                            studentName: widget.studentName,
                            studentId: widget.studentId, // NEW: Pass studentId
                          ),
                        ),
                      ).then((_) {
                        // Refresh progress when returning
                        _loadProgress();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Lesson number circle (shows checkmark if completed)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.green
                                  : Colors.green.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCompleted
                                    ? Colors.green.shade700
                                    : Colors.green.shade200,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 28,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Lesson info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted
                                        ? Colors.green.shade700
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isCompleted
                                          ? Icons.check_circle
                                          : Icons.article,
                                      size: 14,
                                      color: isCompleted
                                          ? Colors.green
                                          : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isCompleted
                                          ? 'Completed'
                                          : 'Lesson ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isCompleted
                                            ? Colors.green
                                            : Colors.grey.shade600,
                                        fontWeight: isCompleted
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (quizScore != null) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.grade,
                                        size: 14,
                                        color: Colors.amber.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Score: $quizScore',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    if (hasQuiz && !isCompleted) ...[
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.quiz,
                                        size: 14,
                                        color: Colors.orange.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$questionCount Q',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Arrow or completion badge
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                size: 20,
                                color: Colors.amber,
                              ),
                            )
                          else
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.grey.shade400,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build stat box
  Widget _buildStatBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
