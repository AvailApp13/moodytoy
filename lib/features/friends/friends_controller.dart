import 'package:get/get.dart';
import '../../data/models/friendship_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/friends_repository.dart';

class FriendsController extends GetxController {
  final friends = <UserModel>[].obs;
  final incomingRequests = <FriendshipModel>[].obs;
  final isLoading = false.obs;

  // Кэш статусов для карточек на карте/списке
  final _statusCache = <String, FriendshipStatus?>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    await Future.wait([loadFriends(), loadRequests()]);
    isLoading.value = false;
  }

  Future<void> loadFriends() async {
    friends.value = await FriendsRepository.getFriends();
  }

  Future<void> loadRequests() async {
    incomingRequests.value = await FriendsRepository.getIncomingRequests();
  }

  Future<void> sendRequest(String userId) async {
    await FriendsRepository.sendRequest(userId);
    _statusCache[userId] = FriendshipStatus.pending;
    await loadRequests();
  }

  Future<void> acceptRequest(String friendshipId, String requesterId) async {
    await FriendsRepository.acceptRequest(friendshipId);
    _statusCache[requesterId] = FriendshipStatus.accepted;
    await loadAll();
  }

  Future<void> declineRequest(String friendshipId) async {
    await FriendsRepository.declineRequest(friendshipId);
    await loadRequests();
  }

  FriendshipStatus? getFriendStatusWith(String userId) {
    return _statusCache[userId];
  }
}
