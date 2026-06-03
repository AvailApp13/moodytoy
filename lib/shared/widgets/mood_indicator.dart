import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';

// ── Цветной индикатор настроения ──────────────────────────

class MoodIndicator extends StatelessWidget {
  final Mood mood;
  final double size;

  const MoodIndicator({
    super.key,
    required this.mood,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: mood.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: mood.color.withOpacity(0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ── Чип настроения ────────────────────────────────────────

class MoodChip extends StatelessWidget {
  final Mood mood;

  const MoodChip({super.key, required this.mood});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: mood.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: mood.color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: mood.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            mood.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: mood.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Три кнопки настроения ─────────────────────────────────

class MoodSelector extends StatelessWidget {
  final Mood? selected;
  final ValueChanged<Mood> onSelect;

  const MoodSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Mood.values.map((mood) {
        final isSelected = selected == mood;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelect(mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? mood.color.withOpacity(0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? mood.color : AppColors.border,
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    MoodIndicator(mood: mood, size: 10),
                    const SizedBox(height: 4),
                    Text(
                      mood.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? mood.color : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
