import 'package:get/get.dart';
import '../../data/models/user_model.dart';

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chat_id': chatId,
        'sender_id': senderId,
        'text': text,
        'created_at': createdAt.toIso8601String(),
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

class ChatRoom {
  final String id;
  final String name;
  final Mood? mood; // Для общих чатов
  final UserModel? otherUser; // Для личных чатов
  final List<ChatMessage> lastMessages;
  final bool isGeneral; // true = общий чат, false = личный

  ChatRoom({
    required this.id,
    required this.name,
    this.mood,
    this.otherUser,
    this.lastMessages = const [],
    required this.isGeneral,
  });

  String get displayName => otherUser?.name ?? name;
  String? get displayAvatar => otherUser?.mainPhoto;
}

class ChatsController extends GetxController {
  final generalChats = <ChatRoom>[].obs;
  final personalChats = <ChatRoom>[].obs;
  final messages = <String, List<ChatMessage>>{}.obs; // chatId -> messages
  final currentMood = Rxn<Mood>();
  final activeGeneralChatId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initGeneralChats();
    _loadPersonalChats();
  }

  void _initGeneralChats() {
    generalChats.value = [
      ChatRoom(
        id: 'coffee_break',
        name: 'Кофе-брейк',
        mood: Mood.coffeeBreak,
        isGeneral: true,
      ),
      ChatRoom(
        id: 'gamer',
        name: 'Игрок',
        mood: Mood.gamer,
        isGeneral: true,
      ),
      ChatRoom(
        id: 'dating',
        name: 'Знакомство',
        mood: Mood.dating,
        isGeneral: true,
      ),
      ChatRoom(
        id: 'walk',
        name: 'Прогулка',
        mood: Mood.walk,
        isGeneral: true,
      ),
      ChatRoom(
        id: 'sport',
        name: 'Спорт/активность',
        mood: Mood.sport,
        isGeneral: true,
      ),
    ];

    // Установить активный чат по умолчанию
    activeGeneralChatId.value = 'coffee_break';
    currentMood.value = Mood.coffeeBreak;
  }

  void _loadPersonalChats() {
    // Заглушка - личные чаты создаются при принятии запроса в друзья
    personalChats.value = [];
  }

  void addPersonalChat(UserModel user) {
    final existingChat = personalChats.firstWhere(
      (c) => c.otherUser?.id == user.id,
      orElse: () => ChatRoom(id: '', name: '', isGeneral: false),
    );

    if (existingChat.id.isEmpty) {
      personalChats.add(ChatRoom(
        id: 'personal_${user.id}',
        name: user.name,
        otherUser: user,
        isGeneral: false,
      ));
    }
  }

  void setMoodAndSwitchChat(Mood mood) {
    currentMood.value = mood;
    final chatId = _moodToChatId(mood);
    activeGeneralChatId.value = chatId;
  }

  String _moodToChatId(Mood mood) {
    switch (mood) {
      case Mood.coffeeBreak: return 'coffee_break';
      case Mood.gamer: return 'gamer';
      case Mood.dating: return 'dating';
      case Mood.walk: return 'walk';
      case Mood.sport: return 'sport';
    }
  }

  Mood? _chatIdToMood(String chatId) {
    switch (chatId) {
      case 'coffee_break': return Mood.coffeeBreak;
      case 'gamer': return Mood.gamer;
      case 'dating': return Mood.dating;
      case 'walk': return Mood.walk;
      case 'sport': return Mood.sport;
      default: return null;
    }
  }

  void sendMessage(String chatId, String text) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'current_user', // заглушка
      text: text,
      createdAt: DateTime.now(),
    );

    if (!messages.containsKey(chatId)) {
      messages[chatId] = [];
    }
    messages[chatId]!.add(message);
  }

  List<ChatMessage> getMessages(String chatId) {
    return messages[chatId] ?? [];
  }

  ChatRoom? getGeneralChatByMood(Mood mood) {
    final chatId = _moodToChatId(mood);
    return generalChats.firstWhere((c) => c.id == chatId);
  }
}
