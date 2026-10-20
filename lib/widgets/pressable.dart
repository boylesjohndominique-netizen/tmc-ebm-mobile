import 'dart:async';

import 'package:flutter/material.dart';
import '../app/motion.dart';
import '../app/theme.dart';

/// A wrapper that gives any child a subtle press-down spring response.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const Pressable(
      {super.key, required this.child, this.onTap, this.borderRadius});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.fast, value: 1.0);
  late final Animation<double> _scale = Tween(begin: 0.955, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: AppMotion.springy));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  void _up() {
    if (widget.onTap == null) return;
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return GestureDetector(
      onTapDown: reduce ? null : (_) => _down(),
      onTapUp: reduce ? null : (_) => _up(),
      onTapCancel: reduce ? null : _up,
      onTap: widget.onTap,
      child: reduce
          ? widget.child
          : ScaleTransition(
              scale: _scale,
              child: widget.child,
            ),
    );
  }
}

/// Plays a one-shot staggered fade + rise entrance when first built.
class Entrance extends StatefulWidget {
  final Widget child;
  final int delay; // milliseconds

  const Entrance({super.key, required this.child, this.delay = 0});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.entrance);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<double> _rise = Tween(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.emphasized));
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _delayTimer = Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child:
            Transform.translate(offset: Offset(0, _rise.value), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Standard content card: white surface, rounded, soft shadow, optional border.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: shadows,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Consistent pill-style section header used across screens.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
