import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/borrowing_transaction.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  const StatusBadge(
      {super.key,
      required this.label,
      required this.color,
      this.filled = false});

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
        return const StatusBadge(
            label: 'Not Returned', color: AppColors.neutral);
      case ReturnStatus.returnPending:
        return const StatusBadge(
            label: 'Return Pending', color: AppColors.warning);
      case ReturnStatus.returnConfirmed:
        return const StatusBadge(
            label: 'Return Confirmed', color: AppColors.info);
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
        color: filled ? color : color.withValues(alpha: 0.14),
        gradient: filled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.92), color],
              )
            : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: filled ? AppColors.onPrimary : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: TextStyle(
              color: filled ? AppColors.onPrimary : color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
