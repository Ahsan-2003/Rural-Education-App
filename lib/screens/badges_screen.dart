import 'package:flutter/material.dart';
import 'package:rural_education_app/services/streak_service.dart';

class BadgesScreen extends StatelessWidget {
  final String studentId; // NEW
  const BadgesScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final allBadges = StreakService.getAllBadges();
    final earnedIds = StreakService.getEarnedBadgeIds(studentId);
    final stats = StreakService.getStats(studentId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements 🏆'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Stats header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.amber.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      '🔥',
                      '${stats['currentStreak']}',
                      'Day Streak',
                    ),
                    _buildStatItem('⭐', '${stats['totalXP']}', 'XP Points'),
                    _buildStatItem(
                      '🏆',
                      '${stats['earnedBadges']}/${stats['totalBadges']}',
                      'Badges',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats['earnedBadges'] / stats['totalBadges'],
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats['earnedBadges']} of ${stats['totalBadges']} badges earned',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),

          // Badge grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: allBadges.length,
              itemBuilder: (context, index) {
                final badge = allBadges[index];
                final isEarned = earnedIds.contains(badge.id);

                return Card(
                  elevation: isEarned ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isEarned
                        ? BorderSide(color: Colors.green, width: 2)
                        : BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isEarned
                          ? badge.badgeColor.withOpacity(0.2)
                          : Colors.grey.shade50,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Badge icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEarned
                                ? badge.badgeColor.withOpacity(0.2)
                                : Colors.grey.shade200,
                            border: Border.all(
                              color: isEarned
                                  ? badge.badgeColor.withOpacity(0.2)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isEarned ? badge.icon : '🔒',
                              style: TextStyle(
                                fontSize: 28,
                                color: isEarned ? null : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Badge name
                        Text(
                          badge.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isEarned ? Colors.black87 : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Badge description
                        Text(
                          badge.description,
                          style: TextStyle(
                            fontSize: 10,
                            color: isEarned
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Required count
                        if (!isEarned)
                          Text(
                            '${badge.requiredCount} needed',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }
}
