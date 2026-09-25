import 'package:flutter/material.dart';
import '../app/theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle = ''});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
