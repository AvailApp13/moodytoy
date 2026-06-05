import 'package:get/get.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/mock_data.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_controller.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime time;
  final bool isMe;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.time,
    required this.isMe,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'time': time.toIso8601String(),
    'isMe': isMe,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] ?? '',
    senderId: json['senderId'] ?? '',
    text: json['text'] ?? '',
    time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
    isMe: json['isMe'] ?? false,
  );
}

class ChatsController extends GetxController {
  // Общие чаты по настроениям
  static const List<Mood> moodChats = [
    Mood.coffee, Mood.gamer, Mood.dating, Mood.walk, Mood.sport,
  ];

  // Личные чаты (с друзьями)
  final personalChats = <String>[].obs; // friend ids

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

    // Добавляем авто-ответ в общих чатах через 1 сек
    if (moodChats.map((m) => m.value).contains(chatId)) {
      _addAutoReply(chatId);
    }
    update([chatId]);
  }

  void _addAutoReply(String chatId) {
    final replies = [
      'Привет! 👋', 'Тоже здесь!', 'Отличное настроение 😊',
      'Кто ещё тут?', 'Всем привет!', '🎉', 'Ого, нас уже много!',
    ];
    final mood = Mood.values.firstWhere(
      (m) => m.value == chatId, orElse: () => Mood.coffee,
    );
    final users = MockData.nearbyUsers
        .where((u) => u.mood == mood)
        .toList();
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
