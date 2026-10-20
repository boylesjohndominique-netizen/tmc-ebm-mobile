import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import '../../widgets/status_badge.dart';
import 'transaction_details_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: LiquidScaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('History'),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Every request and return, in one place.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    GlassPanel(
                      blur: 18,
                      radius: AppRadius.pill,
                      padding: const EdgeInsets.all(5),
                      shadows: AppShadows.soft,
                      child: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicator: BoxDecoration(
                          gradient: AppColors.premiumGradient,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: AppShadows.primaryGlow,
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        splashBorderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(height: 38, text: 'Borrowing'),
                          Tab(height: 38, text: 'Returns'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Expanded(
                child: TabBarView(
                  children: [_BorrowingHistoryTab(), _ReturnHistoryTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BorrowingHistoryTab extends StatelessWidget {
  const _BorrowingHistoryTab();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().borrowingHistory;
    final dateFormat = DateFormat('MMM d, yyyy');

    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No borrowing history yet',
        subtitle: 'Completed and past requests will appear here.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final txn = history[i];
        return _HistoryTile(
          title: '${txn.equipmentName} × ${txn.quantity}',
          subtitle:
              '${dateFormat.format(txn.borrowingDate)} → ${dateFormat.format(txn.returnDate)}',
          icon: Icons.inventory_2_outlined,
          badge: StatusBadge.forRequest(txn.status),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) =>
                    TransactionDetailsScreen(transactionId: txn.transactionId)),
          ),
        );
      },
    );
  }
}

class _ReturnHistoryTab extends StatelessWidget {
  const _ReturnHistoryTab();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().returnHistory;
    final dateFormat = DateFormat('MMM d, yyyy');

    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_turned_in_outlined,
        title: 'No returns recorded yet',
        subtitle: 'Returned equipment will be tracked here.',
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final txn = history[i];
        final subtitle = txn.actualReturnDate != null
            ? 'Borrowed ${dateFormat.format(txn.borrowingDate)} · Returned ${dateFormat.format(txn.actualReturnDate!)}'
            : 'Borrowed: ${dateFormat.format(txn.borrowingDate)}';
        return _HistoryTile(
          title: '${txn.equipmentName} × ${txn.quantity}',
          subtitle: subtitle,
          icon: Icons.assignment_turned_in_outlined,
          badge: StatusBadge.forReturn(txn.returnStatus),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) =>
                    TransactionDetailsScreen(transactionId: txn.transactionId)),
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget badge;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Icon(icon, size: 19, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            badge,
          ],
        ),
      ),
    );
  }
}
