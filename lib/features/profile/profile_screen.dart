import '../../shared/widgets/translated_text.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/language_service.dart';
import '../language/language_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../auth/auth_controller.dart';
import '../chats/chats_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final user = auth.currentUser.value;
          if (user == null) return const Center(child: CircularProgressIndicator());
          return _buildContent(context, user, auth);
        }),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, UserModel user, AuthController auth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(ctx, user, auth),
        const SizedBox(height: 16),
        _buildInfoCard(ctx, user, auth),
        const SizedBox(height: 12),
        _buildMoodCard(ctx, user, auth),
        const SizedBox(height: 12),
        _buildLocationToggle(user, auth),
        const SizedBox(height: 12),
        _buildSettingsButton(ctx, auth),
        const SizedBox(height: 16),
        _buildKeyfobButton(ctx),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader(BuildContext ctx, UserModel user, AuthController auth) {
    return Row(children: [
      GestureDetector(
        onTap: () => _editAvatar(ctx, auth),
        child: Stack(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.5),
            ),
            child: Center(child: Text(user.avatarEmoji ?? '😊',
                style: const TextStyle(fontSize: 36))),
          ),
          Positioned(right: 0, bottom: 0,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: const Icon(Icons.edit, size: 13, color: Colors.white),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.name,
              style: const TextStyle(color: Colors.white,
                  fontSize: 22, fontWeight: FontWeight.bold)),
          if (user.city != null || user.age != null)
            Text(
              [if (user.city != null) user.city!, if (user.age != null) '${user.age} лет'].join(' · '),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
        ],
      )),
      GestureDetector(
        onTap: () => Get.to(() => const _SettingsScreen()),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: const Icon(Icons.settings_outlined,
              size: 20, color: AppColors.textSecondary),
        ),
      ),
    ]);
  }

  Widget _buildInfoCard(BuildContext ctx, UserModel user, AuthController auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.cake_outlined, 'Возраст', '${user.age ?? '?'} лет'),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, 'Город', user.city ?? 'Не указан'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _editBio(ctx, auth, user),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.edit_note_outlined,
                      size: 16, color: AppColors.textHint),
                  SizedBox(width: 6),
                  Text('О себе',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                ]),
                const SizedBox(height: 4),
                TranslatedText(
                  user.bio?.isNotEmpty == true ? user.bio : null,
                  style: TextStyle(
                    color: user.bio?.isNotEmpty == true
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textHint),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(
          color: AppColors.textHint, fontSize: 13)),
      Text(value, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 13)),
    ]);
  }

  Widget _buildMoodCard(BuildContext ctx, UserModel user, AuthController auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Текущее настроение',
              style: TextStyle(color: AppColors.textSecondary,
                  fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: Mood.values.map((mood) {
              final isActive = user.mood == mood;
              return GestureDetector(
                onTap: () async {
                  await auth.updateMood(mood);
                  // Синхронизация с чатами — уже делается через updateMood
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? mood.color.withOpacity(0.25)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? mood.color : AppColors.border,
                      width: isActive ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(mood.label,
                        style: TextStyle(
                          color: isActive ? mood.color : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationToggle(UserModel user, AuthController auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.location_on_outlined,
            size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        const Expanded(child: Text('Показывать меня на карте',
            style: TextStyle(color: Colors.white, fontSize: 14))),
        Switch(
          value: user.locationEnabled,
          onChanged: (val) => auth.toggleLocation(val),
          activeColor: AppColors.primary,
        ),
      ]),
    );
  }

  Widget _buildSettingsButton(BuildContext ctx, AuthController auth) {
    return GestureDetector(
      onTap: () => Get.to(() => const _SettingsScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.settings_outlined,
              size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Настройки профиля',
              style: TextStyle(color: Colors.white, fontSize: 14))),
          const Icon(Icons.chevron_right,
              size: 20, color: AppColors.textHint),
        ]),
      ),
    );
  }

  Widget _buildKeyfobButton(BuildContext ctx) {
    return GestureDetector(
      onTap: () => Get.snackbar('🎮 Брелок', 'Функция в разработке',
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.surface,
          colorText: Colors.white),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🧸', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Подключить игрушку',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text('nRF52832 · BLE 5.0 · OTA',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
            Spacer(),
            Icon(Icons.bluetooth, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  void _editBio(BuildContext ctx, AuthController auth, UserModel user) {
    final controller = TextEditingController(text: user.bio ?? '');
    Get.dialog(AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('О себе', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLength: 200,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Расскажи о себе...',
            hintStyle: TextStyle(color: AppColors.textHint),
            counterStyle: TextStyle(color: AppColors.textHint),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Отмена', style: TextStyle(color: AppColors.textHint)),
        ),
        ElevatedButton(
          onPressed: () {
            auth.updateBio(controller.text.trim());
            Get.back();
          },
          child: const Text('Сохранить'),
        ),
      ],
    ));
  }

  void _editAvatar(BuildContext ctx, AuthController auth) {
    final emojis = ['😊', '🧑', '👱‍♀️', '🧔', '👩', '🏃', '👩‍🦰', '🌸', '😎', '🤩', '🦊', '🐼'];
    Get.dialog(AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Выбери аватар', style: TextStyle(color: Colors.white)),
      content: Wrap(
        spacing: 12, runSpacing: 12,
        children: emojis.map((e) => GestureDetector(
          onTap: () {
            final user = auth.currentUser.value;
            if (user != null) {
              auth.updateUser(user.copyWith(avatarEmoji: e));
            }
            Get.back();
          },
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
          ),
        )).toList(),
      ),
    ));
  }
}

// ── Экран настроек ────────────────────────────────────────
class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  late TextEditingController _nameCtrl;
  late AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    _nameCtrl = TextEditingController(
        text: _auth.currentUser.value?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: Colors.white),
        title: const Text('Настройки', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Профиль'),
          _settingItem(
            title: 'settings_name'.tr,
            subtitle: _auth.currentUser.value?.name ?? '',
            icon: Icons.person_outline,
            onTap: () => _editName(context),
          ),
          _settingItem(
            title: 'settings_birthday'.tr,
            subtitle: _auth.currentUser.value?.birthDate != null
                ? '${_auth.currentUser.value!.birthDate!.day}.'
                  '${_auth.currentUser.value!.birthDate!.month}.'
                  '${_auth.currentUser.value!.birthDate!.year}'
                : 'Не указана',
            icon: Icons.cake_outlined,
            onTap: () => _editBirthDate(context),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Аккаунт'),
          _settingItem(
            title: 'settings_login'.tr,
            subtitle: 'settings_wip'.tr,
            icon: Icons.alternate_email,
            onTap: () => Get.snackbar('', 'Функция в разработке',
                backgroundColor: AppColors.surface, colorText: Colors.white),
          ),
          _settingItem(
            title: 'settings_password'.tr,
            subtitle: 'settings_wip'.tr,
            icon: Icons.lock_outline,
            onTap: () => Get.snackbar('', 'wip_feature'.tr,
                backgroundColor: AppColors.surface, colorText: Colors.white),
          ),
          const SizedBox(height: 16),
          _sectionTitle('settings_language'.tr),
          _LanguageSettingItem(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(text.toUpperCase(),
        style: const TextStyle(color: AppColors.textHint,
            fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
  );

  Widget _settingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              Text(subtitle, style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
            ],
          )),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }

  void _editName(BuildContext context) {
    Get.dialog(AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Имя', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _nameCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Введите имя',
          hintStyle: TextStyle(color: AppColors.textHint),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(),
            child: const Text('Отмена', style: TextStyle(color: AppColors.textHint))),
        ElevatedButton(
          onPressed: () {
            _auth.updateName(_nameCtrl.text.trim());
            Get.back();
            setState(() {});
          },
          child: const Text('Сохранить'),
        ),
      ],
    ));
  }

  void _editBirthDate(BuildContext context) async {
    final current = _auth.currentUser.value?.birthDate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      await _auth.updateBirthDate(picked);
      setState(() {});
    }
  }
}

// ── Виджет выбора языка в настройках ─────────────────────
class _LanguageSettingItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: LanguageService.supportedLocales.map((lang) {
        final currentCode = LanguageService.getSavedLanguage() ?? 'ru';
        final isSelected = currentCode == lang['code'];
        return GestureDetector(
          onTap: () async {
            await LanguageService.setLanguage(lang['code']!, lang['country']!);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(children: [
              Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(lang['name']!,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 20),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
