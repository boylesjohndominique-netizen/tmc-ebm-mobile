import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/floating_nav_bar.dart';
import '../borrowing/my_requests_screen.dart';
import '../equipment/equipment_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    EquipmentListScreen(),
    MyRequestsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  void goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<AppState>().unreadCount;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onTap: goToTab,
        unreadCount: unread,
      ),
    );
  }
}
