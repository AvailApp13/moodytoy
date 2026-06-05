import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/friendship_model.dart';
import '../../../shared/widgets/mood_indicator.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../friends/friends_controller.dart';
import '../people_controller.dart';

class PeopleList extends StatelessWidget {
  final PeopleController controller;
  final FriendsController friendsCtrl;
  
  const PeopleList({super.key, required this.controller, required this.friendsCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final users = controller.filteredUsers;
      if (users.isEmpty) {
        return Center(
          child: Text('Никого нет рядом',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textHint,
                  )),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.refresh,
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _UserCard(user: users[i], friendsCtrl: friendsCtrl),
        ),
      );
    });
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final FriendsController friendsCtrl;
  
  const _UserCard({required this.user, required this.friendsCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          UserAvatarWidget(user: user, size: 52, showMoodRing: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.name}, ${user.age ?? '?'}',
                    style: Theme.of(context).textTheme.labelLarge),
                if (user.mood != null) ...[
                  const SizedBox(height: 3),
                  MoodChip(mood: user.mood!),
                ],
              ],
            ),
          ),
          _AddFriendButton(user: user, friendsCtrl: friendsCtrl),
        ],
      ),
    );
  }
}

class _AddFriendButton extends StatelessWidget {
  final UserModel user;
  final FriendsController friendsCtrl;
  
  const _AddFriendButton({required this.user, required this.friendsCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = friendsCtrl.getFriendStatusWith(user.id);
      
      if (status == FriendshipStatus.accepted) {
        // Уже друзья - кнопка "Написать"
        return GestureDetector(
          onTap: () {
            Get.snackbar('Чат', 'Открывается чат с ${user.name}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success, width: 0.5),
            ),
            child: const Icon(Icons.chat, size: 16, color: AppColors.success),
          ),
        );
      }
      
      final isIncoming = friendsCtrl.incomingRequests.any((r) => r.requesterId == user.id);
      
      if (isIncoming) {
        // Входящий запрос - кнопка "Принять"
        return GestureDetector(
          onTap: () {
            final request = friendsCtrl.incomingRequests.firstWhere(
              (r) => r.requesterId == user.id,
            );
            friendsCtrl.acceptRequest(request.id, user.id);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success, width: 0.5),
            ),
            child: const Text('Принять',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
          ),
        );
      }
      
      final isPending = status == FriendshipStatus.pending;
      
      return GestureDetector(
        onTap: isPending ? null : () {
          friendsCtrl.sendRequest(user.id);
          Get.snackbar('Дружба', 'Запрос отправлен пользователю ${user.name}');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPending
                ? AppColors.surfaceVariant
                : AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPending ? AppColors.border : AppColors.primary,
              width: 0.5,
            ),
          ),
          child: Text(
            isPending ? AppStrings.requestSent : AppStrings.addFriend,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isPending ? AppColors.textHint : AppColors.primary,
            ),
          ),
        ),
      );
    });
  }
}
