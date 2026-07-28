import 'package:flutter/material.dart';
import 'package:rural_education_app/models/student_profile.dart';
import 'package:rural_education_app/screens/home_screens.dart';
import 'package:rural_education_app/screens/profile_screen.dart';
import 'package:rural_education_app/services/database_service.dart';

class ExistingScreens extends StatefulWidget {
  final Function(StudentProfile)? onProfileSelected;

  const ExistingScreens({super.key, this.onProfileSelected});

  @override
  State<ExistingScreens> createState() => _ExistingScreensState();
}

class _ExistingScreensState extends State<ExistingScreens> {
  List<StudentProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    setState(() {
      _profiles = DatabaseService.getAllProfiles();
      _isLoading = false;
    });
  }

  void _loginWithProfile(BuildContext context, StudentProfile profile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final pinController = TextEditingController();

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock, color: Colors.green),
              const SizedBox(width: 8),
              Column(
                children: [
                  Text('Welcome back'),
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your 4-digit PIN to login:'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                maxLength: 4,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '****',
                  border: const OutlineInputBorder(),
                  counterText: '',
                  prefixIcon: const Icon(Icons.pin),
                ),
                onChanged: (value) {
                  if (value.length == 4) {
                    if (value == profile.pin) {
                      Navigator.pop(ctx);

                      if (widget.onProfileSelected != null) {
                        widget.onProfileSelected!(profile);
                      }

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreens(profile: profile),
                        ),
                      );
                    } else {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('❌ Wrong PIN! Try again.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profiles.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Profiles Found',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please create a profile to get started',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // ✅ Use push to keep ExistingScreens in stack
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        onProfileSelected: (profile) {
                          print('Profile created: ${profile.name}');
                          // After creating profile, refresh the list
                          _loadProfiles();
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo & Title
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  size: 60,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Rural Education',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const Center(
              child: Text(
                'Learn anytime, anywhere - even offline!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),

            // ✅ Fixed: Existing Profiles Header
            Row(
              children: [
                const Icon(Icons.people, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Existing Profiles (${_profiles.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ✅ Fixed: Profile Cards with better spacing
            ...List.generate(_profiles.length, (index) {
              final profile = _profiles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8), // ✅ Less gap
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      profile.name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    profile.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.classCode != null)
                        Text(
                          'Class: ${profile.classCode}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      Text(
                        'Created: ${_formatDate(profile.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _loginWithProfile(context, profile),
                ),
              );
            }),

            const SizedBox(height: 20),

            // ✅ Fixed: Divider with better visibility
            const Divider(thickness: 1, color: Colors.grey),

            const SizedBox(height: 16),

            // ✅ Fixed: Create New Profile Button - More Visible
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        onProfileSelected: (profile) {
                          print('Profile created: ${profile.name}');
                          _loadProfiles();
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'Create New Profile',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
