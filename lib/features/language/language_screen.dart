import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/language_service.dart';
import '../main_nav/main_nav_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Лого/иконка
              const Text('🧸', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text(
                'MoodyToy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),

              // Заголовок на 3 языках
              const Text(
                'Выберите язык\nSelect Language\n选择语言',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 32),

              // Кнопки выбора языка
              ...LanguageService.supportedLocales.map((lang) =>
                _LanguageButton(
                  flag: lang['flag']!,
                  name: lang['name']!,
                  code: lang['code']!,
                  country: lang['country']!,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String flag;
  final String name;
  final String code;
  final String country;

  const _LanguageButton({
    required this.flag,
    required this.name,
    required this.code,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          await LanguageService.setLanguage(code, country);
          Get.offAll(() => const MainNavScreen());
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 20),
          ]),
        ),
      ),
    );
  }
}
