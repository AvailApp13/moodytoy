import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class MoodChip extends StatelessWidget {
  final Mood mood;
  final bool compact;

  const MoodChip({super.key, required this.mood, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: mood.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: mood.color.withOpacity(0.5), width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(mood.emoji, style: TextStyle(fontSize: compact ? 10 : 12)),
        SizedBox(width: compact ? 3 : 4),
        Text(mood.label,
            style: TextStyle(
                color: mood.color,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
