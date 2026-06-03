import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../data/repositories/user_repository.dart';

class LocationService extends GetxService {
  final currentPosition = Rxn<Position>();
  final hasPermission = false.obs;

  StreamSubscription<Position>? _positionSubscription;

  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // обновлять при сдвиге на 10 метров
  );

  @override
  void onInit() {
    super.onInit();
    _checkPermission();
  }

  // ── Разрешения ────────────────────────────────────────────

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return false;

    hasPermission.value = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    return hasPermission.value;
  }

  Future<void> _checkPermission() async {
    final permission = await Geolocator.checkPermission();
    hasPermission.value = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ── Запуск обновлений ─────────────────────────────────────

  Future<void> startTracking() async {
    if (!hasPermission.value) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(_onPositionUpdate);
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void _onPositionUpdate(Position position) {
    currentPosition.value = position;
    // Отправляем на сервер (WGS-84 GPS координаты)
    UserRepository.updateLocation(position.latitude, position.longitude);
  }

  // ── Разовое получение позиции ─────────────────────────────

  Future<Position?> getCurrentPosition() async {
    if (!hasPermission.value) return null;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      currentPosition.value = pos;
      return pos;
    } catch (e) {
      return null;
    }
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    super.onClose();
  }
}
