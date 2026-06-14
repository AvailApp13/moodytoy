import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/services/language_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/supabase_repository.dart';
import '../auth/auth_controller.dart';

class PeopleController extends GetxController {
  final allUsers = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final selectedMood = Rxn<Mood>();
  final isListMode = true.obs;
  final isLoading = false.obs;
  final myLocation = Rxn<LatLng>(); // WGS-84

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    initLocation();
  }

  // ── Геолокация ────────────────────────────────────────
  Future<void> initLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      myLocation.value = LatLng(pos.latitude, pos.longitude);

      final auth = Get.find<AuthController>();
      final myId = auth.currentUser.value?.id ?? '';
      if (myId.isNotEmpty) {
        await SupabaseRepository.updateLocation(
            myId, pos.latitude, pos.longitude);
      }
      _recalcDistances();
    } catch (_) {}
  }

  void _recalcDistances() {
    final me = myLocation.value;
    if (me == null) return;
    const distance = Distance();
    for (final u in allUsers) {
      if (u.lat != null && u.lng != null) {
        u.distanceMeters =
            distance.as(LengthUnit.Meter, me, LatLng(u.lat!, u.lng!));
      }
    }
    _applyFilter();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      final auth = Get.find<AuthController>();
      final myId = auth.currentUser.value?.id ?? '';
      final users = await SupabaseRepository.getNearbyUsers(myId);
      allUsers.value = users;
    } catch (_) {
      allUsers.value = [];
    }
    _recalcDistances();
    _applyFilter();
    isLoading.value = false;
  }

  void setFilter(Mood? mood) {
    selectedMood.value = mood;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedMood.value == null) {
      filteredUsers.value = List.from(allUsers);
    } else {
      filteredUsers.value =
          allUsers.where((u) => u.mood == selectedMood.value).toList();
    }
    filteredUsers.sort((a, b) =>
        (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999));
  }

  void toggleView() => isListMode.value = !isListMode.value;

  String formatDistance(double? meters) {
    if (meters == null) return '';
    final lang = LanguageService.getSavedLanguage() ?? 'ru';
    if (meters < 1000) {
      final r = (meters / 10).round() * 10;
      final s = switch (lang) { 'en' => 'm', 'zh' => '米', _ => 'м' };
      return '~${r.toInt()}$s';
    }
    final km = (meters / 1000).toStringAsFixed(1);
    final s = switch (lang) { 'en' => 'km', 'zh' => '千米', _ => 'км' };
    return '~$km$s';
  }
}
