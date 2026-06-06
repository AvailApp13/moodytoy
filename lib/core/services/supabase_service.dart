import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const _url = 'https://aqvbzbjjzymvrttodbnk.supabase.co';
  static const _anonKey = 'sb_publishable_jgeL90LU-6JY3FFARF55qQ_TwIEklfG';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(url: _url, anonKey: _anonKey);
    } catch (_) {
      // Продолжаем без Supabase если нет подключения
    }
  }

  static bool get isConnected {
    try {
      return Supabase.instance.client.auth.currentSession != null
          || true; // доступен даже без сессии
    } catch (_) {
      return false;
    }
  }
}
