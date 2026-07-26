import 'package:flutter/material.dart';
import 'package:rural_education_app/screens/home_screens.dart';
import '../models/student_profile.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  final Function(StudentProfile) onProfileSelected;

  const ProfileScreen({super.key, required this.onProfileSelected});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _classController = TextEditingController();
  List<StudentProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _classController.dispose();
    super.dispose();
  }

  void _loadProfiles() {
    setState(() {
      _profiles = DatabaseService.getAllProfiles();
      _isLoading = false;
    });
    DatabaseService.getAllProfiles();
  }

  Future<void> _createProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }
    if (_pinController.text.length != 4) {
      _showError('PIN must be exactly 4 digits');
      return;
    }

    final profile = StudentProfile.create(
      name: _nameController.text.trim(),
      pin: _pinController.text.trim(),
      classCode: _classController.text.trim().isEmpty
          ? null
          : _classController.text.trim(),
    );

    await DatabaseService.saveProfile(profile);

    _nameController.clear();
    _pinController.clear();
    _classController.clear();

    _loadProfiles();

    // Create button ke andar, after saving profile:

    // After saving profile
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile created for ${profile.name}! 🎉'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      widget.onProfileSelected(profile);

      // ✅ Use pushReplacement to go to HomeScreens
      // AND remove ProfileScreen from stack
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreens(profile: profile)),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo & Title
            const SizedBox(height: 30),
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

            // ==========================================
            // EXISTING PROFILES SECTION
            // ==========================================
            if (_profiles.isNotEmpty) ...[
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

              ...List.generate(_profiles.length, (index) {
                final profile = _profiles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
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
                          Text('Class: ${profile.classCode}'),
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
                    onTap: () {
                      widget.onProfileSelected(profile);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreens(profile: profile),
                        ),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 20),
              const Divider(thickness: 1),
              const SizedBox(height: 16),
            ],

            // ==========================================
            // CREATE NEW PROFILE SECTION
            // ==========================================
            Row(
              children: [
                const Icon(Icons.person_add, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  _profiles.isEmpty
                      ? 'Create Your First Profile'
                      : 'Create New Profile',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name field
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your Full Name *',
                hintText: 'e.g., Ravi Kumar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),

            // PIN field
            TextField(
              controller: _pinController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Create 4-digit PIN *',
                hintText: '****',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                helperText: 'You will use this PIN to login',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            // Class code field
            TextField(
              controller: _classController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Class Code (Optional)',
                hintText: 'e.g., 5A',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.class_),
                helperText: 'Given by your teacher',
              ),
            ),
            const SizedBox(height: 20),

            // Create button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _createProfile,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Create Profile & Start Learning',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
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
