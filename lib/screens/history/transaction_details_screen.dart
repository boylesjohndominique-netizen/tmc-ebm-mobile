import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/borrowing_transaction.dart';
import '../../state/app_state.dart';
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
      return Scaffold(
        appBar: AppBar(title: const Text('Transaction Details')),
        body: const Center(child: Text('Transaction not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(txn.transactionId)),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge.forRequest(txn.status),
                StatusBadge.forReturn(txn.returnStatus),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Equipment Information',
              rows: {
                'Equipment': txn.equipmentName,
                if (txn.assetId.isNotEmpty) 'Asset ID': txn.assetId,
                if (txn.category.isNotEmpty) 'Category': txn.category,
                'Quantity': '${txn.quantity}',
              },
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Borrowing Details',
              rows: {
                'Borrowing Date': dateFormat.format(txn.borrowingDate),
                'Expected Return': dateFormat.format(txn.returnDate),
                'Actual Return':
                    txn.actualReturnDate != null ? dateFormat.format(txn.actualReturnDate!) : '—',
                'Purpose': txn.purpose,
                if (txn.notes.isNotEmpty) 'Notes': txn.notes,
              },
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Timeline',
              rows: {
                'Request Date': dateFormat.format(txn.requestDate),
                'Approval Date':
                    txn.approvalDate != null ? dateFormat.format(txn.approvalDate!) : 'Pending review',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (int i = 0; i < entries.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    entries[i].key,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entries[i].value,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (i != entries.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}
