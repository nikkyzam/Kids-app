import 'package:flutter/material.dart';

class BadgeDefinition {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;

  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
  });
}
