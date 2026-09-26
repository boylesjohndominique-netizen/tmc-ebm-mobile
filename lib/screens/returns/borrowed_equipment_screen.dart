import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class BorrowedEquipmentScreen extends StatelessWidget {
  const BorrowedEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final borrowed = appState.currentlyBorrowed;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Borrowed Equipment')),
      body: borrowed.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nothing borrowed yet',
              subtitle: 'Items you borrow will appear here for tracking.',
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: borrowed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final txn = borrowed[i];
                final overdue = txn.isOverdue;
                final daysLeft = txn.daysUntilDue;
                String dueLabel;
                Color dueColor;
                if (txn.returnStatus == ReturnStatus.returnPending) {
                  dueLabel = 'Return Pending';
                  dueColor = AppColors.warning;
                } else if (overdue) {
                  dueLabel = 'Overdue';
                  dueColor = AppColors.danger;
                } else if (daysLeft <= 3) {
                  dueLabel = 'Due in $daysLeft day${daysLeft == 1 ? '' : 's'}';
                  dueColor = AppColors.warning;
                } else {
                  dueLabel = 'Due in $daysLeft days';
                  dueColor = AppColors.success;
                }

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: overdue
                          ? AppColors.danger.withValues(alpha: 0.4)
                          : AppColors.divider.withValues(alpha: 0.6),
                    ),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${txn.equipmentName} × ${txn.quantity}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: dueColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              dueLabel,
                              maxLines: 1,
                              style: TextStyle(
                                color: dueColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Borrowed: ${dateFormat.format(txn.borrowingDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Expected return: ${dateFormat.format(txn.returnDate)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: StatusBadge.forReturn(txn.returnStatus)),
                          const SizedBox(width: 8),
                          if (txn.returnStatus == ReturnStatus.notReturned)
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _confirmReturn(context, txn.transactionId, txn.equipmentName),
                              icon: const Icon(Icons.assignment_return_rounded, size: 16),
                              label: const Text('Submit Return'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _confirmReturn(BuildContext context, String transactionId, String equipmentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Return Request?'),
        content: Text('Confirm that you are returning "$equipmentName" to the Equipment Office.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Not Yet')),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().submitReturnRequest(transactionId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Return request submitted successfully.')));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
