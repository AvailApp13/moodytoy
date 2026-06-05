import 'package:get/get.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/mock_data.dart';
import '../../data/models/user_model.dart';

enum FriendStatus { none, outgoing, incoming, friend }

class FriendsController extends GetxController {
  final friends = <UserModel>[].obs;
  final incomingRequests = <UserModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
    // Добавляем мок входящие запросы для теста
    _addMockRequests();
  }

  void _addMockRequests() {
    final existing = LocalStorageService.getIncomingRequests();
    if (existing.isEmpty) {
      LocalStorageService.addIncomingRequest('user_7'); // Максим
      LocalStorageService.addIncomingRequest('user_8'); // Ольга
      loadAll();
    }
  }

  void loadAll() {
    final friendIds = LocalStorageService.getFriends();
    friends.value = friendIds.map((id) => MockData.getUserById(id)).toList();

    final requestIds = LocalStorageService.getIncomingRequests();
    incomingRequests.value = requestIds.map((id) => MockData.getUserById(id)).toList();
  }

  FriendStatus getStatus(String userId) {
    if (LocalStorageService.getFriends().contains(userId)) return FriendStatus.friend;
    if (LocalStorageService.getIncomingRequests().contains(userId)) return FriendStatus.incoming;
    if (LocalStorageService.getOutgoingRequests().contains(userId)) return FriendStatus.outgoing;
    return FriendStatus.none;
  }

  Future<void> sendRequest(String userId) async {
    await LocalStorageService.addOutgoingRequest(userId);
    loadAll();
    update();
  }

  Future<void> acceptRequest(String userId) async {
    await LocalStorageService.removeIncomingRequest(userId);
    await LocalStorageService.addFriend(userId);
    loadAll();
    update();
  }

  Future<void> declineRequest(String userId) async {
    await LocalStorageService.removeIncomingRequest(userId);
    loadAll();
    update();
  }

  bool isFriend(String userId) {
    return LocalStorageService.getFriends().contains(userId);
  }
}
