import 'package:flutter/material.dart';
import 'package:rural_education_app/models/student_profile.dart';
import 'package:rural_education_app/screens/existing_screens.dart';

class HomeScreens extends StatefulWidget {
  final StudentProfile profile;

  const HomeScreens({super.key, required this.profile});

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  void _logout() {
    // ✅ Use pushReplacement to go back to ExistingScreens
    // This removes HomeScreens from stack
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ExistingScreens()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

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

              // Class Code (if available)
              if (profile.classCode != null) ...[
                Text(
                  'Class: ${profile.classCode}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
              const SizedBox(height: 8),

              // Member Since
              Text(
                'Member since: ${_formatDate(profile.createdAt)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Status Card
              Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.green.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle, size: 60, color: Colors.green),
                      SizedBox(height: 12),
                      Text(
                        'Profile Management Working! ✅',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lessons coming next...',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to lessons
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📚 Lessons feature coming soon!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: const Icon(Icons.book),
                    label: const Text('Start Learning'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.switch_account),
                    label: const Text('Switch Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
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
