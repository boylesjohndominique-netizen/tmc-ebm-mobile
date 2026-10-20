import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import 'profile_screen.dart';

/// Settings screen — Appearance (theme mode) and Platform Policies authored by
/// administrators in the web system.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final policies = appState.platformPolicies;
    final overdueFee = appState.overdueFeePerDay;

    return LiquidScaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: RefreshIndicator(
        backgroundColor: AppColors.surface,
        color: AppColors.primary,
        onRefresh: () => appState.refreshSettings(),
        child: ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
          children: [
            // ── ID Verification (Profile Settings shortcut) ────────────────
            const GlassSectionLabel('Account Verification'),
            const SizedBox(height: 8),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Pressable(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 22,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Submit / View School ID',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              switch (appState.idVerificationStatus) {
                                IdVerificationStatus.approved =>
                                  'ID verified — borrowing is unlocked',
                                IdVerificationStatus.pending =>
                                  'ID submitted — awaiting admin review',
                                IdVerificationStatus.rejected =>
                                  'ID rejected — tap to resubmit in Profile',
                                IdVerificationStatus.notSubmitted =>
                                  'Tap to upload your Front & Back ID in Profile',
                              },
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),

            // ── Appearance ─────────────────────────────────────────────────
            const GlassSectionLabel('Appearance'),
            const SizedBox(height: 8),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Pressable(
                onTap: () => appState.toggleDarkMode(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        appState.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 22,
                        color: appState.isDarkMode
                            ? AppColors.gold
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dark Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appState.isDarkMode
                                  ? 'Dark theme enabled'
                                  : 'Light theme enabled',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: appState.isDarkMode,
                        onChanged: (_) => appState.toggleDarkMode(),
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),

            // ── Platform Policies ──────────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: GlassSectionLabel('Platform Policies'),
                ),
                if (appState.isLoadingPolicies)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (overdueFee > 0) ...[
              GlassCard(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 22,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overdue Return Fee Policy',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₱${overdueFee.toStringAsFixed(2)} per day for late equipment returns.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (policies.isEmpty && !appState.isLoadingPolicies)
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.policy_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Platform Policies Published',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Policies and guidelines created by administrators will appear here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              )
            else
              for (int i = 0; i < policies.length; i++) ...[
                _PolicyCard(
                  policy: policies[i],
                  initiallyExpanded: i == 0,
                ),
                if (i != policies.length - 1) const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _PolicyCard extends StatefulWidget {
  final PlatformPolicy policy;
  final bool initiallyExpanded;

  const _PolicyCard({
    required this.policy,
    this.initiallyExpanded = false,
  });

  @override
  State<_PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<_PolicyCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final policy = widget.policy;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      policy.title.isEmpty ? 'Platform Policy' : policy.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && policy.content.isNotEmpty) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(
                policy.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
