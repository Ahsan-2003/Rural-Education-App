import 'package:flutter/material.dart';
import 'package:rural_education_app/models/student_profile.dart';
import 'package:rural_education_app/screens/existing_screens.dart';
import 'package:rural_education_app/screens/home_screens.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rural Education App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AppShell(),
      // ✅ Add routes for better navigation
      routes: {
        '/profile': (context) => ProfileScreen(
          onProfileSelected: (profile) {
            print('Profile selected: ${profile.name}');
          },
        ),
        '/home': (context) => HomeScreens(
          profile: StudentProfile.create(name: 'Guest', pin: '0000'),
        ),
      },
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final hasProfiles = DatabaseService.hasProfile();

    if (hasProfiles) {
      return ExistingScreens(
        onProfileSelected: (profile) {
          print('Profile selected: ${profile.name}');
        },
      );
    } else {
      return ProfileScreen(
        onProfileSelected: (profile) {
          print('Profile created: ${profile.name}');
        },
      );
    }
  }
}
