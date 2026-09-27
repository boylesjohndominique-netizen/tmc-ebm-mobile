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
  RequestStatus? _statusFilter;
  String? _cancellingId;

  static const _filters = [
    RequestStatus.pending,
    RequestStatus.approved,
    RequestStatus.completed,
    RequestStatus.rejected,
    RequestStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final all = appState.transactions;
    final requests = _applyFilter(all);
    final dateFormat = DateFormat('MMM d');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Requests', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${requests.length} of ${all.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),

                  // ── Status chips ────────────────────────────────────────
                  if (all.isNotEmpty)
                    SizedBox(
                      height: 34,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        clipBehavior: Clip.none,
                        children: [
                          _StatusChip(
                            label: 'All',
                            selected: _statusFilter == null,
                            onTap: () => setState(() => _statusFilter = null),
                          ),
                          ..._filters.map(
                            (s) => _StatusChip(
                              label: s.label,
                              selected: _statusFilter == s,
                              onTap: () => setState(() => _statusFilter = s),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                backgroundColor: AppColors.surface,
                color: AppColors.primary,
                onRefresh: () => appState.refreshBorrowings(),
                child: requests.isEmpty
                    ? const EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No requests',
                        subtitle: 'Browse equipment to submit your first request.',
                      )
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final txn = requests[i];
                          return _RequestTile(
                            txn: txn,
                            dateFormat: dateFormat,
                            cancelling: _cancellingId == txn.transactionId,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => TransactionDetailsScreen(
                                      transactionId: txn.transactionId)),
                            ),
                            onCancel: txn.status == RequestStatus.pending
                                ? () => _confirmCancel(context, txn.transactionId)
                                : null,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BorrowingTransaction> _applyFilter(List<BorrowingTransaction> all) {
    final filtered =
        _statusFilter == null ? all : all.where((t) => t.status == _statusFilter).toList();
    // Newest requests first.
    final sorted = [...filtered]..sort((a, b) => b.requestDate.compareTo(a.requestDate));
    return sorted;
  }

  void _confirmCancel(BuildContext context, String transactionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel request?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Keep')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _cancellingId = transactionId);
              final error = await context.read<AppState>().cancelRequest(transactionId);
              if (!mounted) return;
              setState(() => _cancellingId = null);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Request cancelled.'),
                  backgroundColor: error != null ? AppColors.danger : null,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request tile — status dot, item name, date range, status pill.
// ---------------------------------------------------------------------------
class _RequestTile extends StatelessWidget {
  final BorrowingTransaction txn;
  final DateFormat dateFormat;
  final bool cancelling;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _RequestTile({
    required this.txn,
    required this.dateFormat,
    required this.cancelling,
    required this.onTap,
    this.onCancel,
  });

  Color get _statusColor => switch (txn.status) {
        RequestStatus.pending => AppColors.warning,
        RequestStatus.approved => AppColors.success,
        RequestStatus.rejected => AppColors.danger,
        RequestStatus.completed => AppColors.primary,
        RequestStatus.cancelled => AppColors.neutral,
      };

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${txn.equipmentName}  ·  ${txn.quantity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge.forRequest(txn.status),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    '${dateFormat.format(txn.borrowingDate)} → ${dateFormat.format(txn.returnDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  if (onCancel != null)
                    SizedBox(
                      height: 28,
                      child: TextButton(
                        onPressed: cancelling ? null : onCancel,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: Text(cancelling ? 'Cancelling' : 'Cancel'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status chip — quiet pill that fills with brand color when selected.
// ---------------------------------------------------------------------------
class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
