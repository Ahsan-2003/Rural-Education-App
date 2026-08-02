import 'package:flutter/material.dart';
import 'package:rural_education_app/services/database_service.dart';
import 'package:rural_education_app/services/streak_service.dart';

class DashboardScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const DashboardScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _subjectProgress = {};
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> _quizHistory = [];
  double _averageScore = 0;
  int _totalLessonsCompleted = 0;
  int _totalQuizzes = 0;
  int _currentStreak = 0;
  int _totalXP = 0;
  int _badgesEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() {
    _subjectProgress = DatabaseService.getSubjectProgress(widget.studentId);
    _recentActivity = DatabaseService.getRecentActivity(widget.studentId);
    _quizHistory = DatabaseService.getQuizHistory(widget.studentId);
    _averageScore = DatabaseService.getAverageQuizScore(widget.studentId);
    _totalLessonsCompleted = DatabaseService.getCompletedLessonsCount(
      widget.studentId,
    );
    _totalQuizzes = DatabaseService.getTotalQuizzesTaken(widget.studentId);
    _currentStreak = StreakService.getCurrentStreak(widget.studentId);
    _totalXP = StreakService.getTotalXP(widget.studentId);
    _badgesEarned = StreakService.getEarnedBadgeIds(widget.studentId).length;

    print('📊 Dashboard loaded for ${widget.studentName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName}\'s Dashboard 📊'),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // OVERVIEW CARDS
            // ==========================================
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Lessons',
                    '$_totalLessonsCompleted/12',
                    Icons.menu_book,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Quizzes',
                    '$_totalQuizzes',
                    Icons.quiz,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Avg Score',
                    '${_averageScore.toStringAsFixed(0)}%',
                    Icons.grade,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Streak',
                    '$_currentStreak days',
                    Icons.local_fire_department,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'XP Points',
                    '$_totalXP',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Badges',
                    '$_badgesEarned/8',
                    Icons.emoji_events,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ==========================================
            // SUBJECT PROGRESS
            // ==========================================
            const Text(
              '📚 Subject Progress',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildSubjectProgressBar('📐 Mathematics', 'math', Colors.blue),
            _buildSubjectProgressBar('🔬 Science', 'science', Colors.green),
            _buildSubjectProgressBar('📖 English', 'english', Colors.purple),
            _buildSubjectProgressBar('🏛️ History', 'history', Colors.orange),

            const SizedBox(height: 24),

            // ==========================================
            // QUIZ SCORE HISTORY
            // ==========================================
            const Text(
              '📝 Quiz Score History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_quizHistory.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No quizzes taken yet. Complete some quizzes to see your history!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._quizHistory.take(5).map((quiz) {
                final lessonName = DatabaseService.getLessonName(
                  quiz['lessonId'] as String,
                );
                final subjectIcon = DatabaseService.getSubjectIcon(
                  quiz['lessonId'] as String,
                );
                final score = quiz['score'] as int;
                final percentage = (score / 5) * 100;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: percentage >= 80
                          ? Colors.green.shade100
                          : percentage >= 50
                          ? Colors.orange.shade100
                          : Colors.red.shade100,
                      child: Text(
                        subjectIcon,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    title: Text(
                      lessonName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(quiz['date'] as String),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: percentage >= 80
                            ? Colors.green.shade50
                            : percentage >= 50
                            ? Colors.orange.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$score/5 (${percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: percentage >= 80
                              ? Colors.green.shade700
                              : percentage >= 50
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),

            // ==========================================
            // RECENT ACTIVITY
            // ==========================================
            const Text(
              '🕐 Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_recentActivity.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No activity yet. Start learning!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ..._recentActivity.map((activity) {
                final lessonName = DatabaseService.getLessonName(
                  activity['lessonId'] as String,
                );
                final subjectIcon = DatabaseService.getSubjectIcon(
                  activity['lessonId'] as String,
                );
                final type = activity['type'] as String;
                final score = activity['score'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type == 'quiz'
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    child: Text(
                      type == 'quiz' ? '📝' : '📖',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  title: Text(
                    type == 'quiz'
                        ? 'Completed quiz: $lessonName'
                        : 'Completed lesson: $lessonName',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Text(subjectIcon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(activity['date'] as String),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: score != null
                      ? Text(
                          'Score: $score',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 12,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                );
              }),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectProgressBar(String label, String subjectId, Color color) {
    final completed = _subjectProgress[subjectId] ?? 0;
    final total = 3; // 3 lessons per subject
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '$completed/$total',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
