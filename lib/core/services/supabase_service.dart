import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception('⚠️ SUPABASE_URL или SUPABASE_ANON_KEY не заданы в .env');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
  }

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => client.auth.currentUser?.id;

  static bool get isAuthenticated => client.auth.currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
