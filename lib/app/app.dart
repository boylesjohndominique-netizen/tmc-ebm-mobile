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
      child: MaterialApp(
        title: 'TMCEBMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.map,
      ),
    );
  }
}
