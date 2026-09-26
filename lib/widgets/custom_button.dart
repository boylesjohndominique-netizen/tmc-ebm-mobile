import 'package:flutter/material.dart';

/// Primary / secondary / destructive action button with press-spring response.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool loading;
  final IconData? icon;
  final Color? color;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.loading = false,
    this.icon,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: outlined ? Theme.of(context).colorScheme.primary : Colors.white,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final disabled = loading || onPressed == null;

    if (outlined) {
      return OutlinedButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: color != null
          ? ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: textColor ?? Colors.white)
          : null,
      child: child,
    );
  }
}
