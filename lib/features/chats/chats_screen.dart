import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/user_model.dart';
import '../../shared/widgets/user_avatar.dart';
import 'chats_controller.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ChatsController>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  AppStrings.tabChats,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              // TabBar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary, width: 0.5),
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: AppStrings.generalChats),
                    Tab(text: AppStrings.personalChats),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: [
                    _GeneralChatsTab(ctrl: ctrl),
                    _PersonalChatsTab(ctrl: ctrl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneralChatsTab extends StatelessWidget {
  final ChatsController ctrl;

  const _GeneralChatsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeChatId = ctrl.activeGeneralChatId.value;
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.generalChats.length,
        itemBuilder: (_, i) {
          final chat = ctrl.generalChats[i];
          final isActive = chat.id == activeChatId;
          
          return _ChatCard(
            chat: chat,
            isActive: isActive,
            onTap: () {
              ctrl.activeGeneralChatId.value = chat.id;
              ctrl.currentMood.value = chat.mood;
              Get.to(() => ChatDetailScreen(chatRoom: chat));
            },
          );
        },
      );
    });
  }
}

class _PersonalChatsTab extends StatelessWidget {
  final ChatsController ctrl;

  const _PersonalChatsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.personalChats.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                AppStrings.noPersonalChats,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ctrl.personalChats.length,
        itemBuilder: (_, i) {
          final chat = ctrl.personalChats[i];
          return _ChatCard(
            chat: chat,
            isActive: false,
            onTap: () => Get.to(() => ChatDetailScreen(chatRoom: chat)),
          );
        },
      );
    });
  }
}

class _ChatCard extends StatelessWidget {
  final ChatRoom chat;
  final bool isActive;
  final VoidCallback onTap;

  const _ChatCard({
    required this.chat,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive 
            ? AppColors.primary.withOpacity(0.1) 
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Avatar or mood icon
            if (chat.isGeneral)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: chat.mood?.color ?? AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  chat.mood?.icon ?? Icons.chat,
                  color: Colors.white,
                  size: 28,
                ),
              )
            else if (chat.otherUser != null)
              UserAvatarWidget(user: chat.otherUser!, size: 52, showMoodRing: true)
            else
              const SizedBox(width: 52, height: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.displayName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  if (chat.isGeneral)
                    Text(
                      'Общий чат по настроению',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    )
                  else
                    Text(
                      'Нажмите чтобы начать чат',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
