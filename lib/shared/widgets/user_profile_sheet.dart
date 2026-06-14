import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/supabase_repository.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/friends/friends_controller.dart';
import '../../features/chats/chats_controller.dart';
import '../../features/chats/chats_screen.dart';
import 'translated_text.dart';

/// Единый попап профиля пользователя — используется в Люди, Друзья и Чатах.
void showUserProfileSheet(UserModel user) {
  Get.bottomSheet(
    _UserProfileSheet(user: user),
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  );
}

class _UserProfileSheet extends StatelessWidget {
  final UserModel user;
  const _UserProfileSheet({required this.user});

  String _formatBirth(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final mood = user.mood;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Хваталка
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),

            // Аватар с настроением + онлайн
            Stack(children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: mood?.color ?? AppColors.border, width: 3),
                ),
                child: Center(child: Text(user.avatarEmoji ?? '👤',
                    style: const TextStyle(fontSize: 44))),
              ),
              if (user.isOnline) Positioned(
                right: 4, bottom: 4,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 3),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Имя + возраст
            Text(
              user.age != null ? '${user.name}, ${user.age}' : user.name,
              style: const TextStyle(color: Colors.white,
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Онлайн/офлайн
            Text(
              user.isOnline ? 'status_online'.tr : 'status_offline'.tr,
              style: TextStyle(
                  color: user.isOnline ? AppColors.success : AppColors.textHint,
                  fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Настроение цветной плашкой
            if (mood != null) Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: mood.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mood.color, width: 1),
              ),
              child: Text('${mood.emoji} ${mood.label}',
                  style: TextStyle(color: mood.color, fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            // Карточка с инфо
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _row(Icons.location_on_outlined, 'profile_city'.tr,
                    user.city?.isNotEmpty == true ? user.city! : 'profile_not_set'.tr),
                const SizedBox(height: 12),
                _row(Icons.cake_outlined, 'profile_birth'.tr,
                    user.birthDate != null ? _formatBirth(user.birthDate!) : 'profile_not_set'.tr),
                if (user.bio?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.textHint),
                    const SizedBox(width: 10),
                    Expanded(child: TranslatedText(user.bio,
                        style: const TextStyle(color: Colors.white, fontSize: 14))),
                  ]),
                ],
              ]),
            ),
            const SizedBox(height: 16),

            // Подключённые игрушки (коллекция)
            _ToysBlock(userId: user.id),
            const SizedBox(height: 16),

            // Кнопка действия (в друзья / написать)
            SizedBox(
              width: double.infinity,
              child: GetBuilder<FriendsController>(
                builder: (fc) => _actionButton(fc),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.textHint),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      Expanded(child: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 14))),
    ]);
  }

  Widget _actionButton(FriendsController fc) {
    final myId = Get.find<AuthController>().currentUser.value?.id ?? '';
    if (user.id == myId) return const SizedBox.shrink();

    final status = fc.getStatus(user.id);
    if (status == FriendStatus.friend) {
      return ElevatedButton.icon(
        onPressed: () {
          Get.back();
          final chatsCtrl = Get.find<ChatsController>();
          Get.to(() => ChatPage(
            chatId: chatsCtrl.personalChatId(user.id),
            title: user.name,
            color: user.mood?.color ?? AppColors.primary,
            avatarEmoji: user.avatarEmoji,
          ));
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 16),
        label: Text('btn_write'.tr),
      );
    }
    if (status == FriendStatus.outgoing) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceVariant),
        child: Text('btn_request_sent'.tr),
      );
    }
    if (status == FriendStatus.incoming) {
      return ElevatedButton(
        onPressed: () { fc.acceptRequest(user.id); Get.back(); },
        child: Text('btn_accept_request'.tr),
      );
    }
    return ElevatedButton.icon(
      onPressed: () { fc.sendRequest(user.id); Get.back(); },
      icon: const Icon(Icons.person_add_outlined, size: 16),
      label: Text('btn_add_friend'.tr),
    );
  }
}

// ── Блок подключённых игрушек ───────────────────────────────
class _ToysBlock extends StatelessWidget {
  final String userId;
  const _ToysBlock({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupabaseRepository.getUserToys(userId),
      builder: (context, snapshot) {
        final toys = snapshot.data ?? [];
        if (toys.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.toys_outlined, size: 16, color: AppColors.textHint),
            const SizedBox(width: 8),
            Text('profile_toys_title'.tr,
                style: const TextStyle(color: AppColors.textSecondary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ...toys.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Text((t['emoji'] ?? '🧸').toString(),
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((t['name'] ?? 'Toy').toString(),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(
                    '${t['series'] ?? ''} · #${(t['serial_number'] ?? '').toString()}',
                    style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              )),
            ]),
          )),
        ]);
      },
    );
  }
}
