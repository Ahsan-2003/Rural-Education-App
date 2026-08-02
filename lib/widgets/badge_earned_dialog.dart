import 'package:flutter/material.dart';
import 'package:rural_education_app/models/badge.dart';
// import 'package:rural_education_app/screens/badges_screen.dart';
// import 'package:rural_education_app/models/badge.dart' hide Badge;

class BadgeEarnedDialog extends StatelessWidget {
  final List<Badgee> badges;

  const BadgeEarnedDialog({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.orange.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🏆 Achievement Unlocked!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...badges.map(
              (badge) => Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: badge.badgeColor,
                      border: Border.all(color: badge.badgeColor, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        badge.icon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    badge.description,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+50 XP',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (badge != badges.last) const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Awesome! 🎉', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, List<Badgee> badges) {
    showDialog(
      context: context,
      builder: (_) => BadgeEarnedDialog(badges: badges),
    );
  }
}
