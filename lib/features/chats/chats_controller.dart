import 'package:get/get.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/mock_data.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_controller.dart';

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
    if (moodChats.map((m) => m.value).contains(chatId)) {
      _addAutoReply(chatId);
    }
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

  void _addAutoReply(String chatId) {
    final replies = ['Привет! 👋', 'Тоже здесь!', '😊', 'Всем привет!', '🎉'];
    final mood = Mood.values.firstWhere(
      (m) => m.value == chatId, orElse: () => Mood.coffee);
    final users = MockData.nearbyUsers.where((u) => u.mood == mood).toList();
    if (users.isEmpty) return;
    Future.delayed(const Duration(milliseconds: 1200), () async {
      final user = users[DateTime.now().millisecond % users.length];
      final reply = replies[DateTime.now().millisecond % replies.length];
      final msg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: user.id,
        text: reply,
        time: DateTime.now(),
        isMe: false,
      );
      await LocalStorageService.addMessage(chatId, msg.toJson());
      update([chatId]);
    });
  }

  String getSenderName(String senderId) {
    if (senderId == 'me') return 'Вы';
    return MockData.getUserById(senderId).name;
  }

  UserModel? getFriendUser(String friendId) {
    return MockData.getUserById(friendId);
  }
}
