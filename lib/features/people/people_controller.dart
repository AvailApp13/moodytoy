import 'package:get/get.dart';
import '../../core/services/language_service.dart';
import '../../core/services/mock_data.dart';
import '../../data/models/user_model.dart';

class PeopleController extends GetxController {
  final allUsers = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final selectedMood = Rxn<Mood>();
  final isListMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    allUsers.value = MockData.nearbyUsers;
    _applyFilter();
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
      final rounded = (meters / 10).round() * 10;
      final suffix = switch (lang) {
        'en' => 'm',
        'zh' => '米',
        _    => 'м',
      };
      return '~${rounded.toInt()}$suffix';
    }

    final km = (meters / 1000).toStringAsFixed(1);
    final suffix = switch (lang) {
      'en' => 'km',
      'zh' => '千米',
      _    => 'км',
    };
    return '~$km$suffix';
  }
}
