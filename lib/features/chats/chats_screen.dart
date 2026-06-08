import '../../shared/widgets/translated_text.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_controller.dart';
import 'chats_controller.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late ChatsController _ctrl;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _ctrl = Get.find<ChatsController>();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: TabBarView(controller: _tab, children: [
            _buildGeneralChats(),
            _buildPersonalChats(),
          ])),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Align(alignment: Alignment.centerLeft,
            child: Text('chats_title'.tr, style: Theme.of(context).textTheme.headlineMedium)),
      ),
      TabBar(
        controller: _tab,
        tabs: [Tab(text: 'chats_general'.tr), Tab(text: 'chats_personal'.tr)],
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.border,
      ),
    ]);
  }

  Widget _buildGeneralChats() {
    final auth = Get.find<AuthController>();
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: ChatsController.moodChats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final mood = ChatsController.moodChats[i];
        return Obx(() {
          final currentMood = auth.currentUser.value?.mood;
          final isActive = currentMood == mood;
          final messages = _ctrl.getMessages(mood.value);
          final lastMsg = messages.isNotEmpty ? messages.last : null;
          return GestureDetector(
            onTap: () {
              auth.updateMood(mood);
              Get.to(() => ChatPage(
                chatId: mood.value,
                title: mood.label,
                color: mood.color,
                avatarEmoji: mood.emoji,
              ));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isActive ? mood.color.withOpacity(0.15) : AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? mood.color : AppColors.border,
                  width: isActive ? 1.5 : 0.5,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: mood.color.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(child: Text(mood.emoji,
                      style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(mood.label, style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w600)),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: mood.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('chats_active'.tr,
                              style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    if (lastMsg != null)
                      Text(
                        lastMsg.imageBase64 != null
                            ? 'chats_photo'.tr
                            : '${_ctrl.getSenderName(lastMsg.senderId)}: ${lastMsg.text}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text('chats_start'.tr,
                          style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                )),
                const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
              ]),
            ),
          );
        });
      },
    );
  }

  Widget _buildPersonalChats() {
    return GetBuilder<ChatsController>(
      builder: (ctrl) {
        ctrl.loadPersonalChats();
        if (ctrl.personalChats.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('💬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Добавьте друзей чтобы начать переписку',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ]));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: ctrl.personalChats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final friendId = ctrl.personalChats[i];
            final friend = ctrl.getFriendUser(friendId);
            if (friend == null) return const SizedBox();
            final personalId = ctrl.personalChatId(friendId);
            final messages = ctrl.getMessages(personalId);
            final lastMsg = messages.isNotEmpty ? messages.last : null;
            return GestureDetector(
              onTap: () => Get.to(() => ChatPage(
                chatId: personalId,
                title: friend.name,
                color: friend.mood?.color ?? AppColors.primary,
                avatarEmoji: friend.avatarEmoji,
              )),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: friend.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: friend.mood?.color ?? AppColors.border, width: 2),
                    ),
                    child: Center(child: Text(friend.avatarEmoji ?? '👤',
                        style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friend.name, style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      if (lastMsg != null)
                        Text(
                          lastMsg.imageBase64 != null
                              ? (lastMsg.isMe ? 'Вы: 📷 Фото' : 'chats_photo'.tr)
                              : (lastMsg.isMe ? '${'chats_me_prefix'.tr}${lastMsg.text}' : lastMsg.text),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        )
                      else
                        Text('chats_first'.tr,
                            style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                    ],
                  )),
                  const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
                ]),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Экран чата ────────────────────────────────────────────
class ChatPage extends StatefulWidget {
  final String chatId;
  final String title;
  final Color color;
  final String? avatarEmoji;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.title,
    required this.color,
    this.avatarEmoji,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  late ChatsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<ChatsController>();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: Colors.white),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.3), shape: BoxShape.circle),
            child: Center(child: Text(
              widget.avatarEmoji ?? widget.title[0],
              style: const TextStyle(fontSize: 16),
            )),
          ),
          const SizedBox(width: 8),
          Text(widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ]),
        elevation: 0,
      ),
      body: Column(children: [
        Expanded(
          child: GetBuilder<ChatsController>(
            id: widget.chatId,
            builder: (ctrl) {
              final messages = ctrl.getMessages(widget.chatId);
              if (messages.isEmpty) {
                return Center(child: Text('chats_begin'.tr,
                    style: TextStyle(color: AppColors.textHint)));
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollCtrl.hasClients) {
                  _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                }
              });
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (_, i) => _MessageBubble(
                  message: messages[i],
                  ctrl: ctrl,
                  chatColor: widget.color,
                ),
              );
            },
          ),
        ),
        _buildInput(),
      ]),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(children: [
        // Кнопка фото
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant, shape: BoxShape.circle),
            child: const Icon(Icons.photo_outlined,
                color: AppColors.textSecondary, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: TextField(
              controller: _textCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'input_placeholder'.tr,
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                isDense: true, border: InputBorder.none,
              ),
              maxLines: null,
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
    );
  }

  void _send() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    _ctrl.sendMessage(widget.chatId, text);
  }

  Future<void> _pickImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;
    final file = await _picker.pickImage(
        source: source, imageQuality: 70, maxWidth: 800);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    final base64 = base64Encode(bytes);
    _ctrl.sendImageMessage(widget.chatId, base64);
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await Get.dialog<ImageSource>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Отправить фото',
            style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            title: const Text('Камера', style: TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
            title: const Text('Галерея', style: TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: ImageSource.gallery),
          ),
        ]),
      ),
    );
  }
}

// ── Пузырь сообщения ──────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Message message;
  final ChatsController ctrl;
  final Color chatColor;

  const _MessageBubble({
    required this.message,
    required this.ctrl,
    required this.chatColor,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                color: chatColor.withOpacity(0.2), shape: BoxShape.circle),
              child: Center(child: Text(
                ctrl.getSenderName(message.senderId).isNotEmpty
                    ? ctrl.getSenderName(message.senderId)[0] : '?',
                style: TextStyle(color: chatColor, fontSize: 12),
              )),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(ctrl.getSenderName(message.senderId),
                        style: TextStyle(fontSize: 11, color: chatColor)),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65),
                  decoration: BoxDecoration(
                    color: isMe ? chatColor : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                  ),
                  child: message.imageBase64 != null
                      ? _buildImageContent(message.imageBase64!)
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Text(message.text,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(String base64) {
    try {
      final bytes = base64Decode(base64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(bytes, width: 200, height: 200, fit: BoxFit.cover),
      );
    } catch (_) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('chats_photo'.tr, style: const TextStyle(color: Colors.white)),
      );
    }
  }
}
