import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/language_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/supabase_service.dart';
import '../core/translations/app_translations.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screen.dart';
import '../features/language/language_screen.dart';
import '../features/main_nav/main_nav_screen.dart';
import '../shared/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _loading();
        }

        Get.put(AuthController());

        return GetMaterialApp(
          title: 'MoodyToy',
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          translations: AppTranslations(),
          locale: LanguageService.currentLocale,
          fallbackLocale: const Locale('ru', 'RU'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ru', 'RU'),
            Locale('en', 'US'),
            Locale('zh', 'CN'),
          ],
          home: _decideHome(),
        );
      },
    );
  }

  Widget _decideHome() {
    // 1. Первый запуск → выбор языка
    if (LanguageService.isFirstLaunch()) {
      return const LanguageScreen();
    }

    // 2. Язык выбран, но сессии Supabase нет → auth
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        return const AuthScreen();
      }
    } catch (_) {
      return const AuthScreen();
    }

    // 3. Сессия активна → главный экран
    return const MainNavScreen();
  }

  Widget _loading() => const MaterialApp(
    home: Scaffold(
      backgroundColor: Color(0xFF0F0F1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🧸', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFF4A9EFF)),
          ],
        ),
      ),
    ),
  );

  Future<void> _init() async {
    await LocalStorageService.init();
    await SupabaseService.initialize();
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final loc = await Permission.locationWhenInUse.status;
    if (loc.isDenied) await Permission.locationWhenInUse.request();
    await Permission.camera.request();
    await Permission.photos.request();
  }
}
