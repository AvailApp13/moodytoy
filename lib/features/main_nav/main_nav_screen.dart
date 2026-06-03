import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../people/people_screen.dart';
import '../collection/collection_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';
import '../friends/friends_controller.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PeopleScreen(),
    CollectionScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Get.put(FriendsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: AppStrings.tabPeople,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.toys_outlined),
              activeIcon: Icon(Icons.toys),
              label: AppStrings.tabCollection,
            ),
            BottomNavigationBarItem(
              icon: GetX<FriendsController>(
                builder: (c) => Badge(
                  isLabelVisible: c.incomingRequests.isNotEmpty,
                  label: Text('${c.incomingRequests.length}'),
                  child: const Icon(Icons.people_alt_outlined),
                ),
              ),
              activeIcon: const Icon(Icons.people_alt),
              label: AppStrings.tabFriends,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppStrings.tabProfile,
            ),
          ],
        ),
      ),
    );
  }
}
