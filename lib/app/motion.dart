import 'package:flutter/material.dart';

/// Central motion tokens — fast, smooth, subtly springy, iOS-like.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration entrance = Duration(milliseconds: 480);
  static const Duration pageIn = Duration(milliseconds: 320);
  static const Duration pageOut = Duration(milliseconds: 260);

  /// Smooth deceleration used for page transitions and entrances.
  static const Curve emphasized = Cubic(0.22, 0.9, 0.24, 1);

  /// Subtle overshoot for micro-interactions (never cartoonish).
  static const Curve springy = Curves.easeOutBack;

  /// Returns [duration] or zero when the platform asks for reduced motion.
  static Duration responsive(BuildContext context, Duration duration) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return reduce ? Duration.zero : duration;
  }
}

/// Default page route: an iOS-style forward slide + soft fade.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          transitionDuration: AppMotion.pageIn,
          reverseTransitionDuration: AppMotion.pageOut,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final reduce =
                MediaQuery.maybeDisableAnimationsOf(context) ?? false;
            if (reduce) return child;

            final curved =
                CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
            final slide = Tween<Offset>(
              begin: const Offset(0.16, 0),
              end: Offset.zero,
            ).animate(curved);
            final scale = Tween<double>(begin: 0.985, end: 1).animate(curved);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: slide,
                child: ScaleTransition(scale: scale, child: child),
              ),
            );
          },
        );
}
