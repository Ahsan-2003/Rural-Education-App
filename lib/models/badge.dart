import 'package:flutter/material.dart';

class Badgee {
  final String id;
  final String name;
  final String description;
  final String icon; // Emoji
  final Color badgeColor;
  final BadgeType type;
  final int requiredCount; // e.g., 5 lessons for Bookworm

  Badgee({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.badgeColor,
    required this.type,
    required this.requiredCount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'color': badgeColor.value.toString(),
    'type': type.name,
    'requiredCount': requiredCount,
  };

  factory Badgee.fromJson(Map<String, dynamic> json) => Badgee(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    icon: json['icon'],
    badgeColor: Color(int.parse(json['color'])),
    type: BadgeType.values.firstWhere((t) => t.name == json['type']),
    requiredCount: json['requiredCount'],
  );
}

enum BadgeType {
  lessonsCompleted,
  quizPerfect,
  streakDays,
  allSubjects,
  quickLearner,
}
