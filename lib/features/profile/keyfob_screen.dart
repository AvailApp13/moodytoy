import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/app_button.dart';
import 'ble_controller.dart';

class KeyfobScreen extends StatelessWidget {
  const KeyfobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BleController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(ctrl.isConnected.value
            ? AppStrings.manageKeyfob
            : AppStrings.connectKeyfob)),
      ),
      body: Obx(() {
        if (ctrl.isConnected.value) {
          return _ConnectedView(ctrl: ctrl);
        }
        return _ScanView(ctrl: ctrl);
      }),
    );
  }
}

// ── Сканирование ──────────────────────────────────────────

class _ScanView extends StatelessWidget {
  final BleController ctrl;

  const _ScanView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Анимация поиска
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary
                      .withOpacity(ctrl.isScanning.value ? 0.15 : 0.08),
                  border: Border.all(
                    color: AppColors.primary
                        .withOpacity(ctrl.isScanning.value ? 0.5 : 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.bluetooth_searching,
                  size: 48,
                  color: AppColors.primary
                      .withOpacity(ctrl.isScanning.value ? 1 : 0.5),
                ),
              )),

          const SizedBox(height: 24),

          Obx(() => Text(
                ctrl.isScanning.value
                    ? AppStrings.scanning
                    : 'Нажмите кнопку для поиска брелока',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              )),

          const SizedBox(height: 24),

          // Кнопка сканирования
          Obx(() => AppButton(
                label: ctrl.isScanning.value ? 'Остановить' : 'Начать поиск',
                icon: ctrl.isScanning.value
                    ? Icons.stop
                    : Icons.bluetooth_searching,
                isLoading: false,
                onPressed: ctrl.isScanning.value
                    ? ctrl.stopScan
                    : ctrl.startScan,
              )),

          const SizedBox(height: 24),

          // Список найденных устройств
          Expanded(
            child: Obx(() {
              final results = ctrl.scanResults;
              if (results.isEmpty && ctrl.isScanning.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (results.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Найдено устройств: ${results.length}',
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) =>
                          _DeviceCard(result: results[i], ctrl: ctrl),
                    ),
                  ),
                ],
              );
            }),
          ),

          // Инструкция
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.textHint),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Нажмите кнопку на брелоке для подтверждения привязки',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final ScanResult result;
  final BleController ctrl;

  const _DeviceCard({required this.result, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'Устройство';
    final mac = result.device.remoteId.str;
    final rssi = result.rssi;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bluetooth, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.labelLarge),
                Text(mac, style: Theme.of(context).textTheme.bodySmall),
                Text('Сигнал: $rssi dBm',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await ctrl.connectToDevice(result.device);
              if (!ok) {
                Get.snackbar('Ошибка', 'Не удалось подключиться');
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Привязать'),
          ),
        ],
      ),
    );
  }
}

// ── Управление подключённым брелоком ──────────────────────

class _ConnectedView extends StatelessWidget {
  final BleController ctrl;

  const _ConnectedView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),

          // Статус
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.1),
              border: Border.all(color: AppColors.success.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.bluetooth_connected,
                size: 48, color: AppColors.success),
          ),

          const SizedBox(height: 16),

          Text(AppStrings.keyfobConnected,
              style: Theme.of(context).textTheme.headlineMedium),

          const SizedBox(height: 24),

          // Инфо карточка
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              children: [
                Obx(() => _infoRow(context, AppStrings.deviceId,
                    ctrl.connectedMac.value.isNotEmpty
                        ? ctrl.connectedMac.value
                        : '--')),
                const Divider(height: 16),
                Obx(() {
                  final level = ctrl.batteryLevel.value;
                  return _infoRow(
                    context,
                    '${ctrl.batteryIcon} ${AppStrings.battery}',
                    level != null ? '$level%' : '--',
                    valueColor: level != null
                        ? (level > 50
                            ? AppColors.batteryGood
                            : level > 20
                                ? AppColors.batteryMedium
                                : AppColors.batteryLow)
                        : null,
                  );
                }),
                const Divider(height: 16),
                _infoRow(context, AppStrings.firmwareVersion, '1.0.0'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Инструкция по кнопкам
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _buttonHint('1 нажатие', '🟢 Готов к встрече'),
                _buttonHint('2 нажатия', '🔵 Грущу'),
                _buttonHint('3 нажатия', '🟣 Особый'),
                _buttonHint('Удержание 5 сек', '📍 Вкл/выкл локацию'),
              ],
            ),
          ),

          const Spacer(),

          // Кнопка отвязать
          AppButton(
            label: AppStrings.unbindKeyfob,
            isOutlined: true,
            color: AppColors.error,
            onPressed: () => _confirmUnbind(context),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: valueColor,
              ),
        ),
      ],
    );
  }

  Widget _buttonHint(String action, String result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(action,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Text(result,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _confirmUnbind(BuildContext context) {
    Get.dialog(AlertDialog(
      title: const Text('Отвязать брелок?'),
      content: const Text('Брелок будет отвязан от аккаунта'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Отмена')),
        TextButton(
          onPressed: () async {
            Get.back();
            await ctrl.disconnect();
          },
          child: const Text('Отвязать',
              style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}
