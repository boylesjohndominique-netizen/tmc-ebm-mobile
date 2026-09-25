import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'transaction_details_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryBlue,
            tabs: [
              Tab(text: 'Borrowing History'),
              Tab(text: 'Return History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_BorrowingHistoryTab(), _ReturnHistoryTab()],
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
      return const EmptyState(icon: Icons.history_rounded, title: 'No borrowing history yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final txn = history[i];
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TransactionDetailsScreen(transactionId: txn.transactionId)),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${txn.equipmentName} × ${txn.quantity}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${dateFormat.format(txn.borrowingDate)} → ${dateFormat.format(txn.returnDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                StatusBadge.forRequest(txn.status),
              ],
            ),
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
      return const EmptyState(icon: Icons.assignment_turned_in_outlined, title: 'No returns recorded yet.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final txn = history[i];
        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TransactionDetailsScreen(transactionId: txn.transactionId)),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${txn.equipmentName} × ${txn.quantity}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Borrowed: ${dateFormat.format(txn.borrowingDate)}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      if (txn.actualReturnDate != null)
                        Text('Returned: ${dateFormat.format(txn.actualReturnDate!)}',
                            style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                StatusBadge.forReturn(txn.returnStatus),
              ],
            ),
          ),
        );
      },
    );
  }
}
