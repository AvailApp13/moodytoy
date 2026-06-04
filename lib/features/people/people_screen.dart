import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/widgets/mood_indicator.dart';
import '../../shared/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import 'people_controller.dart';
import 'widgets/people_list.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late final PeopleController _ctrl;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(PeopleController());
    _auth = Get.find<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Obx(() => _ctrl.mapMode.value == 'split'
                  ? _buildSplitView()
                  : _buildListView()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.tabPeople,
                    style: Theme.of(context).textTheme.headlineMedium),
                Obx(() {
                  final count = _ctrl.filteredUsers.length;
                  return Text('$count человека рядом',
                      style: Theme.of(context).textTheme.bodySmall);
                }),
              ],
            ),
          ),
          Obx(() {
            final isListMode = _ctrl.mapMode.value == 'list';
            if (isListMode) {
              return _headerButton(AppStrings.mapView, Icons.map_outlined,
                  () => _ctrl.setMapMode('split'));
            }
            return Row(children: [
              _headerButton(AppStrings.meButton, Icons.my_location, () {}),
              const SizedBox(width: 8),
              _headerButton(AppStrings.listView, Icons.list,
                  () => _ctrl.setMapMode('list')),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _headerButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ]),
      ),
    );
  }

  Widget _buildSplitView() {
    return Column(children: [
      Expanded(child: _buildMapPlaceholder()),
      _buildLocationToggle(),
      Expanded(child: PeopleList(controller: _ctrl)),
    ]);
  }

  Widget _buildListView() {
    return Column(children: [
      _buildLocationToggle(),
      Expanded(child: PeopleList(controller: _ctrl)),
    ]);
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Stack(children: [
        CustomPaint(size: Size.infinite, painter: _MapGridPainter()),
        Center(child: _PulsingDot()),
        Positioned(
          right: 12, top: 12,
          child: Column(children: [
            _ZoomButton(icon: Icons.add, onTap: () {}),
            const SizedBox(height: 4),
            _ZoomButton(icon: Icons.remove, onTap: () {}),
          ]),
        ),
        Obx(() => Stack(
          children: _ctrl.filteredUsers.take(5).map((u) => _buildMapMarker(u)).toList(),
        )),
      ]),
    );
  }

  Widget _buildMapMarker(UserModel user) {
    final positions = [
      const Offset(0.25, 0.3), const Offset(0.65, 0.35),
      const Offset(0.15, 0.6), const Offset(0.75, 0.65), const Offset(0.5, 0.2),
    ];
    final idx = _ctrl.filteredUsers.indexOf(user) % positions.length;
    final pos = positions[idx];
    return Positioned(
      left: MediaQuery.of(context).size.width * pos.dx - 20,
      top: (MediaQuery.of(context).size.height * 0.4) * pos.dy,
      child: GestureDetector(
        onTap: () => _showUserMiniCard(user),
        child: UserAvatarWidget(user: user, size: 40, showMoodRing: true),
      ),
    );
  }

  Widget _buildLocationToggle() {
    return Obx(() {
      final user = _auth.currentUser.value;
      final hasKeyfob = user?.hasKeyfob ?? false;
      final isEnabled = user?.locationEnabled ?? false;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: GestureDetector(
          onTap: hasKeyfob
              ? () async {
                  await UserRepository.toggleLocation(!isEnabled);
                  await _auth.refreshProfile();
                }
              : () => Get.snackbar('🔑 Нужен брелок', AppStrings.needKeyfob,
                    duration: const Duration(seconds: 2)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isEnabled
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEnabled ? AppColors.primary : AppColors.border,
                width: isEnabled ? 1 : 0.5,
              ),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                isEnabled ? Icons.location_on : Icons.location_off_outlined,
                size: 16,
                color: isEnabled ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                isEnabled
                    ? AppStrings.visibleOnMap
                    : (!hasKeyfob ? AppStrings.needKeyfob : AppStrings.shareLocation),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }

  void _showUserMiniCard(UserModel user) {
    Get.bottomSheet(
      _UserMiniCard(user: user),
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _scale = Tween<double>(begin: 1, end: 2.5)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, height: 40,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _scale,
          builder: (_, __) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ]),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.3)
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _UserMiniCard extends StatelessWidget {
  final UserModel user;
  const _UserMiniCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          UserAvatarWidget(user: user, size: 56, showMoodRing: true),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.name}, ${user.age ?? '?'}',
                  style: Theme.of(context).textTheme.headlineSmall),
              if (user.mood != null) ...[
                const SizedBox(height: 4),
                MoodChip(mood: user.mood!),
              ],
              if (user.distanceMeters != null)
                Text(AppStrings.distance(user.distanceMeters!),
                    style: Theme.of(context).textTheme.bodySmall),
            ],
          )),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text(AppStrings.addFriend),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
