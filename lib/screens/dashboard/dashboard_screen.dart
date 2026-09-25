import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/statistic_card.dart';
import '../../widgets/status_badge.dart';
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
    final user = appState.currentUser!;
    final totalBorrowed = appState.currentlyBorrowed.length;
    final pending = appState.transactions.where((t) => t.status == RequestStatus.pending).length;
    final approved = appState.transactions.where((t) => t.status == RequestStatus.approved).length;
    final overdue = appState.overdueCount;
    final previewEquipment = appState.equipment.where((e) => e.isAvailable).take(4).toList();
    final recent = appState.transactions.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TMCEBMS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(milliseconds: 600)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text('${_greeting()}, ${user.fullName.split(' ').first}!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Welcome back to TMCEBMS.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatisticCard(
                  label: 'Total Borrowed',
                  value: '$totalBorrowed',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.primaryBlue,
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
                    icon: Icons.add_circle_rounded,
                    label: 'Request\nEquipment',
                    onTap: () => Navigator.of(context).pushNamed('/equipment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.assignment_return_rounded,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Equipment', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => Navigator.of(context).pushNamed('/equipment'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...previewEquipment.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EquipmentCard(
                    equipment: e,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EquipmentDetailsScreen(equipmentId: e.id)),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            Text('Recent Activities', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No recent activity yet.', style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...recent.map((t) => _ActivityTile(txn: t)),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${txn.equipmentName} • x${txn.quantity}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(txn.transactionId, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          StatusBadge.forRequest(txn.status),
        ],
      ),
    );
  }
}
