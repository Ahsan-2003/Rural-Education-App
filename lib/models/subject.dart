import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final String icon; // Emoji icon
  final Color color;
  final Color gradientStart;
  final Color gradientEnd;
  final int lessonCount;
  final String description;

  Subject({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.gradientStart,
    required this.gradientEnd,
    required this.lessonCount,
    required this.description,
  });
}
