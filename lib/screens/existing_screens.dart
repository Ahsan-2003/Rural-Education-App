import 'package:flutter/material.dart';
import 'package:rural_education_app/models/student_profile.dart';

class ExistingScreens extends StatelessWidget {
  // void Function(StudentProfile)? onProfileSelected;
  // ExistingScreens({super.key, required this.onProfileSelected});

  final List<StudentProfile> _profiles = [];

  ExistingScreens({super.key});

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
              Text('Welcome back, ${profile.name}!'),
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
                      // widget.onProfileSelected(profile);
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
    return SingleChildScrollView(
      child: Column(
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
              child: Icon(Icons.school, size: 60, color: Colors.green.shade700),
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

            ...List.generate(_profiles.length, ((index) {
              final profile = _profiles[index];
              return Card(
                margin: const EdgeInsets.all(12.0), // ✅ FIX 2: Added 'const'
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      profile.name[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    profile.name,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
                  // ✅ FIX 3: Pass context to the method
                  onTap: () => _loginWithProfile(context, profile),
                ),
              );
            })),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
