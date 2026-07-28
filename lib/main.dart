import 'package:flutter/material.dart';
import 'package:rural_education_app/screens/existing_screens.dart';
import 'package:rural_education_app/screens/profile_screen.dart';
import 'package:rural_education_app/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hftjoljlsrneyrmiwgyc.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmdGpvbGpsc3JuZXlybWl3Z3ljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ5Njk2ODcsImV4cCI6MjEwMDU0NTY4N30.0iIVhiLezLs_ZW8qwbgbFe3fP2NRmxCNJ9uBvVVodw4',
  );

  // Initialize local database
  await DatabaseService.init();

  runApp(const RuralEduApp());
}

class RuralEduApp extends StatelessWidget {
  const RuralEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rural Education',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const AppShell(),
    );
  }
}

// =============================================
// APP SHELL - Entry point that checks profiles
// =============================================
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final hasProfiles = DatabaseService.hasProfile();

    print('🚀 AppShell: hasProfiles = $hasProfiles');

    // If profiles exist, show ExistingScreens (profile list)
    // If no profiles, show ProfileScreen (create first profile)
    if (hasProfiles) {
      return const ExistingScreens();
    } else {
      return ProfileScreen(
        onProfileSelected: (profile) {
          print('👤 First profile created: ${profile.name}');
        },
      );
    }
  }
}
