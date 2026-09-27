import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'routes.dart';
import 'theme.dart';

class TmcebmsApp extends StatelessWidget {
  const TmcebmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, appState, _) {
          AppColors.isDark = appState.isDarkMode;
          return MaterialApp(
            title: 'TMCEBMS',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
