import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
import '../../widgets/equipment_icon.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/status_badge.dart';

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

    return LiquidScaffold(
      appBar: AppBar(title: Text(txn.transactionId)),
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
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primarySoft,
                          AppColors.primarySoft.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Icon(
                      equipmentIcon('${txn.category} ${txn.equipmentName}'),
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.equipmentName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          children: [
                            StatusBadge.forRequest(txn.status),
                            StatusBadge.forReturn(txn.returnStatus),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            _Section(
              title: 'Equipment Information',
              rows: {
                'Equipment': txn.equipmentName,
                if (txn.assetId.isNotEmpty) 'Asset ID': txn.assetId,
                if (txn.category.isNotEmpty) 'Category': txn.category,
                'Quantity': '${txn.quantity}',
              },
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Borrowing Details',
              rows: {
                'Borrowing Date': dateFormat.format(txn.borrowingDate),
                'Expected Return': dateFormat.format(txn.returnDate),
                'Actual Return': txn.actualReturnDate != null
                    ? dateFormat.format(txn.actualReturnDate!)
                    : '—',
                if (txn.hasOverdueFee)
                  'Overdue Fee':
                      '₱${txn.overdueFee!.toStringAsFixed(2)} (${txn.overdueDays ?? 0} day(s) late)',
                'Purpose': txn.purpose,
                if (txn.notes.isNotEmpty) 'Notes': txn.notes,
              },
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Timeline',
              rows: {
                'Request Date': dateFormat.format(txn.requestDate),
                'Approval Date': txn.approvalDate != null
                    ? dateFormat.format(txn.approvalDate!)
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
                        fontWeight: FontWeight.w600, fontSize: 13),
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
