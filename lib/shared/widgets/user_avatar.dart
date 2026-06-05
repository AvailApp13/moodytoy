import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';

class UserAvatarWidget extends StatelessWidget {
  final UserModel user;
  final double size;
  final bool showMoodRing;

  const UserAvatarWidget({
    super.key,
    required this.user,
    this.size = 48,
    this.showMoodRing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: showMoodRing && user.mood != null
            ? Border.all(color: user.mood!.color, width: 2)
            : Border.all(color: AppColors.border, width: 1),
      ),
      child: Center(
        child: Text(
          user.avatarEmoji ?? '👤',
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}

class ProfileAvatarWidget extends StatelessWidget {
  final UserModel user;
  final double size;

  const ProfileAvatarWidget({super.key, required this.user, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2.5),
      ),
      child: Center(
        child: Text(user.avatarEmoji ?? '😊',
            style: TextStyle(fontSize: size * 0.45)),
      ),
    );
  }
}
