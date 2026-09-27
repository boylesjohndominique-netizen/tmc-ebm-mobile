import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pressable.dart';
import '../../widgets/status_badge.dart';
import '../history/transaction_details_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String? _cancellingId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final requests = appState.transactions;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: requests.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No borrowing requests yet',
              subtitle: 'Browse equipment to submit your first request.',
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final txn = requests[i];
                return Pressable(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            TransactionDetailsScreen(transactionId: txn.transactionId)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('${txn.equipmentName} × ${txn.quantity}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge.forRequest(txn.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(txn.transactionId, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text(
                          '${dateFormat.format(txn.borrowingDate)} → ${dateFormat.format(txn.returnDate)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text('Requested ${dateFormat.format(txn.requestDate)}',
                            style: Theme.of(context).textTheme.bodySmall),
                        if (txn.status == RequestStatus.pending) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child:                          OutlinedButton.icon(
                              onPressed: _cancellingId == null
                                  ? () => _confirmCancel(context, txn.transactionId)
                                  : null,
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Cancel Request'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: BorderSide(
                                    color: AppColors.danger.withValues(alpha: 0.5)),
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmCancel(BuildContext context, String transactionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
            'Are you sure you want to cancel this borrowing request? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Keep Request')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _cancellingId = transactionId);
              final error = await context.read<AppState>().cancelRequest(transactionId);
              if (!mounted) return;
              setState(() => _cancellingId = null);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Request cancelled successfully.'),
                  backgroundColor: error != null ? AppColors.danger : null,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}
