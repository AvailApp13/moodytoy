import 'package:get/get.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/mock_data.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/supabase_repository.dart';

class AuthController extends GetxController {
  final currentUser = Rxn<UserModel>();
  final isSupabaseUser = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Пробуем Supabase
    try {
      final user = await SupabaseRepository.getOrCreateTestUser();
      if (user.id != 'local_user') {
        currentUser.value = user;
        isSupabaseUser.value = true;
        await LocalStorageService.saveCurrentUser(user);
        return;
      }
    } catch (_) {}

    // Fallback — локальный
    var user = LocalStorageService.getCurrentUser();
    user ??= MockData.defaultCurrentUser();
    await LocalStorageService.saveCurrentUser(user);
    currentUser.value = user;
  }

  Future<void> updateUser(UserModel user) async {
    await LocalStorageService.saveCurrentUser(user);
    currentUser.value = user;

    if (isSupabaseUser.value) {
      await SupabaseRepository.updateUser(user.id, {
        'name': user.name,
        'bio': user.bio,
        'city': user.city,
        'avatar_emoji': user.avatarEmoji,
        'avatar_url': user.avatarUrl,
        'mood': user.mood?.value,
        'location_enabled': user.locationEnabled,
        'birth_date': user.birthDate?.toIso8601String(),
      });
    }
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

  Future<void> updateCity(String city) async {
    final user = currentUser.value;
    if (user == null) return;
    await updateUser(user.copyWith(city: city));
  }

  Future<void> updateBirthDate(DateTime date) async {
    final user = currentUser.value;
    if (user == null) return;
    await updateUser(user.copyWith(birthDate: date));
  }

  Future<void> addTestToy() async {
    final user = currentUser.value;
    if (user == null) return;
    if (isSupabaseUser.value) {
      await SupabaseRepository.addTestToy(user.id);
    }
  }
}
