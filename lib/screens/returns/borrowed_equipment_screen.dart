import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import '../../widgets/status_badge.dart';
import '../history/transaction_details_screen.dart';

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
                final isEarly = txn.isBeforeDueDate;
                String dueLabel;
                Color dueColor;
                if (txn.returnStatus == ReturnStatus.returnPending) {
                  dueLabel = 'Return Pending';
                  dueColor = AppColors.warning;
                } else if (overdue) {
                  dueLabel = 'Overdue';
                  dueColor = AppColors.danger;
                } else if (daysLeft == 0) {
                  dueLabel = 'Due today';
                  dueColor = AppColors.warning;
                } else if (daysLeft <= 3) {
                  dueLabel = 'Due in $daysLeft day${daysLeft == 1 ? '' : 's'}';
                  dueColor = AppColors.warning;
                } else {
                  dueLabel = 'Due in $daysLeft days';
                  dueColor = AppColors.success;
                }

                return Pressable(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailsScreen(
                        transactionId: txn.transactionId,
                      ),
                    ),
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                size: 22,
                                color: dueColor,
                              ),
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: dueColor.withValues(alpha: 0.14),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
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
                          padding: const EdgeInsets.only(left: 34),
                          child: Text(
                            'Expected return: ${dateFormat.format(txn.returnDate)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatusBadge.forReturn(txn.returnStatus),
                            ),
                            const SizedBox(width: 8),
                            if (txn.canReturn)
                              ElevatedButton.icon(
                                onPressed: () =>
                                    showReturnEquipmentDialog(context, txn),
                                icon: const Icon(
                                  Icons.assignment_return_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  isEarly ? 'Return Early' : 'Submit Return',
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
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
                  ),
                );
              },
            ),
    );
  }
}

Future<bool> showReturnEquipmentDialog(
  BuildContext context,
  BorrowingTransaction txn,
) async {
  final remarks = await showGlassDialog<String>(
    context: context,
    builder: (_) => _ReturnEquipmentDialog(txn: txn),
  );
  if (remarks == null || !context.mounted) return false;

  final error = await context.read<AppState>().submitReturnRequest(
        txn.transactionId,
        remarks: remarks.isEmpty ? null : remarks,
      );
  if (!context.mounted) return false;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error ??
            (txn.isBeforeDueDate
                ? 'Early return request submitted successfully.'
                : 'Return request submitted successfully.'),
      ),
      backgroundColor: error != null ? AppColors.danger : null,
    ),
  );
  return error == null;
}

class _ReturnEquipmentDialog extends StatefulWidget {
  final BorrowingTransaction txn;

  const _ReturnEquipmentDialog({required this.txn});

  @override
  State<_ReturnEquipmentDialog> createState() => _ReturnEquipmentDialogState();
}

class _ReturnEquipmentDialogState extends State<_ReturnEquipmentDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.txn;
    final isEarly = txn.isBeforeDueDate;
    final daysLeft = txn.daysUntilDue;
    final dateFormat = DateFormat('MMM d, yyyy');

    final message = isEarly
        ? 'You are returning "${txn.equipmentName}" $daysLeft day${daysLeft == 1 ? '' : 's'} ahead of the expected return date (${dateFormat.format(txn.returnDate)}).'
        : 'Confirm that you are returning "${txn.equipmentName}" to the Equipment Office.';

    return GlassDialog(
      icon: Icons.assignment_return_rounded,
      iconColor: isEarly ? AppColors.success : AppColors.primary,
      title: isEarly ? 'Return Equipment Early?' : 'Submit Return Request?',
      message: message,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEarly) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Early return — no overdue fee applies.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _noteController,
            maxLines: 2,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Return note (optional)',
              hintText: isEarly
                  ? 'e.g. Finished lab activity early'
                  : 'Condition or handover notes',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not Yet'),
        ),
        TextButton(
          onPressed: () {
            final typed = _noteController.text.trim();
            final remarks =
                typed.isNotEmpty ? typed : (isEarly ? 'Early return' : '');
            Navigator.of(context).pop(remarks);
          },
          child: Text(isEarly ? 'Return Early' : 'Confirm'),
        ),
      ],
    );
  }
}
