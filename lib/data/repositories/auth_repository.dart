import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';

class AuthRepository {
  static final _client = SupabaseService.client;

  /// Войти или зарегистрироваться (упрощённо для MVP)
  static Future<AuthResponse> loginOrRegister({
    required String email,
    required String password,
  }) async {
    try {
      // Пробуем войти
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      // Если аккаунта нет — создаём
      if (e.statusCode == '400' || e.message.contains('Invalid login')) {
        return await _signUp(email: email, password: password);
      }
      rethrow;
    }
  }

  static Future<AuthResponse> _signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': email.split('@').first},
    );

    if (response.user != null) {
      // Создать запись в таблице users
      await _client.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': email.split('@').first,
        'face_verified': true, // mock для MVP
        'location_enabled': false,
        'profile_private': false,
        'tags': [],
        'photos': [],
      }).onConflict('id').ignore();
    }

    return response;
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
