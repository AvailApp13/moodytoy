import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class AuthRepository {
  static final _client = SupabaseService.client;

  static Future<AuthResponse> loginOrRegister({
    required String email,
    required String password,
  }) async {
    try {
      return await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
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
    );
    if (response.user != null) {
      await _client.from('users').insert({
        'id': response.user!.id,
        'email': email,
        'name': email.split('@').first,
        'face_verified': true,
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
}
