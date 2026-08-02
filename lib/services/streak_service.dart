import 'dart:ui';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/badge.dart';

class StreakService {
  static late Box _streakBox;
  static bool _initialized = false;

  // Initialize
  static Future<void> init() async {
    if (_initialized) return;
    _streakBox = await Hive.openBox('streaks');
    _initialized = true;
    print('✅ Streak service initialized');
  }

  // ==========================================
  // HELPER: Get key with student prefix
  // ==========================================
  static String _key(String studentId, String key) {
    return '${studentId}_$key';
  }

  // ==========================================
  // DAILY STREAK (Per Student)
  // ==========================================

  // Check and update daily streak for a specific student
  static Future<void> checkDailyStreak(String studentId) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    final lastLoginDate = _streakBox.get(
      _key(studentId, 'lastLoginDate'),
      defaultValue: '',
    );
    final currentStreak = _streakBox.get(
      _key(studentId, 'currentStreak'),
      defaultValue: 0,
    );

    if (lastLoginDate == todayStr) {
      // Already logged in today
      print('📅 $studentId: Already logged in today. Streak: $currentStreak');
      return;
    }

    if (lastLoginDate.isEmpty) {
      // First login ever
      await _streakBox.put(_key(studentId, 'lastLoginDate'), todayStr);
      await _streakBox.put(_key(studentId, 'currentStreak'), 1);
      await _streakBox.put(_key(studentId, 'bestStreak'), 1);
      print('🔥 $studentId: First day! Streak: 1');
      return;
    }

    // Check if yesterday
    final lastDate = DateTime.parse(lastLoginDate);
    final difference = today.difference(lastDate).inDays;

    if (difference == 1) {
      // Consecutive day!
      final newStreak = currentStreak + 1;
      await _streakBox.put(_key(studentId, 'currentStreak'), newStreak);
      await _streakBox.put(_key(studentId, 'lastLoginDate'), todayStr);

      // Update best streak
      final bestStreak = _streakBox.get(
        _key(studentId, 'bestStreak'),
        defaultValue: 0,
      );
      if (newStreak > bestStreak) {
        await _streakBox.put(_key(studentId, 'bestStreak'), newStreak);
      }

      print('🔥 $studentId: Streak day $newStreak!');
    } else if (difference > 1) {
      // Streak broken
      await _streakBox.put(_key(studentId, 'currentStreak'), 1);
      await _streakBox.put(_key(studentId, 'lastLoginDate'), todayStr);
      print('🔄 $studentId: Streak reset to 1 (missed ${difference - 1} days)');
    }
  }

  static int getCurrentStreak(String studentId) {
    return _streakBox.get(_key(studentId, 'currentStreak'), defaultValue: 0);
  }

  static int getBestStreak(String studentId) {
    return _streakBox.get(_key(studentId, 'bestStreak'), defaultValue: 0);
  }

  // ==========================================
  // XP POINTS (Per Student)
  // ==========================================

  static int getTotalXP(String studentId) {
    return _streakBox.get(_key(studentId, 'totalXP'), defaultValue: 0);
  }

  static Future<void> addXP(String studentId, int points) async {
    final current = getTotalXP(studentId);
    final newTotal = current + points;
    await _streakBox.put(_key(studentId, 'totalXP'), newTotal);
    print('⭐ $studentId: +$points XP (Total: $newTotal)');
  }

  // ==========================================
  // BADGES (Per Student)
  // ==========================================

  // Get all possible badges (same for all students)
  static List<Badgee> getAllBadges() {
    return [
      Badgee(
        id: 'first_lesson',
        name: 'First Steps',
        description: 'Complete your first lesson',
        icon: '👶',
        badgeColor: const Color(0xFF4CAF50),
        type: BadgeType.lessonsCompleted,
        requiredCount: 1,
      ),
      Badgee(
        id: 'bookworm',
        name: 'Bookworm',
        description: 'Complete 5 lessons',
        icon: '📚',
        badgeColor: Color(0xFF2196F3),
        type: BadgeType.lessonsCompleted,
        requiredCount: 5,
      ),
      Badgee(
        id: 'scholar',
        name: 'Scholar',
        description: 'Complete all 12 lessons',
        icon: '🎓',
        badgeColor: const Color(0xFF9C27B0),
        type: BadgeType.lessonsCompleted,
        requiredCount: 12,
      ),
      Badgee(
        id: 'perfect_score',
        name: 'Perfect Score',
        description: 'Get 100% on any quiz',
        icon: '💯',
        badgeColor: const Color(0xFFFFC107),
        type: BadgeType.quizPerfect,
        requiredCount: 1,
      ),
      Badgee(
        id: 'streak_3',
        name: 'Consistent Learner',
        description: '3-day learning streak',
        icon: '🔥',
        badgeColor: const Color(0xFFFF9800),
        type: BadgeType.streakDays,
        requiredCount: 3,
      ),
      Badgee(
        id: 'streak_7',
        name: 'Weekly Warrior',
        description: '7-day learning streak',
        icon: '🔥🔥',
        badgeColor: const Color(0xFFF44336),
        type: BadgeType.streakDays,
        requiredCount: 7,
      ),
      Badgee(
        id: 'all_rounder',
        name: 'All Rounder',
        description: 'Complete lessons in all 4 subjects',
        icon: '🌟',
        badgeColor: const Color(0xFF009688),
        type: BadgeType.allSubjects,
        requiredCount: 4,
      ),
      Badgee(
        id: 'quick_learner',
        name: 'Quick Learner',
        description: 'Complete 3 quizzes in one day',
        icon: '⚡',
        badgeColor: const Color(0xFF3F51B5),
        type: BadgeType.quickLearner,
        requiredCount: 3,
      ),
    ];
  }

  // Get earned badge IDs for a student
  static List<String> getEarnedBadgeIds(String studentId) {
    final badges = _streakBox.get(_key(studentId, 'earnedBadges'));
    if (badges == null) return [];
    return List<String>.from(badges);
  }

  // Get earned badge objects for a student
  static List<Badgee> getEarnedBadges(String studentId) {
    final earnedIds = getEarnedBadgeIds(studentId);
    return getAllBadges().where((b) => earnedIds.contains(b.id)).toList();
  }

  // Check if a badge is earned by a student
  static bool isBadgeEarned(String studentId, String badgeId) {
    return getEarnedBadgeIds(studentId).contains(badgeId);
  }

  // Award a badge to a student
  static Future<bool> awardBadge(String studentId, String badgeId) async {
    if (isBadgeEarned(studentId, badgeId)) return false;

    final earned = getEarnedBadgeIds(studentId);
    earned.add(badgeId);
    await _streakBox.put(_key(studentId, 'earnedBadges'), earned);

    // Add XP for badge
    await addXP(studentId, 50);

    final badge = getAllBadges().firstWhere((b) => b.id == badgeId);
    print('🏆 $studentId earned badge: ${badge.name}!');
    return true;
  }

  // Check and award badges based on progress
  static Future<List<Badgee>> checkAndAwardBadges({
    required String studentId,
    required int totalLessonsCompleted,
    required int totalQuizzesCompleted,
    required int perfectScores,
    required int currentStreak,
    required Set<String> completedSubjects,
  }) async {
    final newlyEarned = <Badgee>[];

    // Check lesson completion badges
    if (totalLessonsCompleted >= 1) {
      if (await awardBadge(studentId, 'first_lesson')) {
        newlyEarned.add(
          getAllBadges().firstWhere((b) => b.id == 'first_lesson'),
        );
      }
    }
    if (totalLessonsCompleted >= 5) {
      if (await awardBadge(studentId, 'bookworm')) {
        newlyEarned.add(getAllBadges().firstWhere((b) => b.id == 'bookworm'));
      }
    }
    if (totalLessonsCompleted >= 12) {
      if (await awardBadge(studentId, 'scholar')) {
        newlyEarned.add(getAllBadges().firstWhere((b) => b.id == 'scholar'));
      }
    }

    // Check quiz badges
    if (perfectScores >= 1) {
      if (await awardBadge(studentId, 'perfect_score')) {
        newlyEarned.add(
          getAllBadges().firstWhere((b) => b.id == 'perfect_score'),
        );
      }
    }

    // Check streak badges
    if (currentStreak >= 3) {
      if (await awardBadge(studentId, 'streak_3')) {
        newlyEarned.add(getAllBadges().firstWhere((b) => b.id == 'streak_3'));
      }
    }
    if (currentStreak >= 7) {
      if (await awardBadge(studentId, 'streak_7')) {
        newlyEarned.add(getAllBadges().firstWhere((b) => b.id == 'streak_7'));
      }
    }

    // Check all subjects badge
    if (completedSubjects.length >= 4) {
      if (await awardBadge(studentId, 'all_rounder')) {
        newlyEarned.add(
          getAllBadges().firstWhere((b) => b.id == 'all_rounder'),
        );
      }
    }

    // Check quick learner
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final quizzesKey = _key(studentId, 'quizzesToday_$todayStr');
    final quizzesToday = _streakBox.get(quizzesKey, defaultValue: 0);
    await _streakBox.put(quizzesKey, quizzesToday + 1);

    if (quizzesToday + 1 >= 3) {
      if (await awardBadge(studentId, 'quick_learner')) {
        newlyEarned.add(
          getAllBadges().firstWhere((b) => b.id == 'quick_learner'),
        );
      }
    }

    if (newlyEarned.isNotEmpty) {
      print('🏆 $studentId earned ${newlyEarned.length} new badges!');
    }

    return newlyEarned;
  }

  // Get overall stats for a student
  static Map<String, dynamic> getStats(String studentId) {
    return {
      'currentStreak': getCurrentStreak(studentId),
      'bestStreak': getBestStreak(studentId),
      'totalXP': getTotalXP(studentId),
      'earnedBadges': getEarnedBadgeIds(studentId).length,
      'totalBadges': getAllBadges().length,
    };
  }

  // Debug: Print all data for a student
  static void debugPrintStudentData(String studentId) {
    print('========== Streak Data for $studentId ==========');
    print('Current Streak: ${getCurrentStreak(studentId)}');
    print('Best Streak: ${getBestStreak(studentId)}');
    print('Total XP: ${getTotalXP(studentId)}');
    print('Earned Badges: ${getEarnedBadgeIds(studentId)}');
    print('==============================================');
  }
}
