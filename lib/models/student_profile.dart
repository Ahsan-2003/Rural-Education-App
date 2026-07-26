import 'package:uuid/uuid.dart';

class StudentProfile {
  final String id;
  final String name;
  final String pin;
  final String? classCode;
  final DateTime createdAt;

  StudentProfile({
    required this.id,
    required this.name,
    required this.pin,
    this.classCode,
    required this.createdAt,
  });

  factory StudentProfile.create({
    required String name,
    required String pin,
    String? classCode,
  }) {
    return StudentProfile(
      id: const Uuid().v4(),
      name: name,
      pin: pin,
      classCode: classCode,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'classCode': classCode,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      pin: json['pin'] as String,
      classCode: json['classCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'StudentProfile(id: $id, name: $name, classCode: $classCode)';
  }
}
