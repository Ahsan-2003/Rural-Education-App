import 'package:flutter/material.dart';
import 'package:rural_education_app/models/student_profile.dart';
import 'package:rural_education_app/screens/existing_screens.dart';
import 'package:rural_education_app/screens/lesson_list_screen.dart';
import 'package:rural_education_app/services/content_service.dart';
import 'package:rural_education_app/services/database_service.dart';
import 'package:rural_education_app/services/sync_service.dart'; // NEW

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
  bool _isOnline = false; // NEW
  bool _isSyncing = false; // NEW
  int _unsyncedCount = 0; // NEW

  @override
  void initState() {
    super.initState();
    _contentService = ContentService();
    _loadProgress();
    _checkConnectivity(); // NEW
    print('🏠 HomeScreens initialized for ${widget.profile.name}');
  }

  // NEW: Check if online
  Future<void> _checkConnectivity() async {
    final online = await SyncService.isOnline();
    setState(() {
      _isOnline = online;
    });

    // Auto-sync if online
    if (online) {
      _syncData();
    }
  }

  void _loadProgress() {
    final lessons = _contentService.getLessons();
    _totalLessons = lessons.length;
    _completedLessons = DatabaseService.getCompletedLessonsCount(
      widget.profile.id,
    );
    _unsyncedCount = DatabaseService.getUnsyncedCount(); // NEW
  }

  // NEW: Manual sync
  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    final result = await SyncService.syncAll(widget.profile.id);

    setState(() {
      _isSyncing = false;
      _unsyncedCount = DatabaseService.getUnsyncedCount();
    });

    if (mounted) {
      if (result['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${result['error']}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (result['events_synced'] > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Synced ${result['events_synced']} events!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ExistingScreens()),
    );
  }

  void _startLearning() {
    final lessons = _contentService.getLessons();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonListScreen(
          studentName: widget.profile.name,
          classCode: widget.profile.classCode,
          studentId: widget.profile.id,
          onLogout: _logout,
          lessons: lessons,
        ),
      ),
    ).then((_) {
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
          // NEW: Sync button
          Stack(
            children: [
              IconButton(
                icon: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _isOnline ? Icons.cloud_done : Icons.cloud_off,
                        color: Colors.white,
                      ),
                onPressed: _isSyncing ? null : _syncData,
                tooltip: _isOnline ? 'Sync Now' : 'Offline',
              ),
              // NEW: Unsynced badge
              if (_unsyncedCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unsyncedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

                      // Progress Bar
                      Column(
                        children: [
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
                  ElevatedButton.icon(
                    onPressed: _startLearning,
                    icon: const Icon(Icons.play_arrow),
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

              // NEW: Sync status text
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isOnline ? _syncData : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isOnline ? Icons.cloud_done : Icons.cloud_off,
                      size: 16,
                      color: _isOnline ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline
                          ? (_unsyncedCount > 0
                                ? '$_unsyncedCount pending - Tap to sync'
                                : 'All data synced ✅')
                          : 'Offline mode 📴',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOnline ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
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
