import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/user_model.dart';
import '../../shared/widgets/mood_indicator.dart';
import '../../shared/widgets/user_avatar.dart';
import 'friends_controller.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FriendsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ctrl),
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: ctrl.loadAll,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Входящие запросы
                      if (ctrl.incomingRequests.isNotEmpty) ...[
                        _sectionTitle(context, AppStrings.incomingRequests),
                        ...ctrl.incomingRequests
                            .map((r) => _RequestCard(request: r, ctrl: ctrl)),
                        const SizedBox(height: 16),
                      ],
                      // Друзья
                      _sectionTitle(context, AppStrings.myFriends),
                      if (ctrl.friends.isEmpty)
                        _emptyState(context, AppStrings.noFriends)
                      else
                        ...ctrl.friends.map((u) => _FriendCard(user: u)),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FriendsController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(AppStrings.friends,
              style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          Obx(() {
            final count = ctrl.incomingRequests.length;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                '${AppStrings.friendRequests} · $count',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: AppColors.textHint, letterSpacing: 0.5)),
    );
  }

  Widget _emptyState(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textHint)),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final dynamic request;
  final FriendsController ctrl;

  const _RequestCard({required this.request, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final user = request.requester as UserModel?;
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          UserAvatarWidget(user: user, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.name,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: AppColors.success),
            onPressed: () =>
                ctrl.acceptRequest(request.id, request.requesterId),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
            onPressed: () => ctrl.declineRequest(request.id),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final UserModel user;

  const _FriendCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
                  const SizedBox(height: 4),
                  MoodChip(mood: user.mood!),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}
