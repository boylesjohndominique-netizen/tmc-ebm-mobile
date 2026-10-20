import 'package:flutter/material.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/borrowing/my_requests_screen.dart';
import '../screens/dashboard/main_nav_screen.dart';
import '../screens/equipment/equipment_list_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/returns/borrowed_equipment_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'motion.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';
  static const main = '/main';
  static const equipment = '/equipment';
  static const myRequests = '/my-requests';
  static const borrowedEquipment = '/borrowed-equipment';
  static const history = '/history';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return AppPageRoute(
          builder: (_) => const SplashScreen(),
          settings: routeSettings,
        );
      case onboarding:
        return AppPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: routeSettings,
        );
      case login:
        return AppPageRoute(
          builder: (_) => const LoginScreen(),
          settings: routeSettings,
        );
      case register:
        return AppPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: routeSettings,
        );
      case verifyEmail:
        final email = (routeSettings.arguments is String)
            ? routeSettings.arguments as String
            : '';
        return AppPageRoute(
          builder: (_) => VerifyEmailScreen(email: email),
          settings: routeSettings,
        );
      case forgotPassword:
        return AppPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: routeSettings,
        );
      case main:
        return AppPageRoute(
          builder: (_) => const MainNavScreen(),
          settings: routeSettings,
        );
      case equipment:
        return AppPageRoute(
          builder: (_) => const EquipmentListScreen(),
          settings: routeSettings,
        );
      case myRequests:
        return AppPageRoute(
          builder: (_) => const MyRequestsScreen(),
          settings: routeSettings,
        );
      case borrowedEquipment:
        return AppPageRoute(
          builder: (_) => const BorrowedEquipmentScreen(),
          settings: routeSettings,
        );
      case history:
        return AppPageRoute(
          builder: (_) => const HistoryScreen(),
          settings: routeSettings,
        );
      case notifications:
        return AppPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: routeSettings,
        );
      case profile:
        return AppPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: routeSettings,
        );
      case settings:
        return AppPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: routeSettings,
        );
      default:
        return AppPageRoute(
          builder: (_) => const SplashScreen(),
          settings: routeSettings,
        );
    }
  }
}
