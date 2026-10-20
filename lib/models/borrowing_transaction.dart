enum RequestStatus { pending, approved, rejected, completed, cancelled }

extension RequestStatusLabel on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum ReturnStatus { notReturned, returnPending, returnConfirmed, completed }

extension ReturnStatusLabel on ReturnStatus {
  String get label {
    switch (this) {
      case ReturnStatus.notReturned:
        return 'Not Returned';
      case ReturnStatus.returnPending:
        return 'Return Pending';
      case ReturnStatus.returnConfirmed:
        return 'Return Confirmed';
      case ReturnStatus.completed:
        return 'Completed';
    }
  }
}

class BorrowingTransaction {
  final String transactionId;
  final String equipmentId;
  final String equipmentName;
  final String assetId;
  final String category;
  int quantity;
  final DateTime borrowingDate;
  final DateTime returnDate;
  DateTime? actualReturnDate;
  final String purpose;
  final String notes;
  final DateTime requestDate;
  DateTime? approvalDate;
  RequestStatus status;
  ReturnStatus returnStatus;
  int? overdueDays;
  double? overdueFee;

  BorrowingTransaction({
    required this.transactionId,
    required this.equipmentId,
    required this.equipmentName,
    required this.assetId,
    required this.category,
    required this.quantity,
    required this.borrowingDate,
    required this.returnDate,
    this.actualReturnDate,
    required this.purpose,
    this.notes = '',
    required this.requestDate,
    this.approvalDate,
    this.status = RequestStatus.pending,
    this.returnStatus = ReturnStatus.notReturned,
    this.overdueDays,
    this.overdueFee,
  });

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _dueDay =>
      DateTime(returnDate.year, returnDate.month, returnDate.day);

  bool get canReturn =>
      status == RequestStatus.approved &&
      returnStatus == ReturnStatus.notReturned;

  bool get isCurrentlyBorrowed =>
      status == RequestStatus.approved &&
      (returnStatus == ReturnStatus.notReturned ||
          returnStatus == ReturnStatus.returnPending);

  int get daysUntilDue => _dueDay.difference(_today).inDays;

  bool get isBeforeDueDate => _today.isBefore(_dueDay);

  bool get isEarlyReturnEligible => canReturn && isBeforeDueDate;

  bool get isOverdue =>
      isCurrentlyBorrowed &&
      _today.isAfter(_dueDay) &&
      returnStatus != ReturnStatus.returnConfirmed;

  bool get hasOverdueFee => (overdueFee ?? 0) > 0;
}
