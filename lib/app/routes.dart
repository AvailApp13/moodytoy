import 'package:get/get.dart';
import '../features/auth/login_screen.dart';
import '../features/main_nav/main_nav_screen.dart';
import '../features/profile/keyfob_screen.dart';
import '../features/profile/profile_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String main = '/main';
  static const String keyfob = '/keyfob';
  static const String settings = '/settings';

  static final routes = [
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: main, page: () => const MainNavScreen()),
    GetPage(name: keyfob, page: () => const KeyfobScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
  ];
}
