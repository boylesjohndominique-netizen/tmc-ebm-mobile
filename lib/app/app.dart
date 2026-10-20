import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'app_navigator.dart';
import 'ban_guard.dart';
import 'routes.dart';
import 'theme.dart';

class TmcebmsApp extends StatelessWidget {
  const TmcebmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Selector<AppState, bool>(
        selector: (_, appState) => appState.isDarkMode,
        builder: (context, isDarkMode, _) {
          AppColors.isDark = isDarkMode;
          return MaterialApp(
            title: 'TMCEBMS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            navigatorKey: appNavigatorKey,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            builder: (context, child) =>
                BanGuard(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
