import 'package:flutter/material.dart';
import 'package:rural_education_app/screens/existing_screens.dart';
import 'package:rural_education_app/screens/profile_screen.dart';
import 'package:rural_education_app/services/connectivity_service.dart';
import 'package:rural_education_app/services/content_cache_service.dart';
import 'package:rural_education_app/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://hftjoljlsrneyrmiwgyc.supabase.co',
    publishableKey: 'sb_publishable_xWUQd4ybjupX5oOsc53rKA_azESq6et',
  );

  // Initialize local database
  await DatabaseService.init();

  // NEW: Initialize connectivity service
  await ConnectivityService().init();

  await ContentCacheService.init(); // NEW

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
