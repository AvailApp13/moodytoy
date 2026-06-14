import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language_service.dart';

class TranslationService {
  static const _cachePrefix = 'tr_cache_';
  static const _apiKey = 'sk-8da8911266f04335925f3bcb3cdecaf8';
  static const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  static final Map<String, String> _memCache = {};
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<String?> translate(String? text) async {
    if (text == null || text.trim().isEmpty) return null;
    final lang = _currentLang;
    if (lang == 'ru') return text;

    final cacheKey = '${text.hashCode}_$lang';
    if (_memCache.containsKey(cacheKey)) return _memCache[cacheKey];

    final prefs = await _storage;
    final cached = prefs.getString('$_cachePrefix$cacheKey');
    if (cached != null) {
      _memCache[cacheKey] = cached;
      return cached;
    }

    final translated = await _translateViaApi(text, lang);
    if (translated != null && translated.isNotEmpty) {
      _memCache[cacheKey] = translated;
      await prefs.setString('$_cachePrefix$cacheKey', translated);
      return translated;
    }
    return text; // Всегда возвращаем оригинал при ошибке, без суффиксов
  }

  static String translateSync(String? text) {
    if (text == null || text.trim().isEmpty) return text ?? '';
    final lang = _currentLang;
    if (lang == 'ru') return text;
    final cacheKey = '${text.hashCode}_$lang';
    return _memCache[cacheKey] ?? text;
  }

  static Future<void> clearCache() async {
    _memCache.clear();
    final prefs = await _storage;
    for (final k in prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList()) {
      await prefs.remove(k);
    }
  }

  static String get _currentLang => LanguageService.getSavedLanguage() ?? 'ru';

  // Последняя ошибка перевода (для диагностики в UI)
  static String? lastError;

  // Определяем язык текста (ru/en/zh) по символам
  static String _detectLang(String text) {
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(text)) return 'zh'; // иероглифы
    if (RegExp(r'[\u0400-\u04FF]').hasMatch(text)) return 'ru'; // кириллица
    return 'en';
  }

  // ── Перевод сообщения в чате по запросу (на язык юзера) ──
  // 1) MyMemory (бесплатно, без ключа)  2) DeepSeek (запасной, если есть баланс)
  static Future<String?> translateMessage(String text) async {
    lastError = null;
    if (text.trim().isEmpty) return null;
    final target = _currentLang;
    final source = _detectLang(text);

    // Уже на языке пользователя — переводить нечего
    if (source == target) return text;

    final cacheKey = 'msg_${text.hashCode}_$target';
    if (_memCache.containsKey(cacheKey)) return _memCache[cacheKey];
    final prefs = await _storage;
    final cached = prefs.getString('$_cachePrefix$cacheKey');
    if (cached != null) {
      _memCache[cacheKey] = cached;
      return cached;
    }

    // 1) MyMemory
    final mm = await _translateMyMemory(text, source, target);
    if (mm != null) {
      _memCache[cacheKey] = mm;
      await prefs.setString('$_cachePrefix$cacheKey', mm);
      return mm;
    }

    // 2) DeepSeek (запасной — сработает только если пополнен баланс)
    final ds = await _translateDeepSeek(text, target);
    if (ds != null) {
      _memCache[cacheKey] = ds;
      await prefs.setString('$_cachePrefix$cacheKey', ds);
      return ds;
    }

    return null; // lastError уже установлен
  }

  // ── MyMemory: бесплатный переводчик без ключа ──────────
  // MyMemory ждёт коды RFC3066: ru, en, zh-CN
  static String _mmCode(String lang) {
    switch (lang) {
      case 'zh': return 'zh-CN';
      case 'en': return 'en-GB';
      case 'ru': return 'ru-RU';
      default:   return lang;
    }
  }

  static Future<String?> _translateMyMemory(
      String text, String source, String target) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.mymemory.translated.net/get',
        queryParameters: {
          'q': text,
          'langpair': '${_mmCode(source)}|${_mmCode(target)}',
        },
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode != 200) {
        lastError = 'MyMemory HTTP ${response.statusCode}';
        return null;
      }
      final data = response.data is Map ? response.data : null;
      final translated =
          data?['responseData']?['translatedText']?.toString().trim();
      // MyMemory кладёт предупреждения прямо в текст
      if (translated == null || translated.isEmpty) {
        lastError = 'MyMemory: пустой ответ';
        return null;
      }
      final upper = translated.toUpperCase();
      if (upper.contains('MYMEMORY WARNING') ||
          upper.contains('QUOTA') ||
          upper.contains('QUERY LENGTH LIMIT') ||
          upper.contains('AVAILABLE FREE TRANSLATIONS')) {
        lastError = 'MyMemory лимит: $translated';
        return null;
      }
      return translated;
    } on DioException catch (e) {
      lastError = 'MyMemory сеть: ${e.type}';
      return null;
    } catch (e) {
      lastError = 'MyMemory ошибка: $e';
      return null;
    }
  }

  // ── DeepSeek: запасной (нужен баланс) ──────────────────
  static Future<String?> _translateDeepSeek(String text, String lang) async {
    final langName = lang == 'zh'
        ? 'Chinese (Simplified)'
        : lang == 'en' ? 'English' : 'Russian';
    try {
      final dio = Dio();
      final response = await dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
        data: {
          'model': 'deepseek-chat',
          'max_tokens': 400,
          'temperature': 0.1,
          'messages': [
            {
              'role': 'system',
              'content': 'Translate the user message to $langName. '
                  'Return ONLY the translation, no quotes, no explanations. '
                  'Keep names, emojis and numbers as-is.',
            },
            {'role': 'user', 'content': text}
          ],
        },
      );
      if (response.statusCode != 200) {
        // Сохраняем ошибку DeepSeek только если MyMemory тоже не дал причину
        lastError ??= 'DeepSeek HTTP ${response.statusCode}';
        return null;
      }
      final result =
          response.data['choices']?[0]?['message']?['content']?.toString().trim();
      if (result != null && result.isNotEmpty) {
        lastError = null;
        return result;
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _translateViaApi(String text, String targetLang) async {
    final langName = targetLang == 'zh' ? 'Chinese (Simplified)' : 'English';
    try {
      final dio = Dio();
      final response = await dio.post(
        _apiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
        data: {
          'model': 'deepseek-chat',
          'max_tokens': 300,
          'temperature': 0.1,
          'messages': [
            {
              'role': 'system',
              'content': 'Translate to $langName. Return ONLY the translation. '
                  'No explanations, no quotes. Keep names and numbers as-is.',
            },
            {'role': 'user', 'content': text}
          ],
        },
      );
      return response.data['choices'][0]['message']['content']?.toString().trim();
    } catch (_) {
      return null; // При любой ошибке — оригинал
    }
  }
}
