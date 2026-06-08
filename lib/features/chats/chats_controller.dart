import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_controller.dart';
import '../friends/friends_controller.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final String? imageBase64;
  final DateTime time;
  final bool isMe;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageBase64,
    required this.time,
    required this.isMe,
  });

  factory Message.fromSupabase(Map<String, dynamic> json, String myId) => Message(
    id: json['id']?.toString() ?? '',
    senderId: json['sender_id']?.toString() ?? '',
    text: json['text'] ?? '',
    imageBase64: json['image_url'],
    time: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    isMe: json['sender_id']?.toString() == myId,
  );
}

class ChatsController extends GetxController {
  static const List<Mood> moodChats = [
    Mood.coffee, Mood.gamer, Mood.dating, Mood.walk, Mood.sport,
  ];

  final personalChats = <String>[].obs;

  // Кэш сообщений по chatId
  final Map<String, List<Message>> _cache = {};
  RealtimeChannel? _channel;

  SupabaseClient get _client => SupabaseService.client;
  String get _myId => Get.find<AuthController>().currentUser.value?.id ?? '';

  // Единый chat_id для личного чата (одинаковый для обоих участников)
  String personalChatId(String otherUserId) {
    final ids = [_myId, otherUserId]..sort();
    return 'personal_${ids.join('_')}';
  }

  @override
  void onInit() {
    super.onInit();
    loadPersonalChats();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    super.onClose();
  }

  void loadPersonalChats() {
    try {
      final fc = Get.find<FriendsController>();
      personalChats.value = fc.friends.map((u) => u.id).toList();
    } catch (_) {
      personalChats.value = [];
    }
  }

  // ── Realtime подписка на новые сообщения ──────────────
  void _subscribeRealtime() {
    try {
      _channel = _client
          .channel('public:messages')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              final row = payload.newRecord;
              final chatId = row['chat_id']?.toString() ?? '';
              if (chatId.isEmpty) return;
              final msg = Message.fromSupabase(row, _myId);
              _cache.putIfAbsent(chatId, () => []);
              // Своё сообщение — заменяем temp на реальное
              if (msg.isMe) {
                _cache[chatId]!.removeWhere((m) => m.id.startsWith('temp_')
                    && m.text == msg.text && m.imageBase64 == msg.imageBase64);
              }
              if (!_cache[chatId]!.any((m) => m.id == msg.id)) {
                _cache[chatId]!.add(msg);
                update([chatId]);
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  // ── Загрузка истории чата из Supabase ─────────────────
  Future<void> loadMessages(String chatId) async {
    try {
      final data = await _client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .limit(200);
      _cache[chatId] = (data as List)
          .map((e) => Message.fromSupabase(e, _myId))
          .toList();
      update([chatId]);
    } catch (_) {
      _cache[chatId] ??= [];
    }
  }

  List<Message> getMessages(String chatId) {
    // Если кэша нет — грузим асинхронно (вернётся пусто, потом update)
    if (!_cache.containsKey(chatId)) {
      loadMessages(chatId);
      return [];
    }
    return _cache[chatId]!;
  }

  // ── Отправка текста ───────────────────────────────────
  Future<void> sendMessage(String chatId, String text) async {
    if (text.trim().isEmpty) return;
    // Optimistic: показываем своё сообщение сразу
    final tempMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _myId, text: text, time: DateTime.now(), isMe: true);
    _cache.putIfAbsent(chatId, () => []);
    _cache[chatId]!.add(tempMsg);
    update([chatId]);
    try {
      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': _myId,
        'text': text,
      });
    } catch (_) {}
  }

  // ── Отправка фото (base64 в image_url) ────────────────
  Future<void> sendImageMessage(String chatId, String base64) async {
    final tempMsg = Message(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _myId, text: '', imageBase64: base64,
      time: DateTime.now(), isMe: true);
    _cache.putIfAbsent(chatId, () => []);
    _cache[chatId]!.add(tempMsg);
    update([chatId]);
    try {
      await _client.from('messages').insert({
        'chat_id': chatId,
        'sender_id': _myId,
        'text': '',
        'image_url': base64,
      });
    } catch (_) {}
  }

  // ── Имя отправителя ───────────────────────────────────
  String getSenderName(String senderId) {
    if (senderId == _myId) return 'chats_me_prefix'.tr.replaceAll(':', '').trim();
    try {
      final fc = Get.find<FriendsController>();
      final friend = fc.friends.firstWhereOrNull((u) => u.id == senderId);
      return friend?.name ?? '...';
    } catch (_) {
      return '...';
    }
  }

  UserModel? getFriendUser(String friendId) {
    try {
      final fc = Get.find<FriendsController>();
      return fc.friends.firstWhereOrNull((u) => u.id == friendId);
    } catch (_) {
      return null;
    }
  }
}
