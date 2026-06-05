import 'package:get/get.dart';
import '../../core/services/mock_data.dart';
import '../../data/models/user_model.dart';

class PeopleController extends GetxController {
  final allUsers = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final selectedMood = Rxn<Mood>(); // null = все
  final isListMode = true.obs; // true=список, false=карта

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
      filteredUsers.value = allUsers
          .where((u) => u.mood == selectedMood.value)
          .toList();
    }
    // Сортировка по расстоянию
    filteredUsers.sort((a, b) =>
        (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999));
  }

  void toggleView() {
    isListMode.value = !isListMode.value;
  }

  String formatDistance(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) {
      final rounded = (meters / 10).round() * 10;
      return '~${rounded.toInt()}м';
    }
    return '~${(meters / 1000).toStringAsFixed(1)}км';
  }
}
