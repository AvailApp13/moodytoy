import '../../shared/widgets/translated_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../chats/chats_controller.dart';
import '../chats/chats_screen.dart';
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
              child: GetBuilder<FriendsController>(
                builder: (c) => ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
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
          Row(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                    color: user.mood?.color ?? AppColors.border, width: 2),
              ),
              child: Center(child: Text(user.avatarEmoji ?? '👤',
                  style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${user.name}, ${user.age ?? '?'}',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.bold)),
              if (user.mood != null)
                Text('${user.mood!.emoji} ${user.mood!.label}',
                    style: TextStyle(color: user.mood!.color, fontSize: 13)),
              if (user.bio != null)
                TranslatedText(user.bio,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back();
                final chatsCtrl = Get.find<ChatsController>();
                Get.to(() => _ChatPage(
                  chatId: 'personal_${user.id}',
                  title: user.name,
                  color: user.mood?.color ?? AppColors.primary,
                  avatarEmoji: user.avatarEmoji,
                ));
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('btn_write'.tr),
            ),
          ),
        ]),
      ),
    );
  }
}

// Inline import of ChatPage to avoid circular dependency
class _ChatPage extends StatefulWidget {
  final String chatId;
  final String title;
  final Color color;
  final String? avatarEmoji;
  const _ChatPage({required this.chatId, required this.title,
      required this.color, this.avatarEmoji});

  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late ChatsController _chatsCtrl;

  @override
  void initState() {
    super.initState();
    _chatsCtrl = Get.find<ChatsController>();
  }

  @override
  void dispose() { _textCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: Colors.white),
        title: Text(widget.title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        elevation: 0,
      ),
      body: Column(children: [
        Expanded(
          child: GetBuilder<ChatsController>(
            id: widget.chatId,
            builder: (ctrl) {
              final messages = ctrl.getMessages(widget.chatId);
              if (messages.isEmpty) {
                return Center(child: Text('Напишите первым!',
                    style: const TextStyle(color: AppColors.textHint)));
              }
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final msg = messages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: msg.isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: msg.isMe
                                ? widget.color
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(msg.text,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Написать...',
                    hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                    isDense: true, border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: widget.color, shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _chatsCtrl.sendMessage(widget.chatId, text);
  }
}
