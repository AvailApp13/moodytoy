import '../models/user_model.dart';
import '../../core/services/supabase_service.dart';

class UserRepository {
  static final _client = SupabaseService.client;
  static const _table = 'users';

  // ── Получить свой профиль ─────────────────────────────────

  static Future<UserModel?> getMe() async {
    final id = SupabaseService.currentUserId;
    if (id == null) return null;

    final data = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();

    return data != null ? UserModel.fromJson(data) : null;
  }

  // ── Обновить профиль ──────────────────────────────────────

  static Future<void> updateProfile(Map<String, dynamic> fields) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;

    await _client
        .from(_table)
        .update({...fields, 'last_seen_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // ── Обновить геопозицию ───────────────────────────────────

  static Future<void> updateLocation(double lat, double lng) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;

    await _client.from(_table).update({
      'lat': lat,
      'lng': lng,
      'location_updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ── Обновить настроение ───────────────────────────────────

  static Future<void> updateMood(Mood mood) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;

    await _client
        .from(_table)
        .update({'mood': mood.value})
        .eq('id', id);
  }

  // ── Вкл/выкл видимость на карте ──────────────────────────

  static Future<void> toggleLocation(bool enabled) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;

    await _client
        .from(_table)
        .update({'location_enabled': enabled})
        .eq('id', id);
  }

  // ── Привязать MAC брелока ─────────────────────────────────

  static Future<void> saveKeyfobMac(String mac) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;

    await _client
        .from(_table)
        .update({'keyfob_mac': mac})
        .eq('id', id);
  }

  // ── Отвязать брелок ───────────────────────────────────────

  static Future<void> removeKeyfobMac() async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;

    await _client
        .from(_table)
        .update({'keyfob_mac': null})
        .eq('id', id);
  }

  // ── Обновить уровень батареи ──────────────────────────────

  static Future<void> updateBatteryLevel(int level) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;

    await _client
        .from(_table)
        .update({'battery_level': level})
        .eq('id', id);
  }

  // ── Обновить push-токен ───────────────────────────────────

  static Future<void> updatePushToken(String token) async {
    final id = SupabaseService.currentUserId;
    if (id == null) return;

    await _client
        .from(_table)
        .update({'push_token': token})
        .eq('id', id);
  }

  // ── Пользователи рядом ────────────────────────────────────

  static Future<List<UserModel>> getNearbyUsers({
    required double lat,
    required double lng,
    double radiusMeters = 1000,
  }) async {
    final myId = SupabaseService.currentUserId;

    // Запрашиваем пользователей с включённой локацией
    // Фильтрация по расстоянию делается на клиенте (Haversine)
    final data = await _client
        .from(_table)
        .select()
        .eq('location_enabled', true)
        .not('id', 'eq', myId ?? '')
        .not('lat', 'is', null)
        .not('lng', 'is', null)
        .order('location_updated_at', ascending: false)
        .limit(100);

    final users = data.map((json) => UserModel.fromJson(json)).toList();

    // Фильтруем по расстоянию
    return users.where((u) {
      if (u.lat == null || u.lng == null) return false;
      final dist = _haversineDistance(lat, lng, u.lat!, u.lng!);
      u.distanceMeters = dist;
      return dist <= radiusMeters;
    }).toList()
      ..sort((a, b) =>
          (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
  }

  // ── Профиль другого пользователя ─────────────────────────

  static Future<UserModel?> getUserById(String userId) async {
    final data = await _client
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();

    return data != null ? UserModel.fromJson(data) : null;
  }

  // ── Формула Хаверсина (расстояние в метрах) ───────────────

  static double _haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // радиус Земли в метрах
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = _sin2(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sin2(dLng / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * 3.14159265358979 / 180;
  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => _mathSin(x);
  static double _cos(double x) => _mathCos(x);
  static double _sqrt(double x) => _mathSqrt(x);
  static double _atan2(double y, double x) => _mathAtan2(y, x);

  static double _mathSin(double x) {
    // dart:math sin
    return x - x * x * x / 6 + x * x * x * x * x / 120;
  }

  static double _mathCos(double x) {
    return 1 - x * x / 2 + x * x * x * x / 24;
  }

  static double _mathSqrt(double x) {
    if (x <= 0) return 0;
    double z = x;
    for (int i = 0; i < 10; i++) {
      z = (z + x / z) / 2;
    }
    return z;
  }

  static double _mathAtan2(double y, double x) {
    // simplified atan2
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265358979;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265358979;
    if (x == 0 && y > 0) return 3.14159265358979 / 2;
    if (x == 0 && y < 0) return -3.14159265358979 / 2;
    return 0;
  }

  static double _atan(double x) {
    return x - x * x * x / 3 + x * x * x * x * x / 5;
  }
}
