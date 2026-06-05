import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null) throw Exception('LocalStorageService not initialized');
    return _prefs!;
  }

  // ── Текущий пользователь ──────────────────────────────────
  static Future<void> saveCurrentUser(UserModel user) async {
    await prefs.setString('current_user', jsonEncode(user.toJson()));
  }

  static UserModel? getCurrentUser() {
    final str = prefs.getString('current_user');
    if (str == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }

  // ── Друзья ────────────────────────────────────────────────
  static Future<void> saveFriends(List<String> friendIds) async {
    await prefs.setStringList('friends', friendIds);
  }

  static List<String> getFriends() {
    return prefs.getStringList('friends') ?? [];
  }

  static Future<void> addFriend(String userId) async {
    final friends = getFriends();
    if (!friends.contains(userId)) {
      friends.add(userId);
      await saveFriends(friends);
    }
  }

  static Future<void> removeFriend(String userId) async {
    final friends = getFriends();
    friends.remove(userId);
    await saveFriends(friends);
  }

  // ── Входящие запросы ──────────────────────────────────────
  static Future<void> saveIncomingRequests(List<String> userIds) async {
    await prefs.setStringList('incoming_requests', userIds);
  }

  static List<String> getIncomingRequests() {
    return prefs.getStringList('incoming_requests') ?? [];
  }

  static Future<void> addIncomingRequest(String userId) async {
    final reqs = getIncomingRequests();
    if (!reqs.contains(userId)) {
      reqs.add(userId);
      await saveIncomingRequests(reqs);
    }
  }

  static Future<void> removeIncomingRequest(String userId) async {
    final reqs = getIncomingRequests();
    reqs.remove(userId);
    await saveIncomingRequests(reqs);
  }

  // ── Исходящие запросы ─────────────────────────────────────
  static Future<void> saveOutgoingRequests(List<String> userIds) async {
    await prefs.setStringList('outgoing_requests', userIds);
  }

  static List<String> getOutgoingRequests() {
    return prefs.getStringList('outgoing_requests') ?? [];
  }

  static Future<void> addOutgoingRequest(String userId) async {
    final reqs = getOutgoingRequests();
    if (!reqs.contains(userId)) {
      reqs.add(userId);
      await saveOutgoingRequests(reqs);
    }
  }

  static Future<void> removeOutgoingRequest(String userId) async {
    final reqs = getOutgoingRequests();
    reqs.remove(userId);
    await saveOutgoingRequests(reqs);
  }

  // ── Чаты ──────────────────────────────────────────────────
  static Future<void> saveMessages(String chatId, List<Map<String, dynamic>> messages) async {
    await prefs.setString('chat_$chatId', jsonEncode(messages));
  }

  static List<Map<String, dynamic>> getMessages(String chatId) {
    final str = prefs.getString('chat_$chatId');
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addMessage(String chatId, Map<String, dynamic> message) async {
    final messages = getMessages(chatId);
    messages.add(message);
    await saveMessages(chatId, messages);
  }

  // ── Настройки ─────────────────────────────────────────────
  static Future<void> saveShowOnMap(bool value) async {
    await prefs.setBool('show_on_map', value);
  }

  static bool getShowOnMap() {
    return prefs.getBool('show_on_map') ?? true;
  }
}
