import 'package:flutter/material.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../widgets/custom_button.dart';

class _OnboardPage {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardPage({required this.icon, required this.title, required this.description});
}

const _pages = [
  _OnboardPage(
    icon: Icons.search_rounded,
    title: 'Easy Equipment Access',
    description:
        'Browse all available school equipment — laptops, projectors, cameras, and more — right from your phone.',
  ),
  _OnboardPage(
    icon: Icons.event_available_rounded,
    title: 'Simple Borrowing',
    description: 'Request equipment in a few taps. Select your borrowing and return dates and submit instantly.',
  ),
  _OnboardPage(
    icon: Icons.track_changes_rounded,
    title: 'Track Everything',
    description: 'Monitor your requests, borrowed items, returns, history, and notifications — all in one place.',
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

  void _finish() => Navigator.of(context).pushReplacementNamed('/login');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextButton(onPressed: _finish, child: const Text('Skip')),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          children: [
                            Container(
                              width: 176,
                              height: 176,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primarySoft,
                                    AppColors.primarySoft.withValues(alpha: 0.4),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1.5),
                              ),
                              child: Icon(page.icon, size: 78, color: AppColors.primary),
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: 320,
                              child: Text(
                                page.title,
                                style: Theme.of(context).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 320,
                              child: Text(
                                page.description,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: AppMotion.emphasized,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: CustomButton(
                label: isLast ? 'Get Started' : 'Next',
                icon: isLast ? Icons.arrow_forward_rounded : null,
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
    );
  }
}
