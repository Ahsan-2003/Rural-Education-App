import 'package:hive_flutter/hive_flutter.dart';
import 'package:rural_education_app/models/student_profile.dart';

class DatabaseService {
  static late Box _profileBox;
  static bool _initialize = false;

  static Future<void> init() async {
    if (_initialize) return;

    await Hive.initFlutter();
    _profileBox = await Hive.openBox('profile');
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
}
