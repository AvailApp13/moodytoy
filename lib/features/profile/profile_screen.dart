import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/widgets/mood_indicator.dart';
import '../../shared/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import 'keyfob_screen.dart';
import 'ble_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    Get.put(BleController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final user = auth.currentUser.value;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(context, user, auth);
        }),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, UserModel user, AuthController auth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Шапка профиля ──────────────────────────────────
        _buildProfileHeader(context, user),
        const SizedBox(height: 16),

        // ── Информация ─────────────────────────────────────
        _buildInfoCard(context, user),
        const SizedBox(height: 12),

        // ── Настроение ─────────────────────────────────────
        _buildMoodCard(context, user),
        const SizedBox(height: 12),

        // ── Настройки ──────────────────────────────────────
        _buildSettingsCard(context, auth),
        const SizedBox(height: 16),

        // ── Кнопка брелока ─────────────────────────────────
        _buildKeyfobButton(context),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user) {
    return Row(
      children: [
        ProfileAvatarWidget(user: user, size: 72),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: Theme.of(context).textTheme.headlineLarge),
              if (user.city != null || user.age != null)
                Text(
                  [
                    if (user.city != null) user.city,
                    if (user.age != null) '${user.age} лет',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (user.hasKeyfob)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.bluetooth_connected,
                          size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Брелок привязан',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Get.to(() => const SettingsScreen()),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, UserModel user) {
    return _card(
      context,
      children: [
        if (user.bio != null && user.bio!.isNotEmpty)
          _infoRow(context, Icons.info_outline, AppStrings.about, user.bio!),
        if (user.city != null)
          _infoRow(context, Icons.location_city_outlined, AppStrings.city, user.city!),
        if (user.height != null)
          _infoRow(context, Icons.height, AppStrings.height, '${user.height} см'),
        if (user.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: user.tags
                .map((tag) => Chip(
                      label: Text(tag,
                          style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMoodCard(BuildContext context, UserModel user) {
    return _card(
      context,
      children: [
        Text('Настроение', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        MoodSelector(
          selected: user.mood,
          onSelect: (mood) async {
            await UserRepository.updateMood(mood);
            await Get.find<AuthController>().refreshProfile();
          },
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, AuthController auth) {
    return _card(
      context,
      children: [
        _settingsRow(
          context,
          Icons.person_outline,
          AppStrings.editProfile,
          () {},
        ),
        _divider(),
        _settingsRow(
          context,
          Icons.notifications_outlined,
          AppStrings.notifications,
          () {},
        ),
        _divider(),
        _settingsRow(
          context,
          Icons.help_outline,
          AppStrings.support,
          () {},
        ),
        _divider(),
        _settingsRow(
          context,
          Icons.logout,
          AppStrings.logout,
          () => _confirmLogout(context, auth),
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildKeyfobButton(BuildContext context) {
    final bleCtrl = Get.find<BleController>();
    return Obx(() {
      final isConnected = bleCtrl.isConnected.value;
      final mac = bleCtrl.connectedMac.value;

      return GestureDetector(
        onTap: () => Get.to(() => const KeyfobScreen()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.primaryDark.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? AppStrings.manageKeyfob
                          : AppStrings.connectKeyfob,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      isConnected
                          ? 'ID: $mac · Батарея: ${bleCtrl.batteryLevel.value ?? '--'}%'
                          : 'nRF52832 · BLE 5.2 · OTA',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      );
    });
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text('$label: ',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textHint)),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: color)),
            const Spacer(),
            if (color == null)
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 1);

  void _confirmLogout(BuildContext context, AuthController auth) {
    Get.dialog(AlertDialog(
      title: const Text('Выйти?'),
      content: const Text('Вы уверены что хотите выйти?'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Отмена')),
        TextButton(
          onPressed: () {
            Get.back();
            auth.logout();
          },
          child: const Text('Выйти', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ));
  }
}

// ── Settings Screen ───────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: Obx(() {
        final user = auth.currentUser.value;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SettingsToggle(
              label: AppStrings.hideProfile,
              value: user?.profilePrivate ?? false,
              onChanged: (val) async {
                await UserRepository.updateProfile({'profile_private': val});
                await auth.refreshProfile();
              },
            ),
          ],
        );
      }),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
