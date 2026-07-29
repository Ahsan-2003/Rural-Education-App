import 'package:flutter/material.dart';
import 'package:rural_education_app/models/student_profile.dart';
import 'package:rural_education_app/screens/existing_screens.dart';
import 'package:rural_education_app/screens/lesson_list_screen.dart';
import 'package:rural_education_app/services/content_service.dart';
import 'package:rural_education_app/services/database_service.dart';

class HomeScreens extends StatefulWidget {
  final StudentProfile profile;

  const HomeScreens({super.key, required this.profile});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  late final ContentService _contentService;
  int _completedLessons = 0;
  int _totalLessons = 0;

  @override
  void initState() {
    super.initState();
    _contentService = ContentService();
    _loadProgress();
    print('🏠 HomeScreens initialized for ${widget.profile.name}');
  }

  // NEW: Load progress from database
  void _loadProgress() {
    final lessons = _contentService.getLessons();
    _totalLessons = lessons.length;
    _completedLessons = DatabaseService.getCompletedLessonsCount(
      widget.profile.id,
    );

    print('📊 Progress: $_completedLessons/$_totalLessons lessons completed');
    DatabaseService.debugPrintProgress(widget.profile.id);
  }

  void _logout() {
    print('🚪 Logging out from HomeScreens');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ExistingScreens()),
    );
  }

  void _startLearning() {
    final lessons = _contentService.getLessons();
    print('📚 Starting learning with ${lessons.length} lessons');

    // Navigate to lesson list and refresh progress when coming back
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonListScreen(
          studentName: widget.profile.name,
          classCode: widget.profile.classCode,
          studentId: widget.profile.id, // NEW: Pass student ID
          onLogout: _logout,
          lessons: lessons,
        ),
      ),
    ).then((_) {
      // Refresh progress when returning from lessons
      _loadProgress();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final progressPercent = _totalLessons > 0
        ? (_completedLessons / _totalLessons)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${profile.name}! 👋'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Switch Profile',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green.shade100,
                child: Text(
                  profile.name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Welcome Text
              Text(
                'Welcome, ${profile.name}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Class Code
              if (profile.classCode != null) ...[
                Text(
                  'Class: ${profile.classCode}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 30),

              // Course Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          size: 50,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Mathematics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fractions - Grade 5',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // NEW: Progress Bar
                      Column(
                        children: [
                          // Progress text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_completedLessons of $_totalLessons lessons completed',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Progress bar
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: progressPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: progressPercent == 1.0
                                      ? Colors.green
                                      : Colors.green.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(progressPercent * 100).toInt()}% complete',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Start/Continue Learning Button
                  ElevatedButton.icon(
                    onPressed: _startLearning,
                    icon: Icon(
                      _completedLessons > 0
                          ? Icons.play_arrow
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      _completedLessons > 0
                          ? 'Continue Learning'
                          : 'Start Learning',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Switch Profile Button
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.switch_account),
                    label: const Text('Switch Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
