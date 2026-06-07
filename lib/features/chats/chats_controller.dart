import 'package:get/get.dart';
import '../../core/services/local_storage_service.dart';
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'imageBase64': imageBase64,
    'time': time.toIso8601String(),
    'isMe': isMe,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] ?? '',
    senderId: json['senderId'] ?? '',
    text: json['text'] ?? '',
    imageBase64: json['imageBase64'],
    time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
    isMe: json['isMe'] ?? false,
  );
}

class ChatsController extends GetxController {
  static const List<Mood> moodChats = [
    Mood.coffee, Mood.gamer, Mood.dating, Mood.walk, Mood.sport,
  ];

  final personalChats = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadPersonalChats();
  }

  void loadPersonalChats() {
    personalChats.value = LocalStorageService.getFriends();
  }

  List<Message> getMessages(String chatId) {
    final raw = LocalStorageService.getMessages(chatId);
    return raw.map((e) => Message.fromJson(e)).toList();
  }

  Future<void> sendMessage(String chatId, String text) async {
    final auth = Get.find<AuthController>();
    final msg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: auth.currentUser.value?.id ?? 'me',
      text: text,
      time: DateTime.now(),
      isMe: true,
    );
    await LocalStorageService.addMessage(chatId, msg.toJson());
    update([chatId]);
  }

  Future<void> sendImageMessage(String chatId, String base64) async {
    final auth = Get.find<AuthController>();
    final msg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: auth.currentUser.value?.id ?? 'me',
      text: '',
      imageBase64: base64,
      time: DateTime.now(),
      isMe: true,
    );
    await LocalStorageService.addMessage(chatId, msg.toJson());
    update([chatId]);
  }

  String getSenderName(String senderId) {
    final auth = Get.find<AuthController>();
    if (senderId == auth.currentUser.value?.id || senderId == 'me') return 'chats_me_prefix'.tr.replaceAll(':', '').trim();
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
