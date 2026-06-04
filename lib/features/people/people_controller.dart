import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/services/location_service.dart';
import '../../core/services/supabase_service.dart';

class PeopleController extends GetxController {
  final nearbyUsers = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final mapMode = 'split'.obs;
  final selectedMoodFilter = Rxn<String>();
  final isLoading = false.obs;
  final myPosition = Rxn<Position>();

  RealtimeChannel? _realtimeChannel;
  Timer? _refreshTimer;

  final LocationService _locationService = Get.find<LocationService>();

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isLoading.value = true;
    myPosition.value = await _locationService.getCurrentPosition();
    await _locationService.startTracking();
    ever(_locationService.currentPosition, (pos) {
      if (pos != null) {
        myPosition.value = pos;
        _loadNearbyUsers();
      }
    });
    await _loadNearbyUsers();
    _subscribeToRealtime();
    _startRefreshTimer();
    isLoading.value = false;
  }

  Future<void> _loadNearbyUsers() async {
    if (myPosition.value == null) return;
    final users = await UserRepository.getNearbyUsers(
      lat: myPosition.value!.latitude,
      lng: myPosition.value!.longitude,
      radiusMeters: 1000,
    );
    nearbyUsers.value = users;
    _applyFilter();
  }

  void setMoodFilter(String? mood) {
    selectedMoodFilter.value = mood;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedMoodFilter.value == null) {
      filteredUsers.value = nearbyUsers;
    } else {
      filteredUsers.value = nearbyUsers
          .where((u) => u.mood?.value == selectedMoodFilter.value)
          .toList();
    }
  }

  void setMapMode(String mode) => mapMode.value = mode;

  void _subscribeToRealtime() {
    _realtimeChannel = SupabaseService.client
        .channel('users-location')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          callback: (_) => _loadNearbyUsers(),
        )
        .subscribe();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadNearbyUsers();
    });
  }

  Future<void> refresh() => _loadNearbyUsers();

  @override
  void onClose() {
    _realtimeChannel?.unsubscribe();
    _refreshTimer?.cancel();
    super.onClose();
  }
}
