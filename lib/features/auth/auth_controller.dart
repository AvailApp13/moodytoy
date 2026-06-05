import 'package:get/get.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/mock_data.dart';
import '../../data/models/user_model.dart';

class AuthController extends GetxController {
  final currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  void _loadUser() {
    var user = LocalStorageService.getCurrentUser();
    if (user == null) {
      user = MockData.defaultCurrentUser();
      LocalStorageService.saveCurrentUser(user);
    }
    currentUser.value = user;
  }

  Future<void> updateUser(UserModel user) async {
    await LocalStorageService.saveCurrentUser(user);
    currentUser.value = user;
  }

  Future<void> updateMood(Mood mood) async {
    final user = currentUser.value;
    if (user == null) return;
    await updateUser(user.copyWith(mood: mood));
  }

  Future<void> toggleLocation(bool value) async {
    final user = currentUser.value;
    if (user == null) return;
    await updateUser(user.copyWith(locationEnabled: value));
  }

  Future<void> updateName(String name) async {
    final user = currentUser.value;
    if (user == null) return;
    await updateUser(user.copyWith(name: name));
  }

  Future<void> updateBio(String bio) async {
    final user = currentUser.value;
    if (user == null) return;
    await updateUser(user.copyWith(bio: bio));
  }

  Future<void> updateBirthDate(DateTime date) async {
    final user = currentUser.value;
    if (user == null) return;
    await updateUser(user.copyWith(birthDate: date));
  }
}
