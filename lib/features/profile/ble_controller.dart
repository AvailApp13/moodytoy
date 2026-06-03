import 'package:get/get.dart';
import '../../core/services/ble_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/constants/ble_constants.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleController extends GetxController {
  // ── Состояние ─────────────────────────────────────────────
  final isConnected = false.obs;
  final isScanning = false.obs;
  final mood = Rxn<Mood>();
  final batteryLevel = Rxn<int>();
  final connectedMac = ''.obs;
  final scanResults = <ScanResult>[].obs;

  final BleService _bleService = Get.find<BleService>();

  @override
  void onInit() {
    super.onInit();
    _bindToService();
  }

  void _bindToService() {
    // Синхронизируем состояние сервиса
    ever(_bleService.isConnected, (val) => isConnected.value = val);
    ever(_bleService.isScanning, (val) => isScanning.value = val);
    ever(_bleService.batteryLevel, (val) => batteryLevel.value = val);
    ever(_bleService.scanResults, (val) => scanResults.value = val);
    ever(_bleService.connectedDevice, (device) {
      connectedMac.value = device?.remoteId.str ?? '';
    });

    // Колбэки от кнопки брелока
    _bleService.onButtonPress = _onButtonPress;
    _bleService.onButtonHold = _onButtonHold;
    _bleService.onBatteryUpdate = (level) {
      batteryLevel.value = level;
      // Уведомление о низком заряде
      if (level <= BleConstants.batteryCriticalPercent) {
        Get.snackbar('⚠️ Критический заряд', 'Срочно замени батарейку CR2032');
      } else if (level <= BleConstants.batteryLowPercent) {
        Get.snackbar('🔋 Низкий заряд', 'Замени батарейку CR2032');
      }
    };
  }

  // ── Обработка нажатий кнопки ──────────────────────────────

  void _onButtonPress(int taps) {
    Mood newMood;
    switch (taps) {
      case 1:
        newMood = Mood.ready;
        break;
      case 2:
        newMood = Mood.sad;
        break;
      case 3:
        newMood = Mood.extra;
        break;
      default:
        return;
    }

    mood.value = newMood;
    UserRepository.updateMood(newMood);

    // Визуальное подтверждение
    Get.snackbar(
      '${newMood.label}',
      'Настроение обновлено',
      duration: const Duration(seconds: 2),
    );
  }

  // ── Удержание кнопки — переключить локацию ────────────────

  void _onButtonHold() {
    // Определяем текущее состояние из профиля и инвертируем
    final auth = Get.find<dynamic>(tag: 'auth');
    // ignore: avoid_dynamic_calls
    final currentEnabled = auth?.currentUser?.value?.locationEnabled ?? false;
    UserRepository.toggleLocation(!currentEnabled);

    Get.snackbar(
      currentEnabled ? '📍 Локация выключена' : '📍 Локация включена',
      currentEnabled ? 'Ты скрыт на карте' : 'Ты видим на карте',
      duration: const Duration(seconds: 2),
    );
  }

  // ── Сканирование и привязка ───────────────────────────────

  Future<void> startScan() => _bleService.startScan();

  Future<void> stopScan() => _bleService.stopScan();

  Future<bool> connectToDevice(BluetoothDevice device) async {
    final success = await _bleService.connectToDevice(device);
    if (success) {
      connectedMac.value = device.remoteId.str;
    }
    return success;
  }

  Future<void> disconnect() => _bleService.disconnect();

  // ── Включить Bluetooth ────────────────────────────────────

  Future<bool> requestBluetooth() async {
    await BleService.requestEnable();
    return BleService.isBluetoothOn();
  }

  // ── Цвет индикатора батареи ───────────────────────────────

  String get batteryIcon {
    final level = batteryLevel.value;
    if (level == null) return '🔋';
    if (level > 50) return '🔋';
    if (level > 20) return '🪫';
    return '⚠️';
  }
}
