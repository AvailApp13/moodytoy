import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/language_service.dart';
import '../main_nav/main_nav_screen.dart';
import 'auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  final _nameCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userIdCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Переключатель языка (вверху справа)
              Align(
                alignment: Alignment.centerRight,
                child: _LanguageDropdown(onChanged: () => setState(() {})),
              ),
              const SizedBox(height: 24),
              // Лого
              const Text('🧸', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                'MoodyToy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              // Переключатель Вход / Регистрация
              _buildTabs(),
              const SizedBox(height: 24),
              // Поля формы
              if (_isRegister) _buildField(
                ctrl: _nameCtrl,
                label: 'auth_name'.tr,
                icon: Icons.person_outline,
              ),
              if (_isRegister) const SizedBox(height: 12),
              if (_isRegister) _buildField(
                ctrl: _userIdCtrl,
                label: 'auth_userid'.tr,
                icon: Icons.alternate_email,
              ),
              if (_isRegister) const SizedBox(height: 12),
              _buildField(
                ctrl: _emailCtrl,
                label: 'auth_email'.tr,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildField(
                ctrl: _passwordCtrl,
                label: 'auth_password'.tr,
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textHint, size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              if (_isRegister) const SizedBox(height: 12),
              if (_isRegister) _buildField(
                ctrl: _confirmCtrl,
                label: 'auth_confirm_password'.tr,
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
              ),
              // Забыли пароль (только в режиме входа)
              if (!_isRegister) Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.snackbar(
                    '',
                    'auth_forgot_stub'.tr,
                    backgroundColor: AppColors.surface,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                    margin: const EdgeInsets.all(16),
                  ),
                  child: Text('auth_forgot'.tr,
                      style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 16),
              // Обязательное согласие (только при регистрации)
              if (_isRegister) Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5)),
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                        child: Text(
                          'auth_terms_consent'.tr,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isRegister) const SizedBox(height: 12),
              // Кнопка действия
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _isRegister ? 'auth_register'.tr : 'auth_login'.tr,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Переключатель режима
              TextButton(
                onPressed: () => setState(() => _isRegister = !_isRegister),
                child: Text(
                  _isRegister ? 'auth_have_account'.tr : 'auth_no_account'.tr,
                  style: const TextStyle(color: AppColors.primary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text('v1.0.7 (build 8)',
                  style: TextStyle(color: AppColors.textHint.withOpacity(0.4), fontSize: 11)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(child: _tab('auth_login'.tr, !_isRegister, () {
          setState(() => _isRegister = false);
        })),
        Expanded(child: _tab('auth_register'.tr, _isRegister, () {
          setState(() => _isRegister = true);
        })),
      ]),
    );
  }

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Закрываем предыдущие snackbar'ы
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();

    // Нормализация
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    // Email regex — строгая валидация
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!emailRegex.hasMatch(email)) {
      _showError('auth_error_email'.tr);
      return;
    }
    if (password.length < 6) {
      _showError('auth_error_password_short'.tr);
      return;
    }

    if (_isRegister) {
      final name = _nameCtrl.text.trim();
      if (name.length < 2) {
        _showError('auth_error_name'.tr);
        return;
      }
      // User ID: только латиница и цифры, минимум 6 символов
      final userIdLogin = _userIdCtrl.text.trim();
      final userIdRegex = RegExp(r'^[a-zA-Z0-9]+$');
      if (userIdLogin.length < 6 || !userIdRegex.hasMatch(userIdLogin)) {
        _showError('auth_error_userid_invalid'.tr);
        return;
      }
      if (password != _confirmCtrl.text) {
        _showError('auth_error_password_mismatch'.tr);
        return;
      }
      // Обязательное согласие с условиями
      if (!_acceptedTerms) {
        _showError('auth_error_terms'.tr);
        return;
      }
    }

    setState(() => _isLoading = true);
    final auth = Get.find<AuthController>();
    final error = _isRegister
        ? await auth.signUp(name: _nameCtrl.text.trim(), email: email, password: password, userIdLogin: _userIdCtrl.text.trim())
        : await auth.signIn(email: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      Get.offAll(() => const MainNavScreen());
    }
  }

  void _showError(String msg) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.snackbar('', msg,
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        margin: const EdgeInsets.all(16));
  }
}

// ── Дропдаун выбора языка ─────────────────────────────────
class _LanguageDropdown extends StatelessWidget {
  final VoidCallback onChanged;
  const _LanguageDropdown({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = LanguageService.getSavedLanguage() ?? 'ru';
    final currentLang = LanguageService.supportedLocales
        .firstWhere((l) => l['code'] == current);

    return PopupMenuButton<Map<String, String>>(
      color: AppColors.surface,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (lang) async {
        await LanguageService.setLanguage(lang['code']!, lang['country']!);
        onChanged();
      },
      itemBuilder: (_) => LanguageService.supportedLocales.map((lang) {
        return PopupMenuItem<Map<String, String>>(
          value: lang.map((k, v) => MapEntry(k, v.toString())),
          child: Row(children: [
            Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(lang['name']!, style: const TextStyle(color: Colors.white)),
          ]),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(currentLang['flag']!, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(currentLang['name']!,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, color: AppColors.textHint, size: 18),
        ]),
      ),
    );
  }
}
