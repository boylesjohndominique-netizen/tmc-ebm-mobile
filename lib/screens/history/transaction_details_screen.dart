import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/equipment_icon.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/status_badge.dart';
import '../returns/borrowed_equipment_screen.dart';
import '../borrowing/borrowing_receipt_screen.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final String transactionId;
  const TransactionDetailsScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    BorrowingTransaction? txn;
    for (final t in appState.transactions) {
      if (t.transactionId == transactionId) {
        txn = t;
        break;
      }
    }
    final dateFormat = DateFormat('MMM d, yyyy');

    if (txn == null) {
      return LiquidScaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    final currentTxn = txn;
    final showBottomAction =
        currentTxn.canReturn ||
        (currentTxn.status == RequestStatus.approved &&
            currentTxn.returnStatus == ReturnStatus.returnPending);

    return LiquidScaffold(
      appBar: AppBar(title: Text(currentTxn.transactionId)),
      bottomNavigationBar: showBottomAction
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: currentTxn.canReturn
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentTxn.isBeforeDueDate) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.event_available_rounded,
                                    size: 15,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Due ${dateFormat.format(currentTxn.returnDate)} (${currentTxn.daysUntilDue} day${currentTxn.daysUntilDue == 1 ? '' : 's'} left) — you can return early anytime.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => showReturnEquipmentDialog(
                                context,
                                currentTxn,
                              ),
                              icon: const Icon(
                                Icons.assignment_return_rounded,
                                size: 18,
                              ),
                              label: Text(
                                currentTxn.isBeforeDueDate
                                    ? 'Return Equipment Early'
                                    : 'Submit Return Request',
                              ),
                            ),
                          ),
                        ],
                      )
                    : GlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Return requested. Admin approval and staff inspection are required before it is confirmed.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary ──────────────────────────────────────────────────
            GlassPanel(
              blur: 20,
              strong: true,
              radius: AppRadius.xl,
              shadows: AppShadows.floating,
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    equipmentIcon(
                      '${currentTxn.category} ${currentTxn.equipmentName}',
                    ),
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTxn.equipmentName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children: [
                            StatusBadge.forRequest(currentTxn.status),
                            StatusBadge.forReturn(currentTxn.returnStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            if (currentTxn.receipt != null) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt ${currentTxn.transactionCode}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('Pickup: ${currentTxn.pickupStatus ?? "Awaiting"}'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BorrowingReceiptScreen(
                            transactionId: currentTxn.transactionId,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text('View / save receipt'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            for (final receipt in currentTxn.returnReceipts) ...[
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Return receipt ${receipt.transactionCode}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text('${receipt.status} · Staff: ${receipt.pickupStatus}'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BorrowingReceiptScreen(
                            transactionId: currentTxn.transactionId,
                            isReturnReceipt: true,
                            returnReceiptCode: receipt.transactionCode,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_rounded),
                      label: const Text('View / save return receipt'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            _Section(
              title: 'Equipment Information',
              rows: {
                'Equipment': currentTxn.equipmentName,
                if (currentTxn.assetId.isNotEmpty)
                  'Asset ID': currentTxn.assetId,
                if (currentTxn.category.isNotEmpty)
                  'Category': currentTxn.category,
                'Quantity': '${currentTxn.quantity}',
              },
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Borrowing Details',
              rows: {
                'Borrowing Date': dateFormat.format(currentTxn.borrowingDate),
                'Expected Return': dateFormat.format(currentTxn.returnDate),
                'Actual Return': currentTxn.actualReturnDate != null
                    ? dateFormat.format(currentTxn.actualReturnDate!)
                    : '—',
                if (currentTxn.hasOverdueFee)
                  'Overdue Fee':
                      '₱${currentTxn.overdueFee!.toStringAsFixed(2)} (${currentTxn.overdueDays ?? 0} day(s) late)',
                'Purpose': currentTxn.purpose,
                if (currentTxn.notes.isNotEmpty) 'Notes': currentTxn.notes,
              },
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Timeline',
              rows: {
                'Request Date': dateFormat.format(currentTxn.requestDate),
                'Approval Date': currentTxn.approvalDate != null
                    ? dateFormat.format(currentTxn.approvalDate!)
                    : 'Pending review',
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Map<String, String> rows;
  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final entries = rows.entries.toList();
    return GlassCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: 9),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < entries.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 118,
                  child: Text(
                    entries[i].key,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entries[i].value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (i != entries.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}
