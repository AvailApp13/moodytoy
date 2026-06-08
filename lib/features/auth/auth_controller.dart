import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/supabase_repository.dart';

class AuthController extends GetxController {
  final currentUser = Rxn<UserModel>();
  final isSupabaseUser = false.obs;
  final isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkSession();
  }

  // ── Проверка существующей сессии ──────────────────────
  Future<void> _checkSession() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) {
        await _loadUserProfile(session.user.id);
      }
    } catch (_) {}
  }

  // ── Регистрация ───────────────────────────────────────
  // Проверка уникальности User ID (логина)
  Future<bool> isUserIdAvailable(String userIdLogin) async {
    try {
      final existing = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('user_id', userIdLogin)
          .maybeSingle();
      return existing == null;
    } catch (_) {
      return true;
    }
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String userIdLogin,
  }) async {
    try {
      // Проверка уникальности User ID
      final available = await isUserIdAvailable(userIdLogin);
      if (!available) return 'auth_error_userid_taken'.tr;

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) return 'auth_error_general'.tr;

      final authId = response.user!.id;

      // Если сессии нет — входим (нужна сессия чтобы прошёл RLS на INSERT)
      if (response.session == null) {
        try {
          await SupabaseService.client.auth.signInWithPassword(
            email: email, password: password);
        } catch (_) {
          return 'Подтвердите email или отключите подтверждение в Supabase';
        }
      }

      // Теперь сессия есть — upsert профиля С user_id (insert или update)
      try {
        await SupabaseService.client.from('users').upsert({
          'id': authId,
          'user_id': userIdLogin,
          'name': name,
          'email': email,
          'avatar_emoji': '😊',
          'mood': 'coffee',
          'location_enabled': true,
        });
      } catch (e) {
        return 'Не удалось сохранить профиль: ${e.toString()}';
      }

      await _loadUserProfile(authId);

      if (currentUser.value == null) {
        return 'Не удалось загрузить профиль. Попробуйте войти ещё раз.';
      }
      return null;
    } on AuthException catch (e) {
      return e.message; // показываем точное сообщение от Supabase
    } catch (e) {
      return 'Ошибка: ${e.toString()}';
    }
  }

  // ── Вход ──────────────────────────────────────────────
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) return 'auth_error_invalid'.tr;
      await _loadUserProfile(response.user!.id);
      if (currentUser.value == null) {
        return 'Не удалось загрузить профиль';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Ошибка: ${e.toString()}';
    }
  }

  // ── Выход ─────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
    } catch (_) {}
    currentUser.value = null;
    isLoggedIn.value = false;
    isSupabaseUser.value = false;
    await LocalStorageService.prefs.remove('current_user');
  }

  // ── Загрузка профиля из Supabase ──────────────────────
  Future<void> _loadUserProfile(String userId) async {
    try {
      final authUser = SupabaseService.client.auth.currentUser;
      var data = await SupabaseService.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Если профиля нет — создаём автоматически
      if (data == null && authUser != null) {
        final name = (authUser.userMetadata?['name'] as String?)
            ?? authUser.email?.split('@').first
            ?? 'Гость';
        try {
          await SupabaseService.client.from('users').insert({
            'id': userId,
            'name': name,
            'email': authUser.email,
            'avatar_emoji': '😊',
            'mood': 'coffee',
            'location_enabled': true,
          });
          data = await SupabaseService.client
              .from('users')
              .select()
              .eq('id', userId)
              .maybeSingle();
        } catch (_) {}
      }

      if (data != null) {
        final user = UserModel.fromJson(data);
        currentUser.value = user;
        isLoggedIn.value = true;
        isSupabaseUser.value = true;
        await LocalStorageService.saveCurrentUser(user);
      } else if (authUser != null) {
        // Fallback: создаём локальный профиль из данных auth
        final name = (authUser.userMetadata?['name'] as String?)
            ?? authUser.email?.split('@').first
            ?? 'Гость';
        final user = UserModel(
          id: userId,
          name: name,
          avatarEmoji: '😊',
          mood: Mood.coffee,
        );
        currentUser.value = user;
        isLoggedIn.value = true;
        isSupabaseUser.value = true;
        await LocalStorageService.saveCurrentUser(user);
      }
    } catch (_) {}
  }

  String _translateAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already') || lower.contains('exists')) {
      return 'auth_error_exists'.tr;
    }
    if (lower.contains('invalid') || lower.contains('credentials')) {
      return 'auth_error_invalid'.tr;
    }
    if (lower.contains('email')) return 'auth_error_email'.tr;
    if (lower.contains('password')) return 'auth_error_password'.tr;
    return 'auth_error_general'.tr;
  }

  // ── Обновление профиля ────────────────────────────────
  Future<void> updateUser(UserModel user) async {
    await LocalStorageService.saveCurrentUser(user);
    currentUser.value = user;
    if (isSupabaseUser.value) {
      await SupabaseRepository.updateUser(user.id, {
        'name': user.name,
        'bio': user.bio,
        'city': user.city,
        'avatar_emoji': user.avatarEmoji,
        'avatar_url': user.avatarUrl,
        'mood': user.mood?.value,
        'location_enabled': user.locationEnabled,
        'birth_date': user.birthDate?.toIso8601String(),
      });
    }
  }

  Future<void> updateMood(Mood mood) async {
    final u = currentUser.value;
    if (u == null) return;
    await updateUser(u.copyWith(mood: mood));
  }

  Future<void> toggleLocation(bool v) async {
    final u = currentUser.value;
    if (u == null) return;
    await updateUser(u.copyWith(locationEnabled: v));
  }

  Future<void> updateName(String name) async {
    final u = currentUser.value;
    if (u == null) return;
    await updateUser(u.copyWith(name: name));
  }

  Future<void> updateBio(String bio) async {
    final u = currentUser.value;
    if (u == null) return;
    await updateUser(u.copyWith(bio: bio));
  }

  Future<void> updateCity(String city) async {
    final u = currentUser.value;
    if (u == null) return;
    await updateUser(u.copyWith(city: city));
  }

  Future<void> updateBirthDate(DateTime d) async {
    final u = currentUser.value;
    if (u == null) return;
    await updateUser(u.copyWith(birthDate: d));
  }

  Future<void> addTestToy() async {
    final u = currentUser.value;
    if (u == null) return;
    if (isSupabaseUser.value) {
      await SupabaseRepository.addTestToy(u.id);
    }
  }
}
