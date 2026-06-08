import 'dart:async';
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
  Timer? _heartbeat;

  @override
  void onInit() {
    super.onInit();
    _checkSession();
    // Heartbeat: обновляем last_seen_at каждую минуту
    _heartbeat = Timer.periodic(const Duration(seconds: 60), (_) => _ping());
  }

  @override
  void onClose() {
    _heartbeat?.cancel();
    super.onClose();
  }

  Future<void> _ping() async {
    final u = currentUser.value;
    if (u == null || !isSupabaseUser.value) return;
    try {
      await SupabaseService.client.from('users')
          .update({'last_seen_at': DateTime.now().toIso8601String()})
          .eq('id', u.id);
    } catch (_) {}
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
  // Возвращает: null = доступен, иначе текст ошибки
  Future<String?> checkUserId(String userIdLogin) async {
    try {
      final existing = await SupabaseService.client
          .from('users')
          .select('id')
          .eq('user_id', userIdLogin)
          .maybeSingle();
      return existing == null ? null : 'auth_error_userid_taken'.tr;
    } catch (e) {
      // Если колонка user_id отсутствует — Supabase вернёт ошибку
      final msg = e.toString().toLowerCase();
      if (msg.contains('user_id') || msg.contains('column') || msg.contains('does not exist')) {
        return 'База не настроена: выполните SQL (колонка user_id). $e';
      }
      return null; // прочие ошибки — считаем доступным
    }
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String userIdLogin,
  }) async {
    try {
      // Шаг 1: проверка уникальности User ID (и наличия колонки)
      final idError = await checkUserId(userIdLogin);
      if (idError != null) return idError;

      // Шаг 2: создаём auth-пользователя
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user == null) return '1: auth.signUp вернул null';
      final authId = response.user!.id;

      // Шаг 3: устанавливаем сессию (нужна для RLS)
      if (SupabaseService.client.auth.currentSession == null) {
        try {
          await SupabaseService.client.auth.signInWithPassword(
            email: email, password: password);
        } catch (e) {
          return '2: нет сессии (вкл. Confirm email?): $e';
        }
      }

      // Шаг 4: сохраняем профиль с user_id
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
        return '3: upsert не прошёл: $e';
      }

      // Шаг 5: проверяем что строка реально создалась
      final check = await SupabaseService.client
          .from('users').select('user_id').eq('id', authId).maybeSingle();
      if (check == null) {
        return '4: строка не создалась (RLS блокирует INSERT?)';
      }

      // Шаг 6: загружаем профиль
      await _loadUserProfile(authId);
      if (currentUser.value == null) {
        return '5: профиль не загрузился';
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
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
        _ping();
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
