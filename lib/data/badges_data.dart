import 'package:flutter/material.dart';
import '../models/badge_definition.dart';
import '../theme/app_theme.dart';

class BadgesData {
  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'first_step',
      title: 'First Step',
      description: 'Complete your very first daily activity',
      emoji: '👶',
      color: AppTheme.primary,
    ),
    BadgeDefinition(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Reach a 7-day activity streak',
      emoji: '🔥',
      color: Color(0xFFFF7043),
    ),
    BadgeDefinition(
      id: 'monthly_marvel',
      title: 'Monthly Marvel',
      description: 'Reach a 30-day activity streak',
      emoji: '🌟',
      color: Color(0xFFF5A623),
    ),
    BadgeDefinition(
      id: 'perfect_week',
      title: 'Perfect Week',
      description: 'Complete an activity every day for a full week',
      emoji: '🏆',
      color: Color(0xFFF5A623),
    ),
    BadgeDefinition(
      id: 'century',
      title: 'Century Club',
      description: 'Complete 100 activities in total',
      emoji: '💯',
      color: AppTheme.cognitiveColor,
    ),
    BadgeDefinition(
      id: 'all_skills',
      title: 'All-Rounder',
      description: 'Try activities across all 6 skill categories',
      emoji: '🌈',
      color: AppTheme.sensoryColor,
    ),
    BadgeDefinition(
      id: 'milestone_first',
      title: 'Milestone Moment',
      description: 'Record your first developmental milestone',
      emoji: '⭐',
      color: AppTheme.secondary,
    ),
    BadgeDefinition(
      id: 'milestone_25',
      title: 'Milestone Master',
      description: 'Achieve 25 developmental milestones',
      emoji: '🎓',
      color: AppTheme.fineMotorColor,
    ),
    BadgeDefinition(
      id: 'gross_motor_10',
      title: 'Motor Champ',
      description: 'Complete 10 gross motor activities',
      emoji: '🏃',
      color: AppTheme.grossMotorColor,
    ),
    BadgeDefinition(
      id: 'language_10',
      title: 'Chatterbox',
      description: 'Complete 10 language activities',
      emoji: '💬',
      color: AppTheme.languageColor,
    ),
    BadgeDefinition(
      id: 'cognitive_10',
      title: 'Brain Boost',
      description: 'Complete 10 cognitive activities',
      emoji: '🧠',
      color: AppTheme.cognitiveColor,
    ),
    BadgeDefinition(
      id: 'social_10',
      title: 'Social Butterfly',
      description: 'Complete 10 social-emotional activities',
      emoji: '🦋',
      color: AppTheme.socialEmotionalColor,
    ),
    BadgeDefinition(
      id: 'sensory_10',
      title: 'Sensory Explorer',
      description: 'Complete 10 sensory activities',
      emoji: '✨',
      color: AppTheme.sensoryColor,
    ),
    BadgeDefinition(
      id: 'fine_motor_10',
      title: 'Fine Artist',
      description: 'Complete 10 fine motor activities',
      emoji: '🎨',
      color: AppTheme.fineMotorColor,
    ),
  ];

  static BadgeDefinition? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
