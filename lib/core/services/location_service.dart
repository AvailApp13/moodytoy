import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationService extends GetxService {
  final currentPosition = Rxn<Position>();
  final hasPermission = false.obs;

  Future<void> init() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final result = await Geolocator.requestPermission();
      hasPermission.value = result != LocationPermission.denied &&
          result != LocationPermission.deniedForever;
    } else {
      hasPermission.value = permission != LocationPermission.deniedForever;
    }

    if (hasPermission.value) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        currentPosition.value = pos;
      } catch (_) {}
    }
  }
}
