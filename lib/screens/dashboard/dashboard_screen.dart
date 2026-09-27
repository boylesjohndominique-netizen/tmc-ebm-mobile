import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/statistic_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/theme_toggle_button.dart';
import '../equipment/equipment_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final totalBorrowed = appState.currentlyBorrowed.length;
    final pending = appState.transactions.where((t) => t.status == RequestStatus.pending).length;
    final approved = appState.transactions.where((t) => t.status == RequestStatus.approved).length;
    final overdue = appState.overdueCount;
    final previewEquipment = appState.equipment.where((e) => e.isAvailable).take(4).toList();
    final recent = appState.transactions.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        backgroundColor: AppColors.surface,
        color: AppColors.primary,
        onRefresh: () async => Future.delayed(const Duration(milliseconds: 600)),
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: EdgeInsets.zero,
          children: [
            // Gradient header — greeting + branding + notification bell.
            Container(
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 22),
                          ),
                          const Spacer(),
                          const ThemeToggleButton(),
                          const SizedBox(width: 8),
                          Stack(
                            children: [
                              _HeaderButton(
                                icon: Icons.notifications_none_rounded,
                                onTap: () => Navigator.of(context).pushNamed('/notifications'),
                              ),
                              if (appState.unreadCount > 0)
                                Positioned(
                                  top: 6,
                                  right: 8,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${_greeting()},',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${user.fullName.split(' ').first} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back to TMCEBMS.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats grid — inside the scrollable ListView so it can never overflow.
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        StatisticCard(
                          label: 'Total Borrowed',
                          value: '$totalBorrowed',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          onTap: () => Navigator.of(context).pushNamed('/borrowed-equipment'),
                        ),
                        StatisticCard(
                          label: 'Pending Requests',
                          value: '$pending',
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.warning,
                          onTap: () => Navigator.of(context).pushNamed('/my-requests'),
                        ),
                        StatisticCard(
                          label: 'Approved Requests',
                          value: '$approved',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          onTap: () => Navigator.of(context).pushNamed('/my-requests'),
                        ),
                        StatisticCard(
                          label: 'Overdue Equipment',
                          value: '$overdue',
                          icon: Icons.warning_rounded,
                          color: AppColors.danger,
                          onTap: () => Navigator.of(context).pushNamed('/borrowed-equipment'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.search_rounded,
                            label: 'Browse\nEquipment',
                            onTap: () => Navigator.of(context).pushNamed('/equipment'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Request\nEquipment',
                            onTap: () => Navigator.of(context).pushNamed('/equipment'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.assignment_return_outlined,
                            label: 'My Borrowed\nEquipment',
                            onTap: () => Navigator.of(context).pushNamed('/borrowed-equipment'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.history_rounded,
                            label: 'Borrowing\nHistory',
                            onTap: () => Navigator.of(context).pushNamed('/history'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Available Equipment',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/equipment'),
                          child: const Text('See all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ...previewEquipment.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EquipmentCard(
                          equipment: e,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => EquipmentDetailsScreen(equipmentId: e.id)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Recent Activities', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    if (recent.isEmpty)
                      Text('No recent activity yet.',
                          style: Theme.of(context).textTheme.bodyMedium)
                    else
                      ...recent.map((t) => _ActivityTile(txn: t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final BorrowingTransaction txn;
  const _ActivityTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${txn.equipmentName} • x${txn.quantity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(txn.transactionId, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge.forRequest(txn.status),
        ],
      ),
    );
  }
}
