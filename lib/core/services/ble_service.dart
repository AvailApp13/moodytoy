// BLE Service — заглушка для MVP
// Реальная реализация будет после получения брелока Radioland 832-B2

class BleService {
  static Future<void> initialize() async {
    // TODO: Инициализация BLE после получения устройства
  }

  static Future<void> startScan() async {
    // TODO: flutter_blue_plus startScan
  }

  static Future<void> connect(String mac) async {
    // TODO: Подключение к брелоку по MAC
  }

  static Future<void> disconnect() async {
    // TODO: Отключение
  }
}
