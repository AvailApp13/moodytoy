import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../shared/widgets/translated_text.dart';
import '../../shared/widgets/user_profile_sheet.dart';
import '../friends/friends_controller.dart';
import '../auth/auth_controller.dart';
import 'people_controller.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});
  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  late final PeopleController _ctrl;
  late final FriendsController _friends;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(PeopleController());
    _friends = Get.find<FriendsController>();
    _auth = Get.find<AuthController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildMoodFilters(),
          Expanded(child: Obx(() => _ctrl.isListMode.value
              ? _buildList() : _buildMap())),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('people_title'.tr,
                style: Theme.of(context).textTheme.headlineMedium),
            Obx(() => Text(
              '${_ctrl.filteredUsers.length} ${'people_nearby'.tr}',
              style: Theme.of(context).textTheme.bodySmall,
            )),
          ],
        )),
        Obx(() => GestureDetector(
          onTap: _ctrl.toggleView,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_ctrl.isListMode.value ? Icons.map_outlined : Icons.list,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_ctrl.isListMode.value ? 'map_btn'.tr : 'list_btn'.tr,
                  style: Theme.of(context).textTheme.labelMedium),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _buildMoodFilters() {
    final moods = [null, ...Mood.values];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final mood = moods[i];
          return Obx(() {
            final selected = _ctrl.selectedMood.value == mood;
            return GestureDetector(
              onTap: () => _ctrl.setFilter(mood),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? (mood?.color ?? AppColors.primary).withOpacity(0.2)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? (mood?.color ?? AppColors.primary) : AppColors.border,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (mood != null) ...[
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(color: mood.color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    mood == null ? 'filter_all'.tr : mood.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? (mood?.color ?? AppColors.primary) : AppColors.textSecondary,
                    ),
                  ),
                ]),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      if (_ctrl.filteredUsers.isEmpty) {
        return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('😔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('people_nobody'.tr, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _ctrl.filteredUsers.length,
        itemBuilder: (_, i) => _PeopleCard(
          user: _ctrl.filteredUsers[i],
          ctrl: _ctrl,
          friends: _friends,
          onTap: () => _showUserCard(_ctrl.filteredUsers[i]),
        ),
      );
    });
  }

  Widget _buildMap() {
    return Stack(children: [
      Container(color: const Color(0xFF1A1A2E)),
      CustomPaint(size: Size.infinite, painter: _GridPainter()),
      Center(child: _PulsingDot()),
      Obx(() => Stack(
        children: _ctrl.filteredUsers.take(8).toList().asMap().entries
            .map((e) => _buildMapMarker(e.value, e.key)).toList(),
      )),
      Positioned(
        bottom: 16, left: 0, right: 0,
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
          child: Text('map_label'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        )),
      ),
    ]);
  }

  Widget _buildMapMarker(UserModel user, int index) {
    final positions = [
      const Offset(0.2, 0.25), const Offset(0.7, 0.3),
      const Offset(0.15, 0.55), const Offset(0.75, 0.6),
      const Offset(0.5, 0.15), const Offset(0.85, 0.45),
      const Offset(0.3, 0.7), const Offset(0.6, 0.75),
    ];
    final pos = positions[index % positions.length];
    return Positioned(
      left: MediaQuery.of(context).size.width * pos.dx - 24,
      top: MediaQuery.of(context).size.height * 0.55 * pos.dy,
      child: GestureDetector(
        onTap: () => _showUserCard(user),
        child: Column(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: user.mood?.color.withOpacity(0.3) ?? AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: user.mood?.color ?? AppColors.primary, width: 2),
            ),
            child: Center(child: Text(user.avatarEmoji ?? '👤',
                style: const TextStyle(fontSize: 22))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: TranslatedText(user.name,
                style: const TextStyle(fontSize: 10, color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  void _showUserCard(UserModel user) {
    showUserProfileSheet(user);
  }
}

class _PeopleCard extends StatelessWidget {
  final UserModel user;
  final PeopleController ctrl;
  final FriendsController friends;
  final VoidCallback onTap;

  const _PeopleCard({required this.user, required this.ctrl,
      required this.friends, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(children: [
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: user.mood?.color ?? AppColors.border, width: 2),
              ),
              child: Center(child: Text(user.avatarEmoji ?? '👤',
                  style: const TextStyle(fontSize: 24))),
            ),
            if (user.isOnline) Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 15, height: 15,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                TranslatedText(user.name, style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Text(', ${user.age ?? '?'}', style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              if (user.mood != null) Row(children: [
                Text(user.mood!.emoji, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(user.mood!.label,
                    style: TextStyle(color: user.mood!.color, fontSize: 12)),
              ]),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(ctrl.formatDistance(user.distanceMeters),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            GetBuilder<FriendsController>(
                builder: (fc) => _FriendButton(userId: user.id, friends: fc)),
          ]),
        ]),
      ),
    );
  }
}

class _FriendButton extends StatelessWidget {
  final String userId;
  final FriendsController friends;
  const _FriendButton({required this.userId, required this.friends});

  @override
  Widget build(BuildContext context) {
    final status = friends.getStatus(userId);
    switch (status) {
      case FriendStatus.friend:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('btn_friend_label'.tr,
              style: const TextStyle(color: AppColors.success, fontSize: 11)),
        );
      case FriendStatus.outgoing:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.textHint.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('btn_request_sent'.tr,
              style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
        );
      case FriendStatus.incoming:
        return GestureDetector(
          onTap: () => friends.acceptRequest(userId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success, width: 1),
            ),
            child: Text('btn_accept'.tr,
                style: const TextStyle(color: AppColors.success, fontSize: 11)),
          ),
        );
      case FriendStatus.none:
        return GestureDetector(
          onTap: () => friends.sendRequest(userId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 1),
            ),
            child: Text('btn_friend'.tr,
                style: const TextStyle(color: AppColors.primary, fontSize: 11)),
          ),
        );
    }
  }
}

class _UserBottomSheet extends StatelessWidget {
  final UserModel user;
  final FriendsController friends;
  final PeopleController ctrl;
  const _UserBottomSheet({required this.user, required this.friends, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: user.mood?.color.withOpacity(0.2) ?? AppColors.surfaceVariant,
              shape: BoxShape.circle,
              border: Border.all(color: user.mood?.color ?? AppColors.border, width: 2),
            ),
            child: Center(child: Text(user.avatarEmoji ?? '👤',
                style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              TranslatedText(user.name, style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(', ${user.age ?? '?'}', style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            if (user.mood != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 8, height: 8,
                    decoration: BoxDecoration(color: user.mood!.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${user.mood!.emoji} ${user.mood!.label}',
                    style: TextStyle(color: user.mood!.color, fontSize: 13)),
              ]),
            ],
            if (user.distanceMeters != null)
              Text(ctrl.formatDistance(user.distanceMeters),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ])),
        ]),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: TranslatedText(user.bio,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: GetBuilder<FriendsController>(
          builder: (fc) => _buildActionButton(context, fc),
        )),
      ]),
    );
  }

  Widget _buildActionButton(BuildContext context, FriendsController fc) {
    final status = fc.getStatus(user.id);
    if (status == FriendStatus.friend) {
      return ElevatedButton.icon(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.chat_bubble_outline, size: 16),
        label: Text('btn_write'.tr),
      );
    }
    if (status == FriendStatus.outgoing) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceVariant),
        child: Text('btn_request_sent'.tr),
      );
    }
    if (status == FriendStatus.incoming) {
      return ElevatedButton(
        onPressed: () { fc.acceptRequest(user.id); Get.back(); },
        child: Text('btn_accept_request'.tr),
      );
    }
    return ElevatedButton.icon(
      onPressed: () { fc.sendRequest(user.id); Get.back(); },
      icon: const Icon(Icons.person_add_outlined, size: 16),
      label: Text('btn_add_friend'.tr),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scale = Tween<double>(begin: 1, end: 2.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 40, height: 40, child: Stack(alignment: Alignment.center, children: [
      AnimatedBuilder(animation: _scale, builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(width: 16, height: 16,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle)),
      )),
      Container(width: 14, height: 14, decoration: BoxDecoration(
        color: AppColors.primary, shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      )),
    ]));
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.border.withOpacity(0.3)..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}
