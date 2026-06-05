import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF4A9EFF);
  static const Color primaryDark = Color(0xFF2E7DD4);
  static const Color primaryLight = Color(0xFF7BBEFF);

  // Background
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF242440);
  static const Color card = Color(0xFF1E1E35);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textHint = Color(0xFF6B6B8A);
  static const Color textDisabled = Color(0xFF3A3A5C);

  // Mood colors - новые цвета настроений из ТЗ
  static const Color moodCoffeeBreak = Color(0xFF6F4E37);  // Коричневый
  static const Color moodGamer = Color(0xFF4CAF50);        // Зелёный
  static const Color moodDating = Color(0xFFFF6B6B);       // Розовый
  static const Color moodWalk = Color(0xFF4A90E2);         // Голубой
  static const Color moodSport = Color(0xFFFF9800);        // Оранжевый

  // Старые названия для совместимости (удалить позже)
  @Deprecated('Используйте moodCoffeeBreak')
  static const Color moodReady = Color(0xFF4CAF50);
  @Deprecated('Используйте moodSport')
  static const Color moodWaiting = Color(0xFFFFB300);
  @Deprecated('Используйте moodWalk')
  static const Color moodSad = Color(0xFF4A9EFF);
  @Deprecated('Не используется')
  static const Color moodExtra = Color(0xFFE040FB);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF4A9EFF);

  // Battery
  static const Color batteryGood = Color(0xFF4CAF50);    // > 50%
  static const Color batteryMedium = Color(0xFFFFB300);  // 20-50%
  static const Color batteryLow = Color(0xFFEF5350);     // < 20%

  // Border / Divider
  static const Color border = Color(0xFF2A2A45);
  static const Color divider = Color(0xFF1E1E35);

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color shimmerBase = Color(0xFF1E1E35);
  static const Color shimmerHighlight = Color(0xFF2A2A45);

  // Bottom nav
  static const Color navBackground = Color(0xFF141428);
  static const Color navSelected = Color(0xFF4A9EFF);
  static const Color navUnselected = Color(0xFF4A4A6A);

  // Map marker ring animation
  static const Color mapRing = Color(0x404A9EFF);
}
