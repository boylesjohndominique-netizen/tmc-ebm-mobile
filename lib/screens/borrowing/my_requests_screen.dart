import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../history/transaction_details_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

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
              title: 'No borrowing requests yet.',
              subtitle: 'Browse equipment to submit your first request.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final txn = requests[i];
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('${txn.equipmentName} × ${txn.quantity}',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                            StatusBadge.forRequest(txn.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(txn.transactionId, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${dateFormat.format(txn.borrowingDate)} → ${dateFormat.format(txn.returnDate)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text('Requested ${dateFormat.format(txn.requestDate)}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        if (txn.status == RequestStatus.pending) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmCancel(context, txn.transactionId),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Cancel Request'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                                minimumSize: const Size(0, 36),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this borrowing request? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Keep Request')),
          TextButton(
            onPressed: () {
              context.read<AppState>().cancelRequest(transactionId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Request cancelled successfully.')));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }
}
