import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rural_education_app/models/lesson.dart';
import 'package:rural_education_app/services/database_service.dart'; // NEW

class LessonViewerScreen extends StatelessWidget {
  final Lesson lesson;
  final String studentName;
  final String studentId; // NEW

  const LessonViewerScreen({
    super.key,
    required this.lesson,
    required this.studentName,
    required this.studentId, // NEW
  });

  // NEW: Mark lesson as completed
  void _markAsCompleted(BuildContext context) {
    DatabaseService.saveProgress(
      studentId: studentId,
      lessonId: lesson.id,
      status: 'completed',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "${lesson.title}" completed!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    print('✅ Lesson completed and saved: ${lesson.title}');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => _markAsCompleted(context),
            tooltip: 'Mark as Complete',
          ),
        ],
      ),
      body: Column(
        children: [
          // Lesson content
          Expanded(
            child: Markdown(
              data: lesson.content,
              padding: const EdgeInsets.all(20),
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
                h2: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                h3: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade600,
                ),
                p: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.black87,
                ),
                code: TextStyle(
                  backgroundColor: Colors.green.shade50,
                  fontSize: 15,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                blockquoteDecoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border(
                    left: BorderSide(color: Colors.orange.shade300, width: 4),
                  ),
                ),
                tableBorder: TableBorder.all(color: Colors.green.shade200),
                tableHead: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),

          // Bottom action bar
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
                  // Back button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.green.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Complete button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markAsCompleted(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Mark Complete'),
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
            ),
          ),
        ],
      ),
    );
  }
}
