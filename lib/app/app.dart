import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/local_storage_service.dart';
import '../features/auth/auth_controller.dart';
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
          return const MaterialApp(
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
        }
        Get.put(AuthController());
        return GetMaterialApp(
          title: 'MoodyToy',
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          home: const MainNavScreen(),
        );
      },
    );
  }

  Future<void> _init() async {
    await LocalStorageService.init();
    // Запрашиваем разрешения при первом запуске
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Геолокация
    final locationStatus = await Permission.locationWhenInUse.status;
    if (locationStatus.isDenied) {
      await Permission.locationWhenInUse.request();
    }

    // Камера и фото
    await Permission.camera.request();
    await Permission.photos.request();
  }
}
