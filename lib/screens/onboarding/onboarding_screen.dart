import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String description;
  final Color tint;
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.tint,
  });
}

const _pages = [
  _OnboardPage(
    icon: Icons.search_rounded,
    title: 'Easy Equipment Access',
    description:
        'Browse all available school equipment — laptops, projectors, cameras, and more — right from your phone.',
    tint: AppColors.primary,
  ),
  _OnboardPage(
    icon: Icons.event_available_rounded,
    title: 'Simple Borrowing',
    description:
        'Request equipment in a few taps. Select your borrowing and return dates and submit instantly.',
    tint: AppColors.gold,
  ),
  _OnboardPage(
    icon: Icons.track_changes_rounded,
    title: 'Track Everything',
    description:
        'Monitor your requests, borrowed items, returns, history, and notifications — all in one place.',
    tint: AppColors.success,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  void _finish() {
    context.read<AppState>().markOnboardingSeen();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 14, 0),
                child: Row(
                  children: [
                    GlassPanel(
                      blur: 14,
                      radius: 16,
                      padding: const EdgeInsets.all(5),
                      shadows: AppShadows.soft,
                      child: Image.asset(
                        'assets/images/tmc_logo.png',
                        width: 34,
                        height: 34,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'TMCEBMS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Pressable(
                      onTap: _finish,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    // Scroll-safe: on very small screens content scrolls instead of overflowing.
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 18),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Illustration(icon: page.icon, tint: page.tint),
                            const SizedBox(height: 38),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 330),
                              child: Text(
                                page.title,
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 330),
                              child: Text(
                                page.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Page indicator ─────────────────────────────────────────
              GlassPanel(
                blur: 16,
                radius: AppRadius.pill,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shadows: AppShadows.soft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: AppMotion.responsive(
                          context, const Duration(milliseconds: 280)),
                      curve: AppMotion.emphasized,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.premiumGradient : null,
                        color: active
                            ? null
                            : AppColors.textTertiary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: CustomButton(
                  label: isLast ? 'Get Started' : 'Continue',
                  icon: isLast
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 340),
                        curve: AppMotion.emphasized,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _Illustration({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  tint.withValues(alpha: AppColors.isDark ? 0.26 : 0.18),
                  tint.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          GlassPanel(
            blur: 26,
            strong: true,
            radius: 64,
            padding: const EdgeInsets.all(4),
            shadows: AppShadows.floating,
            child: Container(
              width: 156,
              height: 156,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tint.withValues(alpha: 0.20),
                    tint.withValues(alpha: 0.06),
                  ],
                ),
              ),
              child: Icon(icon, size: 64, color: tint),
            ),
          ),
          Positioned(
            top: 18,
            right: 30,
            child: GlassPanel(
              blur: 12,
              radius: 12,
              padding: const EdgeInsets.all(7),
              shadows: AppShadows.soft,
              child: Icon(Icons.auto_awesome_rounded, size: 15, color: tint),
            ),
          ),
        ],
      ),
    );
  }
}
