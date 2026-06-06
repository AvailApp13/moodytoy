import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_storage_service.dart';
import '../models/user_model.dart';

class SupabaseRepository {
  static SupabaseClient get _client => SupabaseService.client;

  // ── Авто-создание тестового пользователя ──────────────
  static Future<UserModel> getOrCreateTestUser() async {
    try {
      final deviceId = LocalStorageService.prefs.getString('device_id') ??
          DateTime.now().millisecondsSinceEpoch.toString();
      await LocalStorageService.prefs.setString('device_id', deviceId);

      // Ищем существующего пользователя по device_id
      final existing = await _client
          .from('users')
          .select()
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existing != null) {
        return UserModel.fromJson(existing);
      }

      // Создаём нового
      final newUser = {
        'name': 'Гость',
        'avatar_emoji': '😊',
        'mood': 'coffee',
        'location_enabled': true,
        'device_id': deviceId,
        'city': '',
        'bio': '',
      };

      final result = await _client.from('users').insert(newUser).select().single();
      return UserModel.fromJson(result);
    } catch (e) {
      // Fallback — локальный пользователь
      return UserModel(id: 'local_user', name: 'Гость', avatarEmoji: '😊', mood: Mood.coffee);
    }
  }

  // ── Обновление профиля ────────────────────────────────
  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _client.from('users').update(data).eq('id', userId);
    } catch (_) {}
  }

  // ── Получение всех пользователей (для списка людей) ───
  static Future<List<UserModel>> getNearbyUsers(String currentUserId) async {
    try {
      final result = await _client
          .from('users')
          .select()
          .neq('id', currentUserId)
          .order('last_seen_at', ascending: false)
          .limit(20);

      return (result as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Друзья: отправить запрос ──────────────────────────
  static Future<bool> sendFriendRequest(String requesterId, String receiverId) async {
    try {
      await _client.from('friendships').insert({
        'requester_id': requesterId,
        'receiver_id': receiverId,
        'status': 'pending',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Друзья: принять запрос ────────────────────────────
  static Future<bool> acceptFriendRequest(String friendshipId) async {
    try {
      await _client.from('friendships')
          .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', friendshipId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Друзья: отклонить запрос ──────────────────────────
  static Future<bool> declineFriendRequest(String friendshipId) async {
    try {
      await _client.from('friendships')
          .update({'status': 'declined', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', friendshipId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Друзья: получить список друзей ────────────────────
  static Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    try {
      final result = await _client
          .from('friendships')
          .select('*, requester:users!requester_id(*), receiver:users!receiver_id(*)')
          .or('requester_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', 'accepted');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  // ── Друзья: получить входящие запросы ─────────────────
  static Future<List<Map<String, dynamic>>> getIncomingRequests(String userId) async {
    try {
      final result = await _client
          .from('friendships')
          .select('*, requester:users!requester_id(*)')
          .eq('receiver_id', userId)
          .eq('status', 'pending');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }

  // ── Друзья: получить исходящие запросы ────────────────
  static Future<List<String>> getOutgoingRequestIds(String userId) async {
    try {
      final result = await _client
          .from('friendships')
          .select('receiver_id')
          .eq('requester_id', userId)
          .eq('status', 'pending');
      return (result as List).map((e) => e['receiver_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Друзья: проверить статус ──────────────────────────
  static Future<String> getFriendStatus(String userId, String otherUserId) async {
    try {
      final result = await _client
          .from('friendships')
          .select()
          .or('and(requester_id.eq.$userId,receiver_id.eq.$otherUserId),and(requester_id.eq.$otherUserId,receiver_id.eq.$userId)')
          .maybeSingle();

      if (result == null) return 'none';
      final status = result['status'] as String;
      if (status == 'accepted') return 'friend';
      if (status == 'pending') {
        return result['requester_id'] == userId ? 'outgoing' : 'incoming';
      }
      return 'none';
    } catch (_) {
      return 'none';
    }
  }

  // ── Игрушки: добавить тестовую ────────────────────────
  static Future<void> addTestToy(String userId) async {
    try {
      final toys = ['Котик Мяу', 'Лягушонок', 'Лисичка Фокси', 'Панда Бяо'];
      final emojis = ['🐱', '🐸', '🦊', '🐼'];
      final count = await _client.from('user_toys').select('id').eq('user_id', userId);
      final idx = (count as List).length % toys.length;

      await _client.from('user_toys').insert({
        'user_id': userId,
        'name': toys[idx],
        'emoji': emojis[idx],
        'series': 'Серия ${idx + 1}',
        'serial_number': '#${(1000 + (count as List).length).toString().padLeft(4, '0')}',
      });
    } catch (_) {}
  }

  // ── Игрушки: получить список ──────────────────────────
  static Future<List<Map<String, dynamic>>> getUserToys(String userId) async {
    try {
      final result = await _client
          .from('user_toys')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      return [];
    }
  }
}
