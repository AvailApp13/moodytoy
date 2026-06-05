import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/services/location_service.dart';

class PeopleController extends GetxController {
  final nearbyUsers = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final isMapView = false.obs;
  final selectedMoodFilter = Rxn<String>();
  final isLoading = false.obs;
  final myPosition = Rxn<Position>();

  final LocationService _locationService = Get.find<LocationService>();

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    isLoading.value = true;
    // Для MVP создаем мок-данные сразу
    _generateMockUsers();
    isLoading.value = false;
  }

  void _generateMockUsers() {
    final random = SystemRandom();
    final moods = [
      Mood.coffeeBreak, Mood.gamer, Mood.dating, Mood.walk, Mood.sport
    ];
    final names = ['Иван', 'Мария', 'Дмитрий', 'Ольга', 'Сергей', 'Анна', 'Максим', 'Елена'];

    for (int i = 0; i < 15; i++) {
      final lat = 55.751244 + (random.nextDouble() - 0.5) * 0.1;
      final lng = 37.618423 + (random.nextDouble() - 0.5) * 0.1;
      final mood = moods[random.nextInt(moods.length)];

      var user = UserModel(
        id: 'user_$i',
        email: 'user$i@example.com',
        name: names[i % names.length],
        age: 20 + random.nextInt(20),
        mood: mood,
        bio: 'Мок-пользователь №$i',
        locationEnabled: random.nextBool(),
        lat: lat,
        lng: lng,
      );

      nearbyUsers.add(user);
    }
    _applyFilter();
  }

  void setMoodFilter(String? mood) {
    selectedMoodFilter.value = mood;
    _applyFilter();
  }

  void toggleMapView() {
    isMapView.value = !isMapView.value;
  }

  void _applyFilter() {
    if (selectedMoodFilter.value == null) {
      filteredUsers.value = nearbyUsers;
    } else {
      // Сопоставляем строку настроения с enum
      Mood? filterMood;
      switch (selectedMoodFilter.value) {
        case 'Кофе-брейк': filterMood = Mood.coffeeBreak; break;
        case 'Игрок': filterMood = Mood.gamer; break;
        case 'Знакомство': filterMood = Mood.dating; break;
        case 'Прогулка': filterMood = Mood.walk; break;
        case 'Спорт/активность': filterMood = Mood.sport; break;
      }
      
      filteredUsers.value = nearbyUsers
          .where((u) => u.mood == filterMood)
          .toList();
    }
  }

  Future<void> refresh() async {
    // В будущем здесь будет загрузка реальных данных
  }
}
