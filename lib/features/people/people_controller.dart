import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/services/location_service.dart';
import '../../core/services/supabase_service.dart';

class PeopleController extends GetxController {
  // ── Состояние ─────────────────────────────────────────────
  final nearbyUsers = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final mapMode = 'split'.obs; // 'split' | 'list'
  final selectedMoodFilter = Rxn<String>(); // null = все
  final isLoading = false.obs;
  final myPosition = Rxn<Position>();

  StreamSubscription? _realtimeSubscription;
  Timer? _refreshTimer;

  final LocationService _locationService = Get.find<LocationService>();

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isLoading.value = true;

    // Получить текущую позицию
    myPosition.value = await _locationService.getCurrentPosition();

    // Запустить отслеживание
    await _locationService.startTracking();

    // Слушать позицию
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

  // ── Загрузить пользователей рядом ─────────────────────────

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

  // ── Фильтр по настроению ──────────────────────────────────

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

  // ── Режим отображения ─────────────────────────────────────

  void toggleMapMode() {
    mapMode.value = mapMode.value == 'split' ? 'list' : 'split';
  }

  void setMapMode(String mode) {
    mapMode.value = mode;
  }

  // ── Realtime подписка ─────────────────────────────────────

  void _subscribeToRealtime() {
    _realtimeSubscription?.cancel();

    _realtimeSubscription = SupabaseService.client
        .channel('users-location')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            _loadNearbyUsers();
          },
        )
        .subscribe() as StreamSubscription?;
  }

  // ── Авто-обновление каждые 10 секунд ─────────────────────

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadNearbyUsers();
    });
  }

  // ── Обновить вручную ──────────────────────────────────────

  Future<void> refresh() async {
    await _loadNearbyUsers();
  }

  @override
  void onClose() {
    _realtimeSubscription?.cancel();
    _refreshTimer?.cancel();
    super.onClose();
  }
}
