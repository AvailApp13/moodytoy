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
import '../../data/repositories/supabase_repository.dart';
import '../../core/services/translation_service.dart';
import '../../shared/widgets/user_profile_sheet.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _personalSearch = '';
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
          final online = _ctrl.moodOnline[mood.value] ?? 0;
          final unread = _ctrl.hasUnread(mood.value);
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
                      if (online > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 3),
                        Text('$online', style: TextStyle(
                            fontSize: 11, color: AppColors.success)),
                      ],
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
                if (unread)
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: mood.color, shape: BoxShape.circle),
                  )
                else
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
            Text('💬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('chats_add_friends'.tr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ]));
        }
        // Фильтр по имени друга
        final q = _personalSearch.trim().toLowerCase();
        final filtered = q.isEmpty
            ? ctrl.personalChats.toList()
            : ctrl.personalChats.where((fid) {
                final f = ctrl.getFriendUser(fid);
                return f != null && f.name.toLowerCase().contains(q);
              }).toList();
        return Column(children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              onChanged: (v) => setState(() => _personalSearch = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'chats_search_hint'.tr,
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
              ? Center(child: Text('chats_search_empty'.tr,
                  style: TextStyle(color: AppColors.textHint)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final friendId = filtered[i];
            final friend = ctrl.getFriendUser(friendId);
            if (friend == null) return const SizedBox();
            final personalId = ctrl.personalChatId(friendId);
            final messages = ctrl.getMessages(personalId);
            final lastMsg = messages.isNotEmpty ? messages.last : null;
            final unread = ctrl.hasUnread(personalId);
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
                  Stack(children: [
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
                    if (friend.isOnline) Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
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
                      Text(friend.name, style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      if (lastMsg != null)
                        Text(
                          lastMsg.imageBase64 != null
                              ? (lastMsg.isMe ? '${'chats_you_prefix'.tr}: 📷 ${'chats_photo_label'.tr}' : 'chats_photo'.tr)
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (lastMsg != null)
                        Text(
                          '${lastMsg.time.hour.toString().padLeft(2, '0')}:${lastMsg.time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                        ),
                      const SizedBox(height: 4),
                      if (unread)
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                              color: friend.mood?.color ?? AppColors.primary,
                              shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ]),
              ),
            );
          },
        ),
          ),
        ]);
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
    // Отметить прочитанным при открытии и после загрузки сообщений
    _ctrl.markRead(widget.chatId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.markRead(widget.chatId);
    });
    // Для общего чата — обновить счётчик онлайн
    if (!widget.chatId.startsWith('personal_')) {
      _ctrl.refreshMoodOnline();
    }
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    overflow: TextOverflow.ellipsis),
                // Для общих чатов — "N в сети"
                if (!widget.chatId.startsWith('personal_'))
                  Obx(() {
                    final n = _ctrl.moodOnline[widget.chatId] ?? 0;
                    return Text(
                      '$n ${'chats_online_count'.tr}',
                      style: TextStyle(
                          color: AppColors.success, fontSize: 11),
                    );
                  }),
              ],
            ),
          ),
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
        title: Text('chats_send_photo'.tr,
            style: const TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            title: Text('chats_camera'.tr, style: const TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Colors.white),
            title: Text('chats_gallery'.tr, style: const TextStyle(color: Colors.white)),
            onTap: () => Get.back(result: ImageSource.gallery),
          ),
        ]),
      ),
    );
  }
}

// ── Пузырь сообщения ──────────────────────────────────────
class _MessageBubble extends StatefulWidget {
  final Message message;
  final ChatsController ctrl;
  final Color chatColor;

  const _MessageBubble({
    required this.message,
    required this.ctrl,
    required this.chatColor,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  String? _translated;
  bool _translating = false;

  Future<void> _openProfile() async {
    final senderId = widget.message.senderId;
    final myId = Get.find<AuthController>().currentUser.value?.id ?? '';
    if (senderId == myId || senderId == 'me') return;
    // Сначала ищем среди друзей, иначе грузим из Supabase
    UserModel? user = widget.ctrl.getFriendUser(senderId);
    user ??= await SupabaseRepository.getUserById(senderId);
    if (user != null) showUserProfileSheet(user);
  }

  Future<void> _translate() async {
    if (_translating) return;
    setState(() => _translating = true);
    final result =
        await TranslationService.translateMessage(widget.message.text);
    if (!mounted) return;

    if (result == null) {
      // Показываем реальную причину для диагностики
      setState(() => _translating = false);
      Get.snackbar(
        'translate_failed'.tr,
        TranslationService.lastError ?? 'translate_unknown'.tr,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 8),
      );
      return;
    }

    setState(() {
      _translated = result;
      _translating = false;
    });

    // Если перевод совпал с оригиналом — подсказка (тот же язык)
    if (result.trim() == widget.message.text.trim()) {
      Get.snackbar(
        '',
        'chats_translate_same'.tr,
        backgroundColor: AppColors.surface,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final ctrl = widget.ctrl;
    final chatColor = widget.chatColor;
    final isMe = message.isMe;
    final senderName = ctrl.getSenderName(message.senderId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            GestureDetector(
              onTap: _openProfile,
              child: Container(
                width: 28, height: 28,
                margin: const EdgeInsets.only(right: 6, bottom: 2),
                decoration: BoxDecoration(
                  color: chatColor.withOpacity(0.2), shape: BoxShape.circle),
                child: Center(child: Text(
                  senderName.isNotEmpty ? senderName[0] : '?',
                  style: TextStyle(color: chatColor, fontSize: 12),
                )),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  GestureDetector(
                    onTap: _openProfile,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(senderName,
                          style: TextStyle(fontSize: 11, color: chatColor)),
                    ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message.text,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14)),
                              if (_translated != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    border: Border(top: BorderSide(
                                        color: Colors.white24, width: 0.5)),
                                  ),
                                  child: Text(_translated!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic)),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
                // Время + кнопка перевода
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                      ),
                      // Перевод — только для текстовых сообщений и если ещё не переведено
                      if (message.imageBase64 == null &&
                          message.text.trim().isNotEmpty &&
                          _translated == null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _translate,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.translate,
                                size: 11, color: chatColor.withOpacity(0.8)),
                            const SizedBox(width: 3),
                            Text(
                              _translating ? 'chats_translating'.tr : 'chats_translate'.tr,
                              style: TextStyle(fontSize: 10,
                                  color: chatColor.withOpacity(0.8)),
                            ),
                          ]),
                        ),
                      ],
                    ],
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
