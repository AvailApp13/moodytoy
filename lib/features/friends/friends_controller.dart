import 'package:get/get.dart';
import '../../core/services/local_storage_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/supabase_repository.dart';
import '../auth/auth_controller.dart';

enum FriendStatus { none, outgoing, incoming, friend }

class FriendsController extends GetxController {
  final friends = <UserModel>[].obs;
  final incomingRequests = <UserModel>[].obs;
  final _incomingRequestIds = <String, String>{}; // friendshipId → requesterId

  @override
  void onInit() {
    super.onInit();
    loadAll();
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
      // Друзья
      final friendsData = await SupabaseRepository.getFriends(userId);
      friends.value = friendsData.map((f) {
        final isRequester = f['requester_id'] == userId;
        final userData = isRequester ? f['receiver'] : f['requester'];
        return UserModel.fromJson(userData);
      }).toList();

      // Входящие запросы
      final requestsData = await SupabaseRepository.getIncomingRequests(userId);
      _incomingRequestIds.clear();
      incomingRequests.value = requestsData.map((r) {
        _incomingRequestIds[r['id']] = r['requester_id'];
        return UserModel.fromJson(r['requester']);
      }).toList();
    } catch (_) {
      _loadFromLocal();
    }
  }

  void _loadFromLocal() {
    // Без Supabase — пустые списки (никаких моков)
    friends.value = [];
    incomingRequests.value = [];
  }

  FriendStatus getStatus(String userId) {
    if (friends.any((u) => u.id == userId)) return FriendStatus.friend;
    if (incomingRequests.any((u) => u.id == userId)) return FriendStatus.incoming;
    if (LocalStorageService.getOutgoingRequests().contains(userId)) return FriendStatus.outgoing;
    if (LocalStorageService.getFriends().contains(userId)) return FriendStatus.friend;
    return FriendStatus.none;
  }

  Future<void> sendRequest(String targetUserId) async {
    final auth = Get.find<AuthController>();
    if (auth.isSupabaseUser.value) {
      await SupabaseRepository.sendFriendRequest(auth.currentUser.value!.id, targetUserId);
    }
    await LocalStorageService.addOutgoingRequest(targetUserId);
    await loadAll();
  }

  Future<void> acceptRequest(String userId) async {
    final auth = Get.find<AuthController>();

    if (auth.isSupabaseUser.value) {
      // Ищем friendshipId
      final fId = _incomingRequestIds.entries
          .where((e) => e.value == userId)
          .map((e) => e.key)
          .firstOrNull;
      if (fId != null) await SupabaseRepository.acceptFriendRequest(fId);
    }

    await LocalStorageService.removeIncomingRequest(userId);
    await LocalStorageService.addFriend(userId);
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

    await LocalStorageService.removeIncomingRequest(userId);
    await loadAll();
  }

  bool isFriend(String userId) => friends.any((u) => u.id == userId);
}
