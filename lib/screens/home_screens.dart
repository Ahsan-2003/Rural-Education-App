import 'package:flutter/material.dart';
import 'package:rural_education_app/models/student_profile.dart';
import 'package:rural_education_app/screens/existing_screens.dart';
import 'package:rural_education_app/screens/subject_screen.dart';
import 'package:rural_education_app/services/database_service.dart';
import 'package:rural_education_app/services/sync_service.dart';
import 'package:rural_education_app/services/connectivity_service.dart';
import 'package:rural_education_app/widgets/connectivity_banner.dart';

class HomeScreens extends StatefulWidget {
  final StudentProfile profile;

  const HomeScreens({super.key, required this.profile});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  int _completedLessons = 0;
  int _totalLessons = 0;
  bool _isOnline = true;
  bool _isSyncing = false;
  int _unsyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();

    // Get initial connectivity status
    _isOnline = ConnectivityService().isOnline;
    print(
      '📶 HomeScreens: Initial connectivity = ${_isOnline ? "Online" : "Offline"}',
    );

    // Listen for connectivity changes
    ConnectivityService().onConnectivityChanged = (online) {
      print(
        '📶 HomeScreens: Connectivity changed to ${online ? "Online" : "Offline"}',
      );
      setState(() {
        _isOnline = online;
      });
      if (online) {
        _syncData();
      }
    };

    // Auto-sync if online on startup
    if (_isOnline) {
      _syncData();
    }
  }

  // FIXED: Load progress without ContentService
  void _loadProgress() {
    // Total lessons across all subjects (3 lessons × 4 subjects = 12)
    _totalLessons = 12;

    // Get completed lessons from database
    _completedLessons = DatabaseService.getCompletedLessonsCount(
      widget.profile.id,
    );
    _unsyncedCount = DatabaseService.getUnsyncedCount();

    print(
      '📊 Progress: $_completedLessons/$_totalLessons | Unsynced: $_unsyncedCount',
    );
  }

  Future<void> _syncData() async {
    if (_isSyncing) {
      print('🔄 Already syncing, skipping...');
      return;
    }

    print('🔄 Starting sync...');
    setState(() => _isSyncing = true);

    final result = await SyncService.syncAll(widget.profile.id);

    setState(() {
      _isSyncing = false;
      _unsyncedCount = DatabaseService.getUnsyncedCount();
    });

    print('📊 Sync result: $result');

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Already up to date'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectScreen(
          studentName: widget.profile.name,
          classCode: widget.profile.classCode,
          studentId: widget.profile.id,
          onLogout: _logout,
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
          // Sync button
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
                        color: _isOnline ? Colors.white : Colors.white70,
                      ),
                onPressed: _isSyncing ? null : _syncData,
                tooltip: _isOnline
                    ? (_unsyncedCount > 0
                          ? '$_unsyncedCount items to sync'
                          : 'All synced')
                    : 'You are offline',
              ),
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
      body: Column(
        children: [
          // Connectivity Banner
          ConnectivityBanner(
            isOnline: _isOnline,
            unsyncedCount: _unsyncedCount,
            onSyncTap: _syncData,
          ),

          // Main content
          Expanded(
            child: Center(
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
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Course Overview Card
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
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100,
                            ],
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
                                Icons.school,
                                size: 50,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '4 Subjects Available',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Math • Science • English • History',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Progress Overview
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
