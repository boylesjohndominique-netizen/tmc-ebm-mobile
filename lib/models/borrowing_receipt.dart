class BorrowingReceipt {
  final String kind;
  final String borrowingTransactionCode;
  final String verifiedStudentId;
  final String conditionOnReturn;
  final String conditionNotes;
  final String paymentStatus;
  final String adminRemarks;
  final String adminVerifierName;
  final DateTime? adminVerifiedAt;
  final DateTime? returnedAt;
  final double? overdueFee;
  final String transactionCode;
  final String qrPayload;
  final String status;
  final String pickupStatus;
  final Map<String, String> borrower;
  final List<Map<String, dynamic>> items;
  final String approvedBy;
  final String borrowerRemarks;
  final String approvalRemarks;
  final String pickupRemarks;
  final String pickupStaffName;
  final String pickupMethod;
  final DateTime? requestedAt;
  final DateTime? approvedAt;
  final DateTime? pickupStartsAt;
  final DateTime? pickupEndsAt;
  final DateTime? pickupProcessedAt;
  final DateTime? borrowingDate;
  final DateTime? expectedReturnDate;

  BorrowingReceipt.fromJson(Map<String, dynamic> json)
    : kind = '${json['kind'] ?? 'borrowing'}',
      borrowingTransactionCode = '${json['borrowing_transaction_code'] ?? ''}',
      verifiedStudentId = '${json['verified_student_id'] ?? ''}',
      conditionOnReturn = '${json['condition_on_return'] ?? ''}',
      conditionNotes = '${json['condition_notes'] ?? ''}',
      paymentStatus = '${json['payment_status'] ?? 'Not assessed'}',
      adminRemarks = '${json['admin_remarks'] ?? ''}',
      adminVerifierName = '${json['admin_verifier_name'] ?? ''}',
      adminVerifiedAt = DateTime.tryParse('${json['admin_verified_at'] ?? ''}'),
      returnedAt = DateTime.tryParse('${json['returned_at'] ?? ''}'),
      overdueFee = double.tryParse('${json['overdue_fee'] ?? ''}'),
      transactionCode = '${json['transaction_code'] ?? ''}',
      qrPayload = '${json['qr_payload'] ?? ''}',
      status = '${json['status'] ?? ''}',
      pickupStatus =
          '${json['handover_status'] ?? json['pickup_status'] ?? ''}',
      borrower = (json['borrower'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, '${value ?? ''}'),
      ),
      items = (json['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.unmodifiable(item))
          .toList(growable: false),
      approvedBy = '${json['approved_by'] ?? ''}',
      borrowerRemarks = '${json['borrower_remarks'] ?? ''}',
      approvalRemarks = '${json['approval_remarks'] ?? ''}',
      pickupRemarks =
          '${json['handover_remarks'] ?? json['pickup_remarks'] ?? ''}',
      pickupStaffName =
          '${json['handover_staff_name'] ?? json['pickup_staff_name'] ?? ''}',
      pickupMethod =
          '${json['handover_method'] ?? json['pickup_method'] ?? ''}',
      requestedAt = DateTime.tryParse('${json['requested_at'] ?? ''}'),
      approvedAt = DateTime.tryParse('${json['approved_at'] ?? ''}'),
      pickupStartsAt = DateTime.tryParse(
        '${json['handover_starts_at'] ?? json['pickup_starts_at'] ?? ''}',
      ),
      pickupEndsAt = DateTime.tryParse(
        '${json['handover_ends_at'] ?? json['pickup_ends_at'] ?? ''}',
      ),
      pickupProcessedAt = DateTime.tryParse(
        '${json['handover_processed_at'] ?? json['pickup_processed_at'] ?? ''}',
      ),
      borrowingDate = DateTime.tryParse('${json['borrowing_date'] ?? ''}'),
      expectedReturnDate = DateTime.tryParse(
        '${json['expected_return_date'] ?? ''}',
      );

  bool get isReturn => kind == 'return';
  String get title =>
      isReturn ? 'Equipment return receipt' : 'Equipment approval receipt';
  String get handoverLabel => isReturn ? 'Return' : 'Pickup';
  String get instructions => isReturn
      ? 'Present this receipt and your student ID during the return window. Staff record the equipment condition, overdue-fee payment and their decision. The administrator must verify the staff findings before the return is complete. Times are shown in your device time zone.'
      : 'Present this receipt and your student ID to equipment staff during the pickup window. Approval reserves equipment; staff must verify your identity and inspect equipment before handover. Times are shown in your device time zone.';
}
