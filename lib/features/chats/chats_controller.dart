import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_controller.dart';
import '../friends/friends_controller.dart';
import '../../data/repositories/supabase_repository.dart';

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
  // Кэш профилей отправителей (для имён незнакомцев в общих чатах)
  final Map<String, UserModel> _profileCache = {};
  // Счётчики "в сети" по настроению (общие чаты)
  final moodOnline = <String, int>{}.obs;
  // Время последнего прочтения чата (chatId → timestamp) для непрочитанных
  final Map<String, DateTime> _lastRead = {};
  RealtimeChannel? _channel;

  SupabaseClient get _client => SupabaseService.client;
  String get _myId => Get.find<AuthController>().currentUser.value?.id ?? '';

  // Единый chat_id для личного чата (одинаковый для обоих участников)
  String personalChatId(String otherUserId) {
    final ids = [_myId, otherUserId]..sort();
    return 'personal_${ids.join('_')}';
  }

  // ── Непрочитанные ─────────────────────────────────────
  Future<void> _loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (key.startsWith('lastread_')) {
        final chatId = key.substring('lastread_'.length);
        final ts = prefs.getString(key);
        if (ts != null) {
          final dt = DateTime.tryParse(ts);
          if (dt != null) _lastRead[chatId] = dt;
        }
      }
    }
    update();
  }

  Future<void> markRead(String chatId) async {
    final now = DateTime.now();
    _lastRead[chatId] = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastread_$chatId', now.toIso8601String());
    update();
  }

  // Есть ли непрочитанные в чате (последнее сообщение не от меня и позже прочтения)
  bool hasUnread(String chatId) {
    final msgs = _cache[chatId];
    if (msgs == null || msgs.isEmpty) return false;
    final last = msgs.last;
    if (last.isMe) return false;
    final read = _lastRead[chatId];
    if (read == null) return true;
    return last.time.isAfter(read);
  }

  // Сколько чатов с непрочитанными (для бейджа на вкладке)
  int get unreadChatsCount {
    int n = 0;
    for (final mood in moodChats) {
      if (hasUnread(mood.value)) n++;
    }
    for (final fid in personalChats) {
      if (hasUnread(personalChatId(fid))) n++;
    }
    return n;
  }

  // ── Счётчики онлайн по настроению (общие чаты) ────────
  Future<void> refreshMoodOnline() async {
    for (final mood in moodChats) {
      moodOnline[mood.value] =
          await SupabaseRepository.countOnlineByMood(mood.value);
    }
    moodOnline.refresh();
  }

  @override
  void onInit() {
    super.onInit();
    loadPersonalChats();
    _subscribeRealtime();
    _loadLastRead();
    refreshMoodOnline();
    // Обновляем счётчики онлайн раз в 30 сек
    _onlineTimer = Timer.periodic(
        const Duration(seconds: 30), (_) => refreshMoodOnline());
  }

  Timer? _onlineTimer;

  @override
  void onClose() {
    _channel?.unsubscribe();
    _onlineTimer?.cancel();
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
                update(); // обновить бейдж непрочитанных на вкладке
                // Подгрузить имя отправителя если незнакомец
                if (!msg.isMe && !_profileCache.containsKey(msg.senderId)) {
                  SupabaseRepository.getUserById(msg.senderId).then((u) {
                    if (u != null) {
                      _profileCache[u.id] = u;
                      update([chatId]);
                    }
                  });
                }
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
      _loadSenderProfiles(chatId); // подгрузить имена отправителей
    } catch (_) {
      _cache[chatId] ??= [];
    }
  }

  // Подгружаем профили всех отправителей (для имён незнакомцев в общих чатах)
  Future<void> _loadSenderProfiles(String chatId) async {
    final msgs = _cache[chatId] ?? [];
    final ids = msgs
        .map((m) => m.senderId)
        .where((id) => id != _myId && id != 'me' && !_profileCache.containsKey(id))
        .toSet()
        .toList();
    if (ids.isEmpty) return;
    final users = await SupabaseRepository.getUsersByIds(ids);
    for (final u in users) {
      _profileCache[u.id] = u;
    }
    if (users.isNotEmpty) update([chatId]);
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
    // Сначала друзья, потом кэш профилей (незнакомцы в общих чатах)
    try {
      final fc = Get.find<FriendsController>();
      final friend = fc.friends.firstWhereOrNull((u) => u.id == senderId);
      if (friend != null) return friend.name;
    } catch (_) {}
    final cached = _profileCache[senderId];
    if (cached != null) return cached.name;
    return '...';
  }

  UserModel? getFriendUser(String friendId) {
    try {
      final fc = Get.find<FriendsController>();
      final friend = fc.friends.firstWhereOrNull((u) => u.id == friendId);
      if (friend != null) return friend;
    } catch (_) {}
    return _profileCache[friendId];
  }
}
