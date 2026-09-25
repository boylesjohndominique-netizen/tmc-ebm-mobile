import 'package:flutter/material.dart';
import '../../app/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeIn));
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) Navigator.of(context).pushReplacementNamed('/onboarding');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 64, color: AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  const Text(
                    'TMCEBMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trinidad Municipal College',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Smart Equipment Borrowing & Tracking',
                      style: TextStyle(color: AppColors.deepBlue, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 56),
            FadeTransition(
              opacity: _fade,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
