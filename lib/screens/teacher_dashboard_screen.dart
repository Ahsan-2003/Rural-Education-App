import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      // Load students
      final studentsResponse = await _supabase
          .from('students')
          .select('*')
          .order('created_at', ascending: false);

      // Load events
      final eventsResponse = await _supabase
          .from('progress_events')
          .select('*')
          .order('client_created_at', ascending: false);

      setState(() {
        _students = List<Map<String, dynamic>>.from(studentsResponse);
        _events = List<Map<String, dynamic>>.from(eventsResponse);
        _loading = false;
      });

      print(
        '📊 Dashboard loaded: ${_students.length} students, ${_events.length} events',
      );
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ==========================================
  // FIXED: Count UNIQUE lessons per student
  // ==========================================
  int _getUniqueLessonsCompleted(String studentId) {
    final uniqueLessons = <String>{};

    for (final event in _events) {
      if (event['student_id'] == studentId &&
          event['event_type'] == 'lesson_completed') {
        uniqueLessons.add(event['lesson_id'] as String);
      }
    }

    return uniqueLessons.length;
  }

  // Count unique lessons per subject
  int _getSubjectLessonsCompleted(String studentId, String prefix) {
    final uniqueLessons = <String>{};

    for (final event in _events) {
      final lessonId = event['lesson_id'] as String?;
      if (event['student_id'] == studentId &&
          event['event_type'] == 'lesson_completed' &&
          lessonId != null &&
          lessonId.startsWith(prefix)) {
        uniqueLessons.add(lessonId);
      }
    }

    return uniqueLessons.length;
  }

  // Get unique quiz attempts (latest per lesson)
  List<Map<String, dynamic>> _getQuizAttempts(String studentId) {
    final quizAttempts = <String, Map<String, dynamic>>{};

    for (final event in _events) {
      if (event['student_id'] == studentId &&
          event['event_type'] == 'quiz_submitted') {
        final lessonId = event['lesson_id'] as String?;
        if (lessonId != null) {
          // Keep the latest attempt per lesson
          if (!quizAttempts.containsKey(lessonId) ||
              (event['client_created_at'] as String?)?.compareTo(
                    quizAttempts[lessonId]!['client_created_at'] as String,
                  ) ==
                  1) {
            quizAttempts[lessonId] = event;
          }
        }
      }
    }

    return quizAttempts.values.toList()..sort(
      (a, b) => (b['client_created_at'] as String).compareTo(
        a['client_created_at'] as String,
      ),
    );
  }

  int _getTotalQuizzesTaken(String studentId) {
    return _getQuizAttempts(studentId).length;
  }

  String _getLessonName(String lessonId) {
    const names = {
      'math_1': 'Intro to Fractions',
      'math_2': 'Adding Fractions',
      'math_3': 'Fractions in Daily Life',
      'sci_1': 'Parts of a Plant',
      'sci_2': 'Animals Classification',
      'sci_3': 'Human Body Systems',
      'eng_1': 'Nouns - Naming Words',
      'eng_2': 'Verbs - Action Words',
      'eng_3': 'Simple Sentences',
      'his_1': 'Indus Valley Civilization',
      'his_2': 'Freedom Struggle',
      'his_3': 'Indian Heritage & Culture',
    };
    return names[lessonId] ?? lessonId;
  }

  String _getSubjectFromLesson(String lessonId) {
    if (lessonId.startsWith('math_')) return '📐 Mathematics';
    if (lessonId.startsWith('sci_')) return '🔬 Science';
    if (lessonId.startsWith('eng_')) return '📖 English';
    if (lessonId.startsWith('his_')) return '🏛️ History';
    return '📚 Other';
  }

  @override
  Widget build(BuildContext context) {
    // Count unique stats
    int totalLessons = 0;
    int totalQuizzes = 0;

    for (final student in _students) {
      totalLessons += _getUniqueLessonsCompleted(student['id'] as String);
      totalQuizzes += _getTotalQuizzesTaken(student['id'] as String);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍🏫 Teacher Dashboard'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.indigo),
                  SizedBox(height: 16),
                  Text('Loading from Supabase...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      _buildStatCard(
                        '👨‍🎓',
                        '${_students.length}',
                        'Students',
                        Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        '📚',
                        '$totalLessons',
                        'Lessons',
                        Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _buildStatCard(
                        '📝',
                        '$totalQuizzes',
                        'Quizzes',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Students List
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        'Students (${_students.length})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_students.isEmpty)
                    Card(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Students Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Students appear after syncing from the app.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._students.map((student) => _buildStudentCard(student)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final studentId = student['id'] as String;
    final lessonsCompleted = _getUniqueLessonsCompleted(studentId);
    final quizzesTaken = _getTotalQuizzesTaken(studentId);
    final lastSync = student['last_synced_at'] != null
        ? DateTime.parse(student['last_synced_at'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.shade100,
          child: Text(
            (student['name'] as String? ?? '?')[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade700,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          student['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Class: ${student['class_code'] ?? 'N/A'} | 📚 $lessonsCompleted/12 lessons | 📝 $quizzesTaken quizzes',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: lastSync != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${lastSync.day}/${lastSync.month}',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                ),
              )
            : const Icon(Icons.cloud_off, color: Colors.red, size: 20),
        children: [_buildStudentDetail(student)],
      ),
    );
  }

  Widget _buildStudentDetail(Map<String, dynamic> student) {
    final studentId = student['id'] as String;
    final quizAttempts = _getQuizAttempts(studentId);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Progress (FIXED: shows max 3 per subject)
          const Text(
            '📚 Subject Progress:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildSubjectProgress('📐 Mathematics', 'math_', studentId),
          _buildSubjectProgress('🔬 Science', 'sci_', studentId),
          _buildSubjectProgress('📖 English', 'eng_', studentId),
          _buildSubjectProgress('🏛️ History', 'his_', studentId),

          const Divider(height: 24),

          // Quiz Scores (FIXED: shows unique quiz attempts)
          if (quizAttempts.isNotEmpty) ...[
            const Text(
              '📝 Quiz Scores:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...quizAttempts.take(10).map((quiz) {
              final score = quiz['payload']?['quizScore'] ?? 0;
              final lessonId = quiz['lesson_id'] ?? '';
              final lessonName = _getLessonName(lessonId);
              final subject = _getSubjectFromLesson(lessonId);
              final date = quiz['client_created_at'] != null
                  ? DateTime.parse(
                      quiz['client_created_at'],
                    ).toString().substring(0, 16)
                  : '';
              final percentage = (score / 5) * 100;

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lessonName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              subject,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: percentage >= 80
                              ? Colors.green.shade100
                              : percentage >= 50
                              ? Colors.orange.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$score/5 (${percentage.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: percentage >= 80
                                ? Colors.green.shade700
                                : percentage >= 50
                                ? Colors.orange.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date.substring(0, 10),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          if (_getUniqueLessonsCompleted(studentId) == 0 &&
              quizAttempts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                '📭 No activity yet.\nComplete lessons in the app and sync!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress(String label, String prefix, String studentId) {
    final completed = _getSubjectLessonsCompleted(studentId, prefix);
    // Cap at 3 (total lessons per subject)
    final displayCompleted = completed > 3 ? 3 : completed;
    final total = 3;
    final progress = displayCompleted / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              Text(
                '$displayCompleted/$total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: displayCompleted == 3 ? Colors.green : Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                displayCompleted == 3 ? Colors.green : Colors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
