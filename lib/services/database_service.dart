import 'package:hive_flutter/hive_flutter.dart';
import 'package:rural_education_app/models/student_profile.dart';

class DatabaseService {
  static late Box _profileBox;
  static late Box _progressBox;
  static bool _initialize = false;

  static Future<void> init() async {
    if (_initialize) return;

    await Hive.initFlutter();
    _profileBox = await Hive.openBox('profile');
    _progressBox = await Hive.openBox('progress');
    _initialize = true;

    print("DatabaseService Initialzed Successfully");
  }

  static Future<void> saveProfile(StudentProfile profile) async {
    await _profileBox.put(profile.id, profile.toJson());
    print('✅ Profile saved: ${profile.name}');
  }

  // Get Single Profile by ID
  static StudentProfile? getProfile(String id) {
    final data = _profileBox.get(id);

    if (data == null) return null;
    return StudentProfile.fromJson(Map<String, dynamic>.from(data));
  }

  // Get All profiles
  static List<StudentProfile> getAllProfiles() {
    final profiles = <StudentProfile>[];

    for (final data in _profileBox.values) {
      profiles.add(StudentProfile.fromJson(Map<String, dynamic>.from(data)));
    }
    profiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return profiles;
  }

  // Delete Profile by ID
  static Future<void> deleteProfile(String id) async {
    await _profileBox.delete(id);
    print("Profile Delete Successully by id: $id");
  }

  // Check if there is any file exits
  static bool hasProfile() {
    return _profileBox.isNotEmpty;
  }

  // Check the lenght of file
  static int getlength() {
    return _profileBox.length;
  }

  static void printProfile() {
    final profile = getAllProfiles();
    print("Total Profiles: ${profile.length}");
    for (final p in profile) {
      print('  - ${p.name} (Class: ${p.classCode ?? "N/A"})');
    }
  }

  // ==========================================
  // PROGRESS TRACKING (NEW)
  // ==========================================

  // Save lesson progress for a student
  static Future<void> saveProgress({
    required String studentId,
    required String lessonId,
    required String status, // 'completed', 'in_progress'
    int? quizScore,
  }) async {
    final key = '${studentId}_$lessonId';
    await _progressBox.put(key, {
      'studentId': studentId,
      'lessonId': lessonId,
      'status': status,
      'quizScore': quizScore,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    print('📝 Progress saved: $lessonId -> $status (Score: $quizScore)');
  }

  // Get progress for a specific lesson
  static Map<String, dynamic>? getProgress(String studentId, String lessonId) {
    final key = '${studentId}_$lessonId';
    final data = _progressBox.get(key);
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  // Get all progress for a student
  static List<Map<String, dynamic>> getAllProgress(String studentId) {
    final progressList = <Map<String, dynamic>>[];
    for (final key in _progressBox.keys) {
      if (key.toString().startsWith('${studentId}_')) {
        final data = _progressBox.get(key);
        if (data != null) {
          progressList.add(Map<String, dynamic>.from(data));
        }
      }
    }
    return progressList;
  }

  // Get completed lessons count for a student
  static int getCompletedLessonsCount(String studentId) {
    int count = 0;
    for (final key in _progressBox.keys) {
      if (key.toString().startsWith('${studentId}_')) {
        final data = _progressBox.get(key);
        if (data != null && data['status'] == 'completed') {
          count++;
        }
      }
    }
    return count;
  }

  // Check if a lesson is completed
  static bool isLessonCompleted(String studentId, String lessonId) {
    final progress = getProgress(studentId, lessonId);
    return progress != null && progress['status'] == 'completed';
  }

  // Get total quiz score for a student
  static int getTotalQuizScore(String studentId) {
    int totalScore = 0;
    for (final key in _progressBox.keys) {
      if (key.toString().startsWith('${studentId}_')) {
        final data = _progressBox.get(key);
        if (data != null && data['quizScore'] != null) {
          totalScore += (data['quizScore'] as int);
        }
      }
    }
    return totalScore;
  }

  // Debug: Print all progress
  static void debugPrintProgress(String studentId) {
    final progress = getAllProgress(studentId);
    print('📊 Progress for student $studentId:');
    for (final p in progress) {
      print('  - ${p['lessonId']}: ${p['status']} (Score: ${p['quizScore']})');
    }
    print('  Total completed: ${getCompletedLessonsCount(studentId)}');
  }
}
