import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/theme_toggle_button.dart';
import '../equipment/equipment_details_screen.dart';
import '../history/transaction_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstName = user.fullName.trim().split(RegExp(r'\s+')).first;

    return LiquidScaffold(
      body: RefreshIndicator(
        backgroundColor: AppColors.surface,
        color: AppColors.primary,
        onRefresh: () async {
          try {
            await appState.refreshAll();
          } catch (_) {
            // Keep the indicator from hanging if the backend is unreachable.
            await Future.delayed(const Duration(milliseconds: 400));
          }
        },
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            // ── Header: brand mark + theme + notifications ─────────────────
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: 46,
                child: Row(
                  children: [
                    GlassPanel(
                      blur: 16,
                      radius: 15,
                      padding: const EdgeInsets.all(6),
                      shadows: AppShadows.soft,
                      child: Image.asset(
                        'assets/images/tmc_logo.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const Spacer(),
                    const ThemeToggleButton(isHeaderStyle: false),
                    const SizedBox(width: 8),
                    GlassIconButton(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Notifications',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/notifications'),
                      badge: appState.unreadCount > 0
                          ? Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1.5,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Title ──────────────────────────────────────────────────────
            Text('Overview', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Welcome back, $firstName.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            if (appState.currentUser?.isPending == true) ...[
              GlassPanel(
                blur: 0,
                radius: AppRadius.lg,
                padding: EdgeInsets.zero,
                shadows: AppShadows.soft,
                tint: AppColors.warning
                    .withValues(alpha: AppColors.isDark ? 0.16 : 0.10),
                borderColor: AppColors.warning.withValues(alpha: 0.32),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Not Verified',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Browse freely — submit your front and back ID photos in Profile to unlock borrowing.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── Stats strip ────────────────────────────────────────────────
            _StatsStrip(
              borrowed: appState.currentlyBorrowed.length,
              pending: appState.transactions
                  .where((t) => t.status == RequestStatus.pending)
                  .length,
              approved: appState.transactions
                  .where((t) => t.status == RequestStatus.approved)
                  .length,
              overdue: appState.overdueCount,
            ),
            const SizedBox(height: 28),

            // ── Quick actions ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.search_rounded,
                    label: 'Browse',
                    onTap: () => Navigator.of(context).pushNamed('/equipment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Request',
                    tint: AppColors.gold,
                    onTap: () => Navigator.of(context).pushNamed('/equipment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.assignment_return_outlined,
                    label: 'Returns',
                    tint: AppColors.success,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/borrowed-equipment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.history_rounded,
                    label: 'History',
                    tint: AppColors.info,
                    onTap: () => Navigator.of(context).pushNamed('/history'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // ── Equipment preview ──────────────────────────────────────────
            GlassSectionHeader(
              title: 'Equipment',
              actionLabel: 'View all',
              onAction: () => Navigator.of(context).pushNamed('/equipment'),
            ),
            const SizedBox(height: 12),
            ...appState.equipment.where((e) => e.isAvailable).take(3).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EquipmentCard(
                      equipment: e,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                EquipmentDetailsScreen(equipmentId: e.id)),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 18),

            // ── Recent activity ────────────────────────────────────────────
            GlassSectionHeader(
              title: 'Activity',
              actionLabel: appState.transactions.isEmpty ? null : 'View all',
              onAction: () => Navigator.of(context).pushNamed('/my-requests'),
            ),
            const SizedBox(height: 12),
            if (appState.transactions.isEmpty)
              GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 20, color: AppColors.textTertiary),
                    const SizedBox(width: 10),
                    Text('Nothing yet.',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            else
              ...appState.transactions
                  .take(3)
                  .map((t) => _ActivityTile(txn: t)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats strip — one gradient card, four tap-through figures.
// ---------------------------------------------------------------------------
class _StatsStrip extends StatelessWidget {
  final int borrowed;
  final int pending;
  final int approved;
  final int overdue;

  const _StatsStrip({
    required this.borrowed,
    required this.pending,
    required this.approved,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: AppShadows.primaryGlow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            // Glossy top rim.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.10),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  _StatColumn(
                    value: borrowed,
                    label: 'Borrowed',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/borrowed-equipment'),
                  ),
                  _divider,
                  _StatColumn(
                    value: pending,
                    label: 'Pending',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/my-requests'),
                  ),
                  _divider,
                  _StatColumn(
                    value: approved,
                    label: 'Approved',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/my-requests'),
                  ),
                  _divider,
                  _StatColumn(
                    value: overdue,
                    label: 'Overdue',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/borrowed-equipment'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _divider => Container(
        width: 1,
        height: 32,
        color: Colors.white.withValues(alpha: 0.18),
      );
}

class _StatColumn extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback onTap;

  const _StatColumn(
      {required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick action tile — glass card with a tinted icon.
// ---------------------------------------------------------------------------
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AppColors.primary;
    return Pressable(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color.withValues(alpha: 0.16)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity tile — status dot, item name, trailing status pill.
// ---------------------------------------------------------------------------
class _ActivityTile extends StatelessWidget {
  final BorrowingTransaction txn;
  const _ActivityTile({required this.txn});

  Color get _statusColor => switch (txn.status) {
        RequestStatus.pending => AppColors.warning,
        RequestStatus.approved => AppColors.success,
        RequestStatus.rejected => AppColors.danger,
        RequestStatus.completed => AppColors.primary,
        RequestStatus.cancelled => AppColors.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TransactionDetailsScreen(transactionId: txn.transactionId),
          ),
        ),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${txn.equipmentName}  ·  ${txn.quantity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.forRequest(txn.status),
            ],
          ),
        ),
      ),
    );
  }
}
