import '../../shared/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../chats/chats_controller.dart';
import '../chats/chats_screen.dart';
import 'friends_controller.dart';
import '../../data/repositories/supabase_repository.dart';
import '../auth/auth_controller.dart';

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
              child: GetBuilder<FriendsController>(
                builder: (c) => ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    const _FriendSearchBar(),
                    const SizedBox(height: 12),
                    if (c.incomingRequests.isNotEmpty) ...[
                      _sectionLabel('incoming_requests'.tr),
                      ...c.incomingRequests.map(
                        (u) => _RequestCard(user: u, ctrl: c)),
                      const SizedBox(height: 12),
                    ],
                    _sectionLabel('my_friends'.tr),
                    if (c.friends.isEmpty)
                      _buildEmpty(context)
                    else
                      ...c.friends.map((u) => _FriendCard(user: u)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FriendsController ctrl) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('friends_title'.tr,
                  style: Theme.of(context).textTheme.headlineMedium),
              GetBuilder<FriendsController>(
                builder: (c) => Text(
                  '${c.friends.length} ${'friends_count'.tr} · ${c.incomingRequests.length} ${'requests_count'.tr}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        GetBuilder<FriendsController>(
          builder: (c) => c.incomingRequests.isNotEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.error, width: 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.notifications_outlined,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text('Запросы · ${c.incomingRequests.length}',
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                )
              : const SizedBox(),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4, left: 2),
    child: Text(text,
        style: const TextStyle(
            color: AppColors.textHint, fontSize: 11,
            fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );

  Widget _buildEmpty(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Center(
      child: Column(children: [
        const Text('👋', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('friends_empty'.tr,
            style: Theme.of(context).textTheme.bodyMedium),
      ]),
    ),
  );
}

// ── Карточка входящего запроса ────────────────────────────
class _RequestCard extends StatelessWidget {
  final UserModel user;
  final FriendsController ctrl;
  const _RequestCard({required this.user, required this.ctrl});

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
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(user.avatarEmoji ?? '👤',
              style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user.name}, ${user.age ?? '?'}',
                style: const TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('wants_friend'.tr,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        )),
        Row(children: [
          GestureDetector(
            onTap: () => ctrl.acceptRequest(user.id),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 1),
              ),
              child: const Icon(Icons.check, color: AppColors.success, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ctrl.declineRequest(user.id),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.error, width: 1),
              ),
              child: const Icon(Icons.close, color: AppColors.error, size: 18),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Карточка друга ────────────────────────────────────────
class _FriendCard extends StatelessWidget {
  final UserModel user;
  const _FriendCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFriendSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Stack(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                    color: user.mood?.color ?? AppColors.border, width: 2),
              ),
              child: Center(child: Text(user.avatarEmoji ?? '👤',
                  style: const TextStyle(fontSize: 22))),
            ),
            if (user.isOnline) Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: const TextStyle(color: Colors.white,
                  fontSize: 15, fontWeight: FontWeight.w600)),
              if (user.mood != null)
                Text('${user.mood!.emoji} ${user.mood!.label}',
                    style: TextStyle(color: user.mood!.color, fontSize: 12)),
            ],
          )),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }

  void _showFriendSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          // Аватар с настроением + онлайн
          Stack(children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                    color: user.mood?.color ?? AppColors.border, width: 3),
              ),
              child: Center(child: Text(user.avatarEmoji ?? '👤',
                  style: const TextStyle(fontSize: 44))),
            ),
            if (user.isOnline) Positioned(
              right: 4, bottom: 4,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
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
                color: user.isOnline ? const Color(0xFF4CAF50) : AppColors.textHint,
                fontSize: 13),
          ),
          const SizedBox(height: 16),
          // Настроение в цвете
          if (user.mood != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: user.mood!.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: user.mood!.color, width: 1),
            ),
            child: Text('${user.mood!.emoji} ${user.mood!.label}',
                style: TextStyle(color: user.mood!.color, fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          // Карточка с инфо: город, о себе
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _sheetRow(Icons.location_on_outlined, 'profile_city'.tr,
                  user.city?.isNotEmpty == true ? user.city! : 'profile_not_set'.tr),
              const SizedBox(height: 12),
              _sheetRow(Icons.cake_outlined, 'profile_age'.tr,
                  user.age != null ? '${user.age}' : 'profile_not_set'.tr),
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
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
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sheetRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.textHint),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      Expanded(child: Text(value,
          style: const TextStyle(color: Colors.white, fontSize: 14))),
    ]);
  }
}

// ── Поиск друга по User ID ────────────────────────────────
class _FriendSearchBar extends StatefulWidget {
  const _FriendSearchBar();
  @override
  State<_FriendSearchBar> createState() => _FriendSearchBarState();
}

class _FriendSearchBarState extends State<_FriendSearchBar> {
  final _ctrl = TextEditingController();
  bool _searching = false;
  bool _searched = false;
  UserModel? _result;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _ctrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _searching = true; _searched = false; _result = null; });

    final user = await SupabaseRepository.findUserByUserId(query);
    final myId = Get.find<AuthController>().currentUser.value?.userId;

    if (!mounted) return;
    setState(() {
      _searching = false;
      _searched = true;
      // Не показываем самого себя
      _result = (user != null && user.userId != myId) ? user : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'friend_search_hint'.tr,
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _searching ? null : _search,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _searching
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('friend_search_btn'.tr,
                      style: const TextStyle(color: Colors.white, fontSize: 14,
                          fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        if (_searched && _result == null)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Text('friend_not_found'.tr,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _SearchResultCard(user: _result!, onAdded: () {
              setState(() { _result = null; _searched = false; _ctrl.clear(); });
            }),
          ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onAdded;
  const _SearchResultCard({required this.user, required this.onAdded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(user.avatarEmoji ?? '👤',
              style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslatedText(user.name, style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            if (user.userId != null)
              Text('ID: ${user.userId}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        )),
        GetBuilder<FriendsController>(
          builder: (fc) {
            final status = fc.getStatus(user.id);
            if (status == FriendStatus.friend) {
              return Text('btn_friend_label'.tr,
                  style: const TextStyle(color: AppColors.success, fontSize: 12));
            }
            if (status == FriendStatus.outgoing) {
              return Text('btn_request_sent'.tr,
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12));
            }
            return GestureDetector(
              onTap: () {
                fc.sendRequest(user.id);
                onAdded();
                Get.snackbar('', 'btn_request_sent'.tr,
                    backgroundColor: AppColors.surface, colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                    margin: const EdgeInsets.all(16));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text('btn_friend'.tr,
                    style: const TextStyle(color: AppColors.primary, fontSize: 12)),
              ),
            );
          },
        ),
      ]),
    );
  }
}
