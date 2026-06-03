import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../constants/ble_constants.dart';
import '../../data/repositories/user_repository.dart';

typedef ButtonPressCallback = void Function(int taps);
typedef HoldCallback = void Function();
typedef BatteryCallback = void Function(int percent);
typedef ConnectionCallback = void Function(bool connected);

class BleService extends GetxService {
  // ── Состояние ─────────────────────────────────────────────
  final isScanning = false.obs;
  final isConnected = false.obs;
  final connectedDevice = Rxn<BluetoothDevice>();
  final batteryLevel = Rxn<int>();
  final scanResults = <ScanResult>[].obs;

  // ── Callbacks ─────────────────────────────────────────────
  ButtonPressCallback? onButtonPress;
  HoldCallback? onButtonHold;
  BatteryCallback? onBatteryUpdate;
  ConnectionCallback? onConnectionChange;

  // ── Internal ──────────────────────────────────────────────
  BluetoothCharacteristic? _notifyChar;
  BluetoothCharacteristic? _writeChar;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _notifySubscription;
  StreamSubscription? _connectionSubscription;

  // Для определения нажатий
  int _tapCount = 0;
  Timer? _tapTimer;
  DateTime? _pressStart;

  // ── Инициализация ─────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _listenToBluetoothState();
  }

  void _listenToBluetoothState() {
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        _handleDisconnect();
      }
    });
  }

  // ── Сканирование ──────────────────────────────────────────

  Future<void> startScan() async {
    if (isScanning.value) return;

    scanResults.clear();
    isScanning.value = true;

    try {
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: BleConstants.scanTimeoutSeconds),
        withServices: [Guid(BleConstants.serviceUuid)],
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final filtered = results.where((r) {
          final name = r.device.platformName;
          return name.startsWith(BleConstants.deviceNamePrefix) ||
              name.contains('Radioland') ||
              name.contains('832');
        }).toList();
        scanResults.value = filtered;
      });

      // Таймаут
      await Future.delayed(
          Duration(seconds: BleConstants.scanTimeoutSeconds));
    } finally {
      await stopScan();
    }
  }

  Future<void> stopScan() async {
    isScanning.value = false;
    _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
  }

  // ── Подключение ───────────────────────────────────────────

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: Duration(seconds: BleConstants.connectTimeoutSeconds),
        autoConnect: false,
      );

      // Слушать разрыв соединения
      _connectionSubscription = device.connectionState.listen((state) {
        final connected = state == BluetoothConnectionState.connected;
        isConnected.value = connected;
        onConnectionChange?.call(connected);
        if (!connected) _handleDisconnect();
      });

      // Discover services
      final services = await device.discoverServices();
      bool found = false;

      for (final service in services) {
        if (service.uuid.str.toLowerCase() ==
            BleConstants.serviceUuid.toLowerCase()) {
          found = true;
          await _setupCharacteristics(service);
        }
      }

      if (!found) {
        await device.disconnect();
        return false;
      }

      connectedDevice.value = device;
      isConnected.value = true;

      // Сохранить MAC в профиль
      final mac = device.remoteId.str;
      await UserRepository.saveKeyfobMac(mac);

      return true;
    } catch (e) {
      await device.disconnect();
      return false;
    }
  }

  Future<void> _setupCharacteristics(BluetoothService service) async {
    for (final char in service.characteristics) {
      final uuid = char.uuid.str.toLowerCase();

      if (uuid == BleConstants.notifyCharUuid.toLowerCase()) {
        _notifyChar = char;
        await char.setNotifyValue(true);
        _notifySubscription = char.onValueReceived.listen(_handleNotify);
      }

      if (uuid == BleConstants.writeCharUuid.toLowerCase()) {
        _writeChar = char;
      }
    }
  }

  // ── Обработка Notify пакета ───────────────────────────────

  void _handleNotify(List<int> value) {
    if (value.isEmpty) return;

    // Лог для первого теста — определяем байты кнопки
    // ignore: avoid_print
    print('BLE Notify: ${value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}');

    // Парсим батарею
    final battery = _parseBattery(value);
    if (battery >= 0) {
      batteryLevel.value = battery;
      onBatteryUpdate?.call(battery);
      UserRepository.updateBatteryLevel(battery);
    }

    // ⚠️ TODO: определить байты кнопки после получения брелока
    // После теста заменить заглушки ниже на реальные значения
    if (BleConstants.buttonByte1Tap != null) {
      _detectButtonPress(value);
    } else {
      // Временная логика — попытка угадать по изменению байт
      _detectButtonPressFallback(value);
    }
  }

  int _parseBattery(List<int> data) {
    if (data.isEmpty) return -1;
    final nameLength = data[0];
    final batteryIdx = nameLength + 9;
    if (data.length > batteryIdx) {
      return data[batteryIdx].clamp(0, 100);
    }
    return -1;
  }

  void _detectButtonPress(List<int> value) {
    // TODO: заменить на реальные байты после тестирования
    // if (value.contains(BleConstants.buttonByte1Tap!)) _registerTap();
    // if (value.contains(BleConstants.buttonByteHold!)) { onButtonHold?.call(); }
  }

  // Временная логика до получения брелока
  void _detectButtonPressFallback(List<int> value) {
    // Просто логируем — после теста реализуем
    // ignore: avoid_print
    print('Button bytes (raw): $value');
  }

  void _registerTap() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(
      Duration(milliseconds: BleConstants.multiTapWindowMs),
      () {
        onButtonPress?.call(_tapCount);
        _tapCount = 0;
      },
    );
  }

  // ── Запись команды ────────────────────────────────────────

  Future<bool> writeCommand(List<int> bytes) async {
    if (_writeChar == null) return false;
    try {
      await _writeChar!.write(bytes, withoutResponse: false);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Отключение ────────────────────────────────────────────

  Future<void> disconnect() async {
    await connectedDevice.value?.disconnect();
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _notifySubscription?.cancel();
    _connectionSubscription?.cancel();
    _notifyChar = null;
    _writeChar = null;
    connectedDevice.value = null;
    isConnected.value = false;
  }

  // ── Статус Bluetooth ──────────────────────────────────────

  static Future<bool> isBluetoothOn() async {
    return await FlutterBluePlus.adapterState.first ==
        BluetoothAdapterState.on;
  }

  static Future<void> requestEnable() async {
    if (!await isBluetoothOn()) {
      await FlutterBluePlus.turnOn();
    }
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectionSubscription?.cancel();
    _tapTimer?.cancel();
    super.onClose();
  }
}
