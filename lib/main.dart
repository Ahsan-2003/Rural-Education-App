import 'package:flutter/material.dart';
import 'package:rural_education_app/models/student_profile.dart';
import 'package:rural_education_app/screens/existing_screens.dart';
import 'package:rural_education_app/screens/profile_screen.dart';
import 'package:rural_education_app/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hftjoljlsrneyrmiwgyc.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmdGpvbGpsc3JuZXlybWl3Z3ljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5Njk2ODcsImV4cCI6MjEwMDU0NTY4N30.0iIVhiLezLs_ZW8qwbgbFe3fP2NRmxCNJ9uBvVVodw4',
  );
  await DatabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: const AppShell(),
      home: AppShell(),
    );
  }
}

// Shell that manages profile selection
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  StudentProfile? _currentProfile;

  void _onProfileSelected(StudentProfile profile) {
    setState(() {
      _currentProfile = profile;
    });
  }

  void _logout() {
    setState(() {
      _currentProfile = null;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExistingScreens()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If no profile selected, show profile screen
    if (_currentProfile == null) {
      return Scaffold(
        // body: ExistingScreens(onProfileSelected: _onProfileSelected),
        body: ProfileScreen(onProfileSelected: _onProfileSelected),
      );
    }

    // Profile selected - show placeholder (lessons will go here)
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${_currentProfile!.name}! 👋'),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green.shade400),
            const SizedBox(height: 20),
            Text(
              'Logged in as ${_currentProfile!.name}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_currentProfile!.classCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Class: ${_currentProfile!.classCode}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 30),
            const Text(
              'Profile Management Working! ✅\nLessons coming next...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
