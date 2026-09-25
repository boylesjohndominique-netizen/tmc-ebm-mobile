import 'package:flutter/material.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/borrowing/my_requests_screen.dart';
import '../screens/dashboard/main_nav_screen.dart';
import '../screens/equipment/equipment_list_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/returns/borrowed_equipment_screen.dart';
import '../screens/splash/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const main = '/main';
  static const equipment = '/equipment';
  static const myRequests = '/my-requests';
  static const borrowedEquipment = '/borrowed-equipment';
  static const history = '/history';
  static const notifications = '/notifications';

  static Map<String, WidgetBuilder> get map => {
        splash: (_) => const SplashScreen(),
        onboarding: (_) => const OnboardingScreen(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        forgotPassword: (_) => const ForgotPasswordScreen(),
        main: (_) => const MainNavScreen(),
        equipment: (_) => const EquipmentListScreen(),
        myRequests: (_) => const MyRequestsScreen(),
        borrowedEquipment: (_) => const BorrowedEquipmentScreen(),
        history: (_) => const HistoryScreen(),
        notifications: (_) => const NotificationsScreen(),
      };
}
