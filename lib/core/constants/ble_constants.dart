// lib/core/constants/ble_constants.dart
// ✅ РЕАЛЬНЫЕ UUID — Radioland 832-B2 (nRF52832)
// Источник: NRF52832-B系列规格书 V1.1, Раздел 7 (接口说明)
// Дополнение к ТЗ от производителя ShenZhen Radioland Technology CO.,LTD.

class BleConstants {
  BleConstants._();

  // ── Имя устройства (для сканирования) ────────────────────
  static const String deviceNamePrefix = 'R2210'; // R2210xxxx

  // ── GATT Service ──────────────────────────────────────────
  static const String serviceUuid =
      '00001803-494c-4f47-4943-544543480000';

  // ── Телефон → Брелок (Write) ──────────────────────────────
  // Отправка команд: пароль, настройки, изменение параметров
  static const String writeCharUuid =
      '00001805-494c-4f47-4943-544543480000';

  // ── Брелок → Телефон (Notify) ─────────────────────────────
  // Получение событий: нажатия кнопки, данные батареи
  static const String notifyCharUuid =
      '00001804-494c-4f47-4943-544543480000';

  // ── iBeacon UUID (для пассивного сканирования) ────────────
  static const String iBeaconUuid =
      'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';

  // ── Параметры подключения ──────────────────────────────────
  static const String defaultPassword = '123456';
  static const int passwordLength = 6;

  // ── Параметры распознавания нажатий ───────────────────────
  static const int multiTapWindowMs = 500;  // окно для мультинажатий
  static const int holdThresholdMs = 5000;  // удержание 5 сек
  static const int debounceMs = 50;         // защита от дребезга

  // ── Команды Write (телефон → брелок) ──────────────────────
  // Отправлять на writeCharUuid после подключения
  static const int cmdSetName = 0x11;         // + name bytes
  static const int cmdSetUuid = 0x12;         // + 16 bytes UUID
  static const int cmdGetUuid = 0x13;
  static const int cmdSetMajorMinor = 0x14;
  static const int cmdGetMajorMinor = 0x15;
  static const int cmdSetAdvInterval = 0x16;
  static const int cmdSetTxPower = 0x17;
  static const int cmdSetPassword = 0x18;
  static const int cmdSetMac = 0x1B;

  // ── Порог уровня батареи ───────────────────────────────────
  static const int batteryLowPercent = 20;
  static const int batteryCriticalPercent = 10;

  // ── Параметры iBeacon по умолчанию ────────────────────────
  static const int defaultMajor = 1;
  static const int defaultMinor = 2;
  static const int defaultRssiAt1m = -40; // dBm

  // ── Таймауты ───────────────────────────────────────────────
  static const int scanTimeoutSeconds = 30;
  static const int connectTimeoutSeconds = 10;
  static const int otaMinBatteryPercent = 20; // минимум для OTA

  // ── Байты нажатия кнопки ───────────────────────────────────
  // ⚠️ ОПРЕДЕЛИТЬ ЭКСПЕРИМЕНТАЛЬНО после получения брелока!
  // Инструкция:
  //   1. Подключить брелок
  //   2. Подписаться: characteristic.setNotifyValue(true)
  //   3. Нажать 1 раз → записать байты в лог
  //   4. Нажать 2 раза → записать байты
  //   5. Удержать 5 сек → записать байты
  //   6. Вставить значения ниже
  static const int? buttonByte1Tap = null;   // TODO: определить
  static const int? buttonByte2Tap = null;   // TODO: определить
  static const int? buttonByte3Tap = null;   // TODO: определить
  static const int? buttonByteHold = null;   // TODO: определить

  // ── Формат пакета Notify (брелок → телефон) ───────────────
  // Байт 0: длина имени (nameLength)
  // Байт 1: тип данных (0x09 = имя устройства)
  // Байты 2..nameLength+1: имя устройства (ASCII)
  // Байты nameLength+2..nameLength+7: MAC-адрес (6 байт)
  // Байты nameLength+8..nameLength+11: Major(2) + Minor(2)
  // Байт nameLength+9: уровень батареи (0x64=100%, 0x00=0%)
  // Байт nameLength+10: TX Power
  // Байт nameLength+11: интервал вещания
}
