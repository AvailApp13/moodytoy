import 'dart:math' as math;
import '../models/user_model.dart';
import '../../core/services/supabase_service.dart';

class UserRepository {
  static final _client = SupabaseService.client;
  static const _table = 'users';

  static Future<UserModel?> getMe() async {
    final id = SupabaseService.currentUserId;
    if (id == null) return null;
    final data = await _client.from(_table).select().eq('id', id).maybeSingle();
    return data != null ? UserModel.fromJson(data) : null;
  }

  static Future<void> updateProfile(Map<String, dynamic> fields) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;
    await _client.from(_table).update(fields).eq('id', id);
  }

  static Future<void> updateLocation(double lat, double lng) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;
    await _client.from(_table).update({
      'lat': lat,
      'lng': lng,
      'location_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  static Future<void> updateMood(Mood mood) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;
    await _client.from(_table).update({'mood': mood.value}).eq('id', id);
  }

  static Future<void> toggleLocation(bool enabled) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;
    await _client.from(_table).update({'location_enabled': enabled}).eq('id', id);
  }

  static Future<void> saveKeyfobMac(String mac) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;
    await _client.from(_table).update({'keyfob_mac': mac}).eq('id', id);
  }

  static Future<void> removeKeyfobMac() async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;
    await _client.from(_table).update({'keyfob_mac': null}).eq('id', id);
  }

  static Future<void> updateBatteryLevel(int level) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;
    await _client.from(_table).update({'battery_level': level}).eq('id', id);
  }

  static Future<void> updatePushToken(String token) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;
    await _client.from(_table).update({'push_token': token}).eq('id', id);
  }

  static Future<List<UserModel>> getNearbyUsers({
    required double lat,
    required double lng,
    double radiusMeters = 1000,
  }) async {
    final myId = SupabaseService.currentUserId;
    final data = await _client
        .from(_table)
        .select()
        .eq('location_enabled', true)
        .neq('id', myId ?? '')
        .limit(100);

    final users = (data as List).map((json) => UserModel.fromJson(json)).toList();
    return users.where((u) {
      if (u.lat == null || u.lng == null) return false;
      final dist = _haversineDistance(lat, lng, u.lat!, u.lng!);
      u.distanceMeters = dist;
      return dist <= radiusMeters;
    }).toList()
      ..sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
  }

  static Future<UserModel?> getUserById(String userId) async {
    final data = await _client.from(_table).select().eq('id', userId).maybeSingle();
    return data != null ? UserModel.fromJson(data) : null;
  }

  static double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
        math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
