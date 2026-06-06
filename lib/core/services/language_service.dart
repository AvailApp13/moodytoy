import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'local_storage_service.dart';

class LanguageService {
  static const _key = 'app_language';

  static const supportedLocales = [
    {'code': 'ru', 'country': 'RU', 'flag': '🇷🇺', 'name': 'Русский'},
    {'code': 'en', 'country': 'US', 'flag': '🇬🇧', 'name': 'English'},
    {'code': 'zh', 'country': 'CN', 'flag': '🇨🇳', 'name': '中文'},
  ];

  /// Первый запуск — язык ещё не выбран
  static bool isFirstLaunch() {
    return !LocalStorageService.prefs.containsKey(_key);
  }

  /// Сохранённый язык (null если первый запуск)
  static String? getSavedLanguage() {
    return LocalStorageService.prefs.getString(_key);
  }

  /// Переключить язык и сохранить
  static Future<void> setLanguage(String code, String country) async {
    await LocalStorageService.prefs.setString(_key, code);
    Get.updateLocale(Locale(code, country));
  }

  /// Текущая Locale для GetMaterialApp
  static Locale get currentLocale {
    final code = getSavedLanguage() ?? 'ru';
    switch (code) {
      case 'zh': return const Locale('zh', 'CN');
      case 'en': return const Locale('en', 'US');
      default:   return const Locale('ru', 'RU');
    }
  }
}
