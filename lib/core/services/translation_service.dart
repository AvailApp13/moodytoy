import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_service.dart';

/// TranslationService — динамический перевод пользовательского контента.
///
/// Архитектура:
///   _translateViaApi()  ← ЕДИНСТВЕННОЕ место, где подключается реальный API.
///   Всё остальное (кэш, виджеты) остаётся без изменений.
///
/// Сейчас: заглушка (возвращает оригинал, в dev-режиме добавляет суффикс).
/// Чтобы подключить DeepSeek / Google ML Kit — замени тело _translateViaApi().
class TranslationService {
  static const _cachePrefix = 'tr_cache_';
  static const bool _devMode = false; // true → показывает "[en]" суффикс

  // ── In-memory кэш (быстрее SharedPreferences) ─────────
  static final Map<String, String> _memCache = {};

  // ── SharedPreferences (персистентный) ─────────────────
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────

  /// Переводит строку на текущий язык приложения.
  /// Если текст null/пустой — возвращает null.
  /// Сначала смотрит в кэш, затем вызывает API.
  static Future<String?> translate(String? text) async {
    if (text == null || text.trim().isEmpty) return null;

    final lang = _currentLang;
    // Русский — язык оригинала, перевод не нужен
    if (lang == 'ru') return text;

    final cacheKey = '${text.hashCode}_$lang';

    // 1. In-memory кэш
    if (_memCache.containsKey(cacheKey)) {
      return _memCache[cacheKey];
    }

    // 2. SharedPreferences кэш
    final prefs = await _storage;
    final cached = prefs.getString('$_cachePrefix$cacheKey');
    if (cached != null) {
      _memCache[cacheKey] = cached;
      return cached;
    }

    // 3. API
    final translated = await _translateViaApi(text, lang);
    if (translated != null) {
      _memCache[cacheKey] = translated;
      await prefs.setString('$_cachePrefix$cacheKey', translated);
    }
    return translated ?? text;
  }

  /// Синхронная версия — только из кэша.
  /// Если перевода нет — возвращает оригинал.
  static String translateSync(String? text) {
    if (text == null || text.trim().isEmpty) return text ?? '';
    final lang = _currentLang;
    if (lang == 'ru') return text;
    final cacheKey = '${text.hashCode}_$lang';
    return _memCache[cacheKey] ?? text;
  }

  /// Предзагружает переводы для списка строк в фоне.
  static Future<void> prefetch(List<String?> texts) async {
    final futures = texts
        .where((t) => t != null && t.isNotEmpty)
        .map((t) => translate(t));
    await Future.wait(futures);
  }

  /// Очищает весь кэш (при смене языка).
  static Future<void> clearCache() async {
    _memCache.clear();
    final prefs = await _storage;
    final keys = prefs.getKeys()
        .where((k) => k.startsWith(_cachePrefix))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  // ─────────────────────────────────────────────────────────
  // ВНУТРЕННЯЯ ЛОГИКА
  // ─────────────────────────────────────────────────────────

  static String get _currentLang =>
      LanguageService.getSavedLanguage() ?? 'ru';

  /// ═══════════════════════════════════════════════════════
  /// ЗАГЛУШКА → ЗАМЕНИ ЭТО НА РЕАЛЬНЫЙ API
  ///
  /// Чтобы подключить DeepSeek:
  ///   1. Добавь DEEPSEEK_API_KEY в .env
  ///   2. Замени тело этого метода (см. инструкцию ниже)
  ///   3. ВСЕ виджеты автоматически начнут использовать реальный перевод
  /// ═══════════════════════════════════════════════════════
  static Future<String?> _translateViaApi(
      String text, String targetLang) async {
    // STUB: возвращает оригинал (в devMode — с суффиксом языка)
    await Future.delayed(const Duration(milliseconds: 50)); // имитация сети
    if (_devMode) {
      return '$text [$targetLang]';
    }
    return text;

    // ─── ПРИМЕР: DeepSeek API ───────────────────────────
    // import 'package:dio/dio.dart';
    // import 'package:flutter_dotenv/flutter_dotenv.dart';
    //
    // final dio = Dio();
    // final langName = targetLang == 'zh' ? 'Chinese' : 'English';
    // try {
    //   final response = await dio.post(
    //     'https://api.deepseek.com/v1/chat/completions',
    //     options: Options(headers: {
    //       'Authorization': 'Bearer ${dotenv.env['DEEPSEEK_API_KEY']}',
    //       'Content-Type': 'application/json',
    //     }),
    //     data: {
    //       'model': 'deepseek-chat',
    //       'max_tokens': 200,
    //       'messages': [{
    //         'role': 'user',
    //         'content': 'Translate to $langName. '
    //             'Return ONLY the translation, no explanations.\n\n$text',
    //       }],
    //     },
    //   );
    //   return response.data['choices'][0]['message']['content']?.trim();
    // } catch (e) {
    //   return null; // при ошибке вернётся оригинал
    // }

    // ─── ПРИМЕР: Google ML Kit (офлайн) ─────────────────
    // import 'package:google_mlkit_translation/google_mlkit_translation.dart';
    //
    // final srcLang = TranslateLanguage.russian;
    // final tgtLang = targetLang == 'zh'
    //     ? TranslateLanguage.chinese
    //     : TranslateLanguage.english;
    // final translator = OnDeviceTranslator(
    //   sourceLanguage: srcLang,
    //   targetLanguage: tgtLang,
    // );
    // try {
    //   return await translator.translateText(text);
    // } finally {
    //   translator.close();
    // }
  }
}
