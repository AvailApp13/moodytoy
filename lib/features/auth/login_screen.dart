import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/app_button.dart';
import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _obscurePassword = true.obs;

  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.put(AuthController());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // ── Лого ───────────────────────────────────────
              _buildLogo(),

              const SizedBox(height: 48),

              // ── Заголовок ──────────────────────────────────
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.tagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: 48),

              // ── Email ──────────────────────────────────────
              Obx(() => TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: AppStrings.emailHint,
                      labelText: AppStrings.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _auth.emailError.value.isEmpty
                          ? null
                          : _auth.emailError.value,
                    ),
                    onChanged: (_) => _auth.emailError.value = '',
                  )),

              const SizedBox(height: 16),

              // ── Пароль ─────────────────────────────────────
              Obx(() => TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword.value,
                    decoration: InputDecoration(
                      hintText: AppStrings.passwordHint,
                      labelText: AppStrings.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _auth.passwordError.value.isEmpty
                          ? null
                          : _auth.passwordError.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword.value
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            _obscurePassword.value = !_obscurePassword.value,
                      ),
                    ),
                    onChanged: (_) => _auth.passwordError.value = '',
                  )),

              const SizedBox(height: 8),

              // ── Ошибка ─────────────────────────────────────
              Obx(() => _auth.errorMessage.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _auth.errorMessage.value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink()),

              const SizedBox(height: 24),

              // ── Кнопка входа/регистрации ───────────────────
              Obx(() => AppButton(
                    label: AppStrings.loginOrRegister,
                    isLoading: _auth.isLoading.value,
                    onPressed: () => _auth.loginOrRegister(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                    ),
                  )),

              const SizedBox(height: 32),

              // ── Подсказка ──────────────────────────────────
              Text(
                'Если аккаунта нет — он создастся автоматически',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.favorite_rounded,
        color: AppColors.primary,
        size: 40,
      ),
    );
  }
}
