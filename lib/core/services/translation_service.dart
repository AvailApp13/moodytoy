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

  // ─────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────

  static Future<String?> translate(String? text) async {
    if (text == null || text.trim().isEmpty) return null;

    final lang = _currentLang;
    if (lang == 'ru') return text; // русский — язык оригинала

    final cacheKey = '${text.hashCode}_$lang';

    // 1. In-memory кэш
    if (_memCache.containsKey(cacheKey)) return _memCache[cacheKey];

    // 2. SharedPreferences кэш
    final prefs = await _storage;
    final cached = prefs.getString('$_cachePrefix$cacheKey');
    if (cached != null) {
      _memCache[cacheKey] = cached;
      return cached;
    }

    // 3. DeepSeek API
    final translated = await _translateViaApi(text, lang);
    if (translated != null && translated.isNotEmpty) {
      _memCache[cacheKey] = translated;
      await prefs.setString('$_cachePrefix$cacheKey', translated);
      return translated;
    }

    return text; // fallback — оригинал
  }

  static String translateSync(String? text) {
    if (text == null || text.trim().isEmpty) return text ?? '';
    final lang = _currentLang;
    if (lang == 'ru') return text;
    final cacheKey = '${text.hashCode}_$lang';
    return _memCache[cacheKey] ?? text;
  }

  static Future<void> prefetch(List<String?> texts) async {
    await Future.wait(
      texts.where((t) => t != null && t.isNotEmpty).map(translate),
    );
  }

  static Future<void> clearCache() async {
    _memCache.clear();
    final prefs = await _storage;
    final keys = prefs.getKeys()
        .where((k) => k.startsWith(_cachePrefix))
        .toList();
    for (final k in keys) await prefs.remove(k);
  }

  // ─────────────────────────────────────────────────────────
  // DeepSeek API
  // ─────────────────────────────────────────────────────────

  static String get _currentLang => LanguageService.getSavedLanguage() ?? 'ru';

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
              'content':
                  'You are a translator. Translate the given text to $langName. '
                  'Return ONLY the translation. No explanations, no quotes, '
                  'no extra punctuation. Keep names and numbers as-is.',
            },
            {
              'role': 'user',
              'content': text,
            }
          ],
        },
      );
      final result = response
          .data['choices'][0]['message']['content']
          ?.toString()
          .trim();
      return (result != null && result.isNotEmpty) ? result : null;
    } catch (_) {
      return null; // при ошибке сети — показываем оригинал
    }
  }
}
