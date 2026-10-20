import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/liquid_glass.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _controller, curve: AppMotion.springy);
    _fade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOut));
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.markOnboardingSeen();

      // Session-aware routing: a restored login goes straight to the app,
      // everyone else sees onboarding → login.
      if (appState.isLoggedIn) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/main', (route) => false);
      } else if (appState.onboardingSeen) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        Navigator.of(context).pushNamed('/onboarding');
      }
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
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.premiumGradient),
        child: Stack(
          children: [
            // Ambient light pools.
            Positioned(
              top: -120,
              right: -90,
              child: _Glow(
                size: 340,
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -110,
              child: _Glow(
                size: 380,
                color: AppColors.gold.withValues(alpha: 0.18),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _scale,
                          child: GlassPanel(
                            blur: 24,
                            radius: 36,
                            padding: const EdgeInsets.all(10),
                            tint: Colors.white.withValues(alpha: 0.24),
                            borderColor: Colors.white.withValues(alpha: 0.40),
                            shadows: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 36,
                                offset: const Offset(0, 16),
                              ),
                            ],
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.asset(
                                  'assets/images/tmc_logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _fade,
                          child: Column(
                            children: [
                              const Text(
                                'TMCEBMS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Trinidad Municipal College',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 22),
                              GlassPanel(
                                blur: 14,
                                radius: AppRadius.pill,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 9),
                                tint: Colors.white.withValues(alpha: 0.16),
                                borderColor:
                                    Colors.white.withValues(alpha: 0.28),
                                shadows: const [],
                                child: const Text(
                                  'Smart Equipment Borrowing & Tracking',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 56),
                        FadeTransition(
                          opacity: _fade,
                          child: const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
