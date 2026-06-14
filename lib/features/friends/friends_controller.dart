import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/supabase_repository.dart';
import '../auth/auth_controller.dart';

enum FriendStatus { none, outgoing, incoming, friend }

class FriendsController extends GetxController {
  final friends = <UserModel>[].obs;
  final incomingRequests = <UserModel>[].obs;
  final outgoingRequestIds = <String>[].obs;
  final _incomingRequestIds = <String, String>{}; // friendshipId → requesterId

  // Фильтр поиска среди существующих друзей
  String friendsFilter = '';
  void setFriendsFilter(String q) {
    friendsFilter = q;
    update();
  }
  List<UserModel> get filteredFriends {
    final q = friendsFilter.trim().toLowerCase();
    if (q.isEmpty) return friends.toList();
    return friends.where((u) => u.name.toLowerCase().contains(q)).toList();
  }

  RealtimeChannel? _channel;
  Timer? _pollTimer;

  String get _myId => Get.find<AuthController>().currentUser.value?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    loadAll();
    _subscribeRealtime();
    // Fallback-опрос раз в 15 сек (на случай если Realtime не сработал)
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => loadAll());
  }

  @override
  void onClose() {
    _channel?.unsubscribe();
    _pollTimer?.cancel();
    super.onClose();
  }

  // ── Realtime: реагируем на изменения в friendships ────
  void _subscribeRealtime() {
    try {
      _channel = SupabaseService.client
          .channel('public:friendships')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'friendships',
            callback: (payload) {
              // Любое изменение дружбы — перезагружаем списки
              loadAll();
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> loadAll() async {
    final auth = Get.find<AuthController>();
    final userId = auth.currentUser.value?.id ?? '';

    if (auth.isSupabaseUser.value && userId.isNotEmpty) {
      await _loadFromSupabase(userId);
    } else {
      _loadFromLocal();
    }
    update();
  }

  Future<void> _loadFromSupabase(String userId) async {
    try {
      // Друзья (репозиторий теперь возвращает профили друзей напрямую)
      final friendsData = await SupabaseRepository.getFriends(userId);
      friends.value =
          friendsData.map((u) => UserModel.fromJson(u)).toList();

      // Входящие запросы
      final requestsData = await SupabaseRepository.getIncomingRequests(userId);
      _incomingRequestIds.clear();
      incomingRequests.value = requestsData.map((r) {
        _incomingRequestIds[r['id']] = r['requester_id'];
        return UserModel.fromJson(r['requester']);
      }).toList();

      // Исходящие (чтобы кнопка показывала "Запрос отправлен")
      outgoingRequestIds.value =
          await SupabaseRepository.getOutgoingRequestIds(userId);
    } catch (_) {
      _loadFromLocal();
    }
  }

  void _loadFromLocal() {
    friends.value = [];
    incomingRequests.value = [];
    outgoingRequestIds.value = [];
  }

  int get incomingCount => incomingRequests.length;

  FriendStatus getStatus(String userId) {
    if (friends.any((u) => u.id == userId)) return FriendStatus.friend;
    if (incomingRequests.any((u) => u.id == userId)) return FriendStatus.incoming;
    if (outgoingRequestIds.contains(userId)) return FriendStatus.outgoing;
    return FriendStatus.none;
  }

  Future<void> sendRequest(String targetUserId) async {
    final auth = Get.find<AuthController>();
    if (auth.isSupabaseUser.value) {
      await SupabaseRepository.sendFriendRequest(_myId, targetUserId);
    }
    await loadAll();
  }

  Future<void> acceptRequest(String userId) async {
    final auth = Get.find<AuthController>();
    if (auth.isSupabaseUser.value) {
      final fId = _incomingRequestIds.entries
          .where((e) => e.value == userId)
          .map((e) => e.key)
          .firstOrNull;
      if (fId != null) await SupabaseRepository.acceptFriendRequest(fId);
    }
    await loadAll();
  }

  Future<void> declineRequest(String userId) async {
    final auth = Get.find<AuthController>();
    if (auth.isSupabaseUser.value) {
      final fId = _incomingRequestIds.entries
          .where((e) => e.value == userId)
          .map((e) => e.key)
          .firstOrNull;
      if (fId != null) await SupabaseRepository.declineFriendRequest(fId);
    }
    await loadAll();
  }

  bool isFriend(String userId) => friends.any((u) => u.id == userId);
}
