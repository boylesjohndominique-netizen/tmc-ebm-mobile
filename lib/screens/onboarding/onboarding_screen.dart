import 'package:flutter/material.dart';
import '../../app/theme.dart';

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
    description: 'Browse all available school equipment — laptops, projectors, cameras, and more — right from your phone.',
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
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: const BoxDecoration(
                            color: AppColors.lightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 84, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryBlue : AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(isLast ? 'Get Started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
