import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import 'mood_indicator.dart';

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
    final ringWidth = showMoodRing && user.mood != null ? 2.5 : 0.0;
    final ringColor = user.mood?.color ?? AppColors.border;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ringColor,
              width: ringWidth,
            ),
          ),
          child: ClipOval(
            child: user.mainPhoto != null
                ? CachedNetworkImage(
                    imageUrl: user.mainPhoto!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        if (showMoodRing && user.mood != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: MoodIndicator(mood: user.mood!, size: size * 0.3),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.person,
        color: AppColors.textHint,
        size: size * 0.5,
      ),
    );
  }
}

// ── Большой аватар профиля ────────────────────────────────

class ProfileAvatarWidget extends StatelessWidget {
  final UserModel? user;
  final double size;
  final VoidCallback? onTap;

  const ProfileAvatarWidget({
    super.key,
    required this.user,
    this.size = 72,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: user?.mainPhoto != null
                  ? CachedNetworkImage(
                      imageUrl: user!.mainPhoto!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          if (onTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: size * 0.14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.person,
        color: AppColors.textHint,
        size: size * 0.5,
      ),
    );
  }
}
