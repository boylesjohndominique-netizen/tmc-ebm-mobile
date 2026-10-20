import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/status_badge.dart';

class BorrowedEquipmentScreen extends StatelessWidget {
  const BorrowedEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final borrowed = appState.currentlyBorrowed;
    final dateFormat = DateFormat('MMM d, yyyy');

    return LiquidScaffold(
      appBar: AppBar(title: const Text('Borrowed Equipment')),
      body: borrowed.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nothing borrowed yet',
              subtitle: 'Items you borrow will appear here for tracking.',
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
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

                return GlassCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: dueColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: dueColor.withValues(alpha: 0.16),
                              ),
                            ),
                            child: Icon(Icons.inventory_2_rounded,
                                size: 20, color: dueColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${txn.equipmentName} × ${txn.quantity}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Borrowed ${dateFormat.format(txn.borrowingDate)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: dueColor.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: dueColor.withValues(alpha: 0.22),
                              ),
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
                      const SizedBox(height: 11),
                      Padding(
                        padding: const EdgeInsets.only(left: 54),
                        child: Text(
                          'Expected return: ${dateFormat.format(txn.returnDate)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: StatusBadge.forReturn(txn.returnStatus)),
                          const SizedBox(width: 8),
                          if (txn.returnStatus == ReturnStatus.notReturned)
                            ElevatedButton.icon(
                              onPressed: () => _confirmReturn(context,
                                  txn.transactionId, txn.equipmentName),
                              icon: const Icon(Icons.assignment_return_rounded,
                                  size: 16),
                              label: const Text('Submit Return'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
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

  void _confirmReturn(
      BuildContext context, String transactionId, String equipmentName) {
    showGlassDialog(
      context: context,
      builder: (ctx) => GlassDialog(
        icon: Icons.assignment_return_rounded,
        title: 'Submit Return Request?',
        message:
            'Confirm that you are returning "$equipmentName" to the Equipment Office.',
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Not Yet')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final error = await context
                  .read<AppState>()
                  .submitReturnRequest(transactionId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(error ?? 'Return request submitted successfully.'),
                  backgroundColor: error != null ? AppColors.danger : null,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
