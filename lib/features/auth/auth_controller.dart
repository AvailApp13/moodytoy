import 'package:get/get.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_strings.dart';
import '../main_nav/main_nav_screen.dart';
import 'login_screen.dart';

class AuthController extends GetxController {
  // ── Состояние ─────────────────────────────────────────────
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final currentUser = Rxn<UserModel>();

  // Поля формы
  final emailError = ''.obs;
  final passwordError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuth();
  }

  // ── Проверка авторизации при запуске ──────────────────────

  Future<void> _checkAuth() async {
    final user = await UserRepository.getMe();
    if (user != null) {
      currentUser.value = user;
      Get.offAll(() => const MainNavScreen());
    }
  }

  // ── Войти или зарегистрироваться ──────────────────────────

  Future<void> loginOrRegister({
    required String email,
    required String password,
  }) async {
    if (!_validate(email, password)) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await AuthRepository.loginOrRegister(
        email: email,
        password: password,
      );

      // Загрузить профиль
      final user = await UserRepository.getMe();
      currentUser.value = user;

      Get.offAll(() => const MainNavScreen());
    } catch (e) {
      errorMessage.value = _parseError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Выйти ─────────────────────────────────────────────────

  Future<void> logout() async {
    await AuthRepository.logout();
    currentUser.value = null;
    Get.offAll(() => const LoginScreen());
  }

  // ── Валидация ─────────────────────────────────────────────

  bool _validate(String email, String password) {
    bool valid = true;
    emailError.value = '';
    passwordError.value = '';

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      emailError.value = AppStrings.errorInvalidEmail;
      valid = false;
    }

    if (password.length < 8) {
      passwordError.value = AppStrings.errorPasswordShort;
      valid = false;
    }

    return valid;
  }

  String _parseError(String error) {
    if (error.contains('network') || error.contains('connection')) {
      return AppStrings.errorNetwork;
    }
    if (error.contains('invalid') || error.contains('credentials')) {
      return 'Неверный email или пароль';
    }
    return AppStrings.errorGeneral;
  }

  // ── Refresh профиля ───────────────────────────────────────

  Future<void> refreshProfile() async {
    final user = await UserRepository.getMe();
    currentUser.value = user;
  }
}
