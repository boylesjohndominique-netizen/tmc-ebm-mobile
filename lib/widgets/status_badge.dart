import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/borrowing_transaction.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  factory StatusBadge.forRequest(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return const StatusBadge(label: 'Pending', color: AppColors.warning);
      case RequestStatus.approved:
        return const StatusBadge(label: 'Approved', color: AppColors.success);
      case RequestStatus.rejected:
        return const StatusBadge(label: 'Rejected', color: AppColors.danger);
      case RequestStatus.completed:
        return const StatusBadge(label: 'Completed', color: AppColors.info);
      case RequestStatus.cancelled:
        return const StatusBadge(label: 'Cancelled', color: AppColors.neutral);
    }
  }

  factory StatusBadge.forReturn(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.notReturned:
        return const StatusBadge(label: 'Not Returned', color: AppColors.neutral);
      case ReturnStatus.returnPending:
        return const StatusBadge(label: 'Return Pending', color: AppColors.warning);
      case ReturnStatus.returnConfirmed:
        return const StatusBadge(label: 'Return Confirmed', color: AppColors.info);
      case ReturnStatus.completed:
        return const StatusBadge(label: 'Completed', color: AppColors.success);
    }
  }

  factory StatusBadge.availability(String status) {
    switch (status) {
      case 'Available':
        return StatusBadge(label: status, color: AppColors.success);
      case 'Limited':
        return StatusBadge(label: status, color: AppColors.warning);
      default:
        return StatusBadge(label: status, color: AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
