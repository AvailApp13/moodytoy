import '../models/friendship_model.dart';
import '../models/user_model.dart';
import '../../core/services/supabase_service.dart';

class FriendsRepository {
  static final _client = SupabaseService.client;
  static const _table = 'friendships';

  // ── Отправить запрос в друзья ─────────────────────────────

  static Future<FriendshipModel> sendRequest(String receiverId) async {
    final myId = SupabaseService.currentUserId!;

    final data = await _client.from(_table).insert({
      'requester_id': myId,
      'receiver_id': receiverId,
      'status': 'pending',
    }).select().single();

    return FriendshipModel.fromJson(data);
  }

  // ── Принять запрос ────────────────────────────────────────

  static Future<void> acceptRequest(String friendshipId) async {
    await _client
        .from(_table)
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', friendshipId);
  }

  // ── Отклонить запрос ──────────────────────────────────────

  static Future<void> declineRequest(String friendshipId) async {
    await _client
        .from(_table)
        .update({'status': 'declined', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', friendshipId);
  }

  // ── Список друзей ─────────────────────────────────────────

  static Future<List<UserModel>> getFriends() async {
    final myId = SupabaseService.currentUserId!;

    // Запросы где я requester и приняты
    final sent = await _client
        .from(_table)
        .select('receiver_id, users!receiver_id(*)')
        .eq('requester_id', myId)
        .eq('status', 'accepted');

    // Запросы где я receiver и приняты
    final received = await _client
        .from(_table)
        .select('requester_id, users!requester_id(*)')
        .eq('receiver_id', myId)
        .eq('status', 'accepted');

    final friends = <UserModel>[];

    for (final item in sent) {
      final userData = item['users'];
      if (userData != null) {
        friends.add(UserModel.fromJson(userData as Map<String, dynamic>));
      }
    }

    for (final item in received) {
      final userData = item['users'];
      if (userData != null) {
        friends.add(UserModel.fromJson(userData as Map<String, dynamic>));
      }
    }

    return friends;
  }

  // ── Входящие запросы ──────────────────────────────────────

  static Future<List<FriendshipModel>> getIncomingRequests() async {
    final myId = SupabaseService.currentUserId!;

    final data = await _client
        .from(_table)
        .select('*, users!requester_id(*)')
        .eq('receiver_id', myId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return data.map((json) {
      // Rename joined user
      final map = Map<String, dynamic>.from(json);
      if (map['users'] != null) {
        map['requester'] = map.remove('users');
      }
      return FriendshipModel.fromJson(map);
    }).toList();
  }

  // ── Статус дружбы с пользователем ─────────────────────────

  static Future<FriendshipStatus?> getStatusWith(String userId) async {
    final myId = SupabaseService.currentUserId!;

    final data = await _client
        .from(_table)
        .select('status')
        .or('and(requester_id.eq.$myId,receiver_id.eq.$userId),'
            'and(requester_id.eq.$userId,receiver_id.eq.$myId)')
        .maybeSingle();

    if (data == null) return null;
    return FriendshipStatusExtension.fromString(data['status'] as String?);
  }

  // ── Удалить из друзей ─────────────────────────────────────

  static Future<void> removeFriend(String friendshipId) async {
    await _client.from(_table).delete().eq('id', friendshipId);
  }
}
