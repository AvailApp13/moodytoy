import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/widgets/mood_indicator.dart';
import '../../shared/widgets/user_avatar.dart';
import '../auth/auth_controller.dart';
import '../friends/friends_controller.dart';
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
  late final FriendsController _friendsCtrl;

  final List<String> _moodFilters = [
    AppStrings.filterAll,
    AppStrings.moodCoffeeBreak,
    AppStrings.moodGamer,
    AppStrings.moodDating,
    AppStrings.moodWalk,
    AppStrings.moodSport,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(PeopleController());
    _auth = Get.find<AuthController>();
    _friendsCtrl = Get.find<FriendsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMoodFilter(),
            Expanded(
              child: Obx(() => _ctrl.isMapView.value
                  ? _buildMapView()
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
                  return Text('$count человек рядом',
                      style: Theme.of(context).textTheme.bodySmall);
                }),
              ],
            ),
          ),
          Obx(() {
            final isListMode = !_ctrl.isMapView.value;
            return Row(children: [
              if (!isListMode)
                _headerButton(AppStrings.listView, Icons.list,
                    () => _ctrl.toggleMapView()),
              if (isListMode)
                _headerButton(AppStrings.mapView, Icons.map_outlined,
                    () => _ctrl.toggleMapView()),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _buildMoodFilter() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _moodFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final mood = _moodFilters[i];
          final isSelected = _ctrl.selectedMoodFilter.value == mood;
          return _MoodFilterChip(
            label: mood,
            isSelected: isSelected,
            onTap: () => _ctrl.setMoodFilter(mood == AppStrings.filterAll ? null : mood),
          );
        },
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

  Widget _buildMapView() {
    return Stack(
      children: [
        Container(color: const Color(0xFF1A1A2E)),
        Center(child: _PulsingDot()),
        Obx(() => Stack(
          children: _ctrl.filteredUsers.take(10).map((u) => _buildMapMarker(u)).toList(),
        )),
      ],
    );
  }

  Widget _buildListView() {
    return PeopleList(controller: _ctrl, friendsCtrl: _friendsCtrl);
  }

  Widget _buildMapMarker(UserModel user) {
    // Заглушка - просто случайные позиции для демонстрации
    final positions = [
      const Offset(0.25, 0.3), const Offset(0.65, 0.35),
      const Offset(0.15, 0.6), const Offset(0.75, 0.65), const Offset(0.5, 0.2),
    ];
    final idx = _ctrl.filteredUsers.indexOf(user) % positions.length;
    final pos = positions[idx];
    return Positioned(
      left: MediaQuery.of(context).size.width * pos.dx - 20,
      top: MediaQuery.of(context).size.height * 0.6 * pos.dy,
      child: GestureDetector(
        onTap: () => _showUserBottomSheet(user),
        child: UserAvatarWidget(user: user, size: 40, showMoodRing: true),
      ),
    );
  }

  void _showUserBottomSheet(UserModel user) {
    Get.bottomSheet(
      _UserDetailSheet(user: user, friendsCtrl: _friendsCtrl),
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }
}

class _MoodFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Mood? mood;
    switch (label) {
      case AppStrings.moodCoffeeBreak: mood = Mood.coffeeBreak; break;
      case AppStrings.moodGamer: mood = Mood.gamer; break;
      case AppStrings.moodDating: mood = Mood.dating; break;
      case AppStrings.moodWalk: mood = Mood.walk; break;
      case AppStrings.moodSport: mood = Mood.sport; break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (mood?.color ?? AppColors.primary).withOpacity(0.2)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (mood?.color ?? AppColors.primary)
                : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mood != null)
              Icon(mood.icon, size: 14, color: mood.color),
            if (mood != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected 
                    ? (mood?.color ?? AppColors.primary)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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

class _UserDetailSheet extends StatelessWidget {
  final UserModel user;
  final FriendsController friendsCtrl;

  const _UserDetailSheet({required this.user, required this.friendsCtrl});

  @override
  Widget build(BuildContext context) {
    final status = friendsCtrl.getFriendStatusWith(user.id);
    final isIncoming = friendsCtrl.incomingRequests.any((r) => r.requesterId == user.id);

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
            ],
          )),
        ]),
        const SizedBox(height: 16),
        if (user.bio != null && user.bio!.isNotEmpty)
          Text(user.bio!, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        _buildActionButton(context, status, isIncoming),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildActionButton(BuildContext context, dynamic status, bool isIncoming) {
    if (status == FriendshipStatus.accepted) {
      // Уже друзья - кнопка "Написать"
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // Открыть чат с другом
            Get.back();
            Get.snackbar('Чат', 'Открывается чат с ${user.name}');
          },
          icon: const Icon(Icons.chat),
          label: const Text('Написать'),
        ),
      );
    } else if (isIncoming) {
      // Входящий запрос - кнопки Принять/Отклонить
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Найти запрос и принять
                final request = friendsCtrl.incomingRequests.firstWhere(
                  (r) => r.requesterId == user.id,
                );
                friendsCtrl.acceptRequest(request.id, user.id);
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: const Text('Принять'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                final request = friendsCtrl.incomingRequests.firstWhere(
                  (r) => r.requesterId == user.id,
                );
                friendsCtrl.declineRequest(request.id);
                Get.back();
              },
              child: const Text('Отклонить'),
            ),
          ),
        ],
      );
    } else if (status == FriendshipStatus.pending) {
      // Исходящий запрос отправлен
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: null,
          child: const Text('Запрос отправлен'),
        ),
      );
    } else {
      // Нет статуса - отправить запрос
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            friendsCtrl.sendRequest(user.id);
            Get.back();
            Get.snackbar('Дружба', 'Запрос отправлен пользователю ${user.name}');
          },
          icon: const Icon(Icons.person_add),
          label: const Text('+ Друг'),
        ),
      );
    }
  }
}
