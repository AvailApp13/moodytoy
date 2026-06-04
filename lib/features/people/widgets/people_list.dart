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
  const PeopleList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMoodFilter(context),
        Expanded(
          child: Obx(() {
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
                itemBuilder: (ctx, i) => _UserCard(user: users[i]),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMoodFilter(BuildContext context) {
    final filters = [
      (null, AppStrings.filterAll),
      ('ready', AppStrings.filterReady),
      ('waiting', AppStrings.filterWaiting),
      ('sad', AppStrings.filterSad),
    ];
    return SizedBox(
      height: 38,
      child: Obx(() => ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: filters.map((f) {
              final isSelected = controller.selectedMoodFilter.value == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f.$2),
                  selected: isSelected,
                  onSelected: (_) => controller.setMoodFilter(f.$1),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final friends = Get.find<FriendsController>();
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
                if (user.distanceMeters != null)
                  Text(AppStrings.distance(user.distanceMeters!),
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          _AddFriendButton(user: user, friendsCtrl: friends),
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
      if (status == FriendshipStatus.accepted) return const SizedBox.shrink();
      final isPending = status == FriendshipStatus.pending;
      return GestureDetector(
        onTap: isPending ? null : () => friendsCtrl.sendRequest(user.id),
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
