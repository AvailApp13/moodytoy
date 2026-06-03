import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/theme/app_theme.dart';
import '../core/services/ble_service.dart';
import '../core/services/location_service.dart';
import '../core/services/push_service.dart';
import 'routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Регистрируем глобальные сервисы
    Get.put(BleService(), permanent: true);
    Get.put(LocationService(), permanent: true);
    Get.put(PushService(), permanent: true);

    return GetMaterialApp(
      title: 'MoodyToy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.routes,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 250),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}
