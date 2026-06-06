import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../people/people_screen.dart';
import '../collection/collection_screen.dart';
import '../chats/chats_screen.dart';
import '../chats/chats_controller.dart';
import '../friends/friends_screen.dart';
import '../friends/friends_controller.dart';
import '../profile/profile_screen.dart';

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
    ChatsScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Get.put(FriendsController());
    Get.put(ChatsController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.navSelected,
          unselectedItemColor: AppColors.navUnselected,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: 'tab_people'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.toys_outlined),
              activeIcon: const Icon(Icons.toys),
              label: 'tab_collection'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble_outline),
              activeIcon: const Icon(Icons.chat_bubble),
              label: 'tab_chats'.tr,
            ),
            BottomNavigationBarItem(
              icon: GetBuilder<FriendsController>(
                builder: (c) => Badge(
                  isLabelVisible: c.incomingRequests.isNotEmpty,
                  label: Text('${c.incomingRequests.length}',
                      style: const TextStyle(fontSize: 10)),
                  child: const Icon(Icons.people_alt_outlined),
                ),
              ),
              activeIcon: const Icon(Icons.people_alt),
              label: 'tab_friends'.tr,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: 'tab_me'.tr,
            ),
          ],
        ),
      ),
    );
  }
}
