import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import '../../data/repositories/user_repository.dart';

class PushService extends GetxService {
  static final _jPush = JPush();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    final appKey = dotenv.env['JPUSH_APP_KEY'] ?? '';
    if (appKey.isEmpty) return;

    try {
      await _jPush.setup(
        appKey: appKey,
        channel: 'flutter',
        production: false,
        debug: true,
      );

      // Получить registration ID и сохранить
      final registrationId = await _jPush.getRegistrationID();
      if (registrationId != null && registrationId.isNotEmpty) {
        await UserRepository.updatePushToken(registrationId);
      }

      // Слушать уведомления
      _jPush.addEventHandler(
        onReceiveNotification: _onNotificationReceived,
        onOpenNotification: _onNotificationOpened,
      );
    } catch (e) {
      // JPush недоступен — игнорируем
    }
  }

  Future<void> _onNotificationReceived(Map<String, dynamic> message) async {
    // Уведомление получено пока приложение открыто
  }

  Future<void> _onNotificationOpened(Map<String, dynamic> message) async {
    // Пользователь нажал на уведомление
    final extras = message['extras'] as Map?;
    if (extras == null) return;

    final type = extras['type'] as String?;
    switch (type) {
      case 'nearby':
        Get.toNamed('/people');
        break;
      case 'friend_request':
        Get.toNamed('/friends');
        break;
      case 'firmware':
        Get.toNamed('/keyfob');
        break;
    }
  }
}
