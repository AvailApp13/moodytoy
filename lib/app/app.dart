import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/local_storage_service.dart';
import '../features/auth/auth_controller.dart';
import '../features/main_nav/main_nav_screen.dart';
import '../shared/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: LocalStorageService.init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Color(0xFF0F0F1A),
              body: Center(child: CircularProgressIndicator()),
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
}
