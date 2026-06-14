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

  // ── Перевод сообщения в чате по запросу (на язык юзера, включая RU) ──
  static Future<String?> translateMessage(String text) async {
    if (text.trim().isEmpty) return null;
    final lang = _currentLang;
    final cacheKey = 'msg_${text.hashCode}_$lang';
    if (_memCache.containsKey(cacheKey)) return _memCache[cacheKey];

    final prefs = await _storage;
    final cached = prefs.getString('$_cachePrefix$cacheKey');
    if (cached != null) {
      _memCache[cacheKey] = cached;
      return cached;
    }

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
          receiveTimeout: const Duration(seconds: 15),
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
      final result =
          response.data['choices'][0]['message']['content']?.toString().trim();
      if (result != null && result.isNotEmpty) {
        _memCache[cacheKey] = result;
        await prefs.setString('$_cachePrefix$cacheKey', result);
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
