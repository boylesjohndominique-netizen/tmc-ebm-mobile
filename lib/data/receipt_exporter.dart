import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/borrowing_receipt.dart';

class ReceiptExporter {
  static String date(DateTime? value, {bool time = false}) {
    if (value == null) return '-';
    return DateFormat(
      time ? 'MMM d, yyyy h:mm a' : 'MMM d, yyyy',
    ).format(time ? value.toLocal() : value);
  }

  static Map<String, String> details(BorrowingReceipt receipt) => {
    'Student': receipt.borrower['name'] ?? '',
    'Student ID': receipt.borrower['id_number'] ?? '',
    'Email': receipt.borrower['email'] ?? '',
    'Contact': receipt.borrower['contact_number'] ?? '',
    'Request status': receipt.status,
    '${receipt.handoverLabel} status': receipt.pickupStatus,
    '${receipt.handoverLabel} starts': date(receipt.pickupStartsAt, time: true),
    '${receipt.handoverLabel} ends': date(receipt.pickupEndsAt, time: true),
    if (receipt.borrowingTransactionCode.isNotEmpty)
      'Borrowing receipt': receipt.borrowingTransactionCode,
    'Borrowing date': date(receipt.borrowingDate),
    'Return by': date(receipt.expectedReturnDate),
    (receipt.isReturn ? 'Return notes' : 'Purpose / student notes'):
        receipt.borrowerRemarks,
    'Admin instructions': receipt.approvalRemarks,
    'Requested': date(receipt.requestedAt, time: true),
    'Approved': date(receipt.approvedAt, time: true),
    'Approved by': receipt.approvedBy,
    if (receipt.pickupProcessedAt != null)
      '${receipt.handoverLabel} processed': date(
        receipt.pickupProcessedAt,
        time: true,
      ),
    if (receipt.pickupRemarks.isNotEmpty)
      'Staff remarks': receipt.pickupRemarks,
    if (receipt.pickupStaffName.isNotEmpty) 'Staff': receipt.pickupStaffName,
    if (receipt.pickupMethod.isNotEmpty)
      'Confirmation method': receipt.pickupMethod == 'qr'
          ? 'QR scan'
          : 'Receipt number',
    if (receipt.verifiedStudentId.isNotEmpty)
      'Verified student ID': receipt.verifiedStudentId,
    if (receipt.conditionOnReturn.isNotEmpty)
      'Inspected condition': receipt.conditionOnReturn,
    if (receipt.conditionNotes.isNotEmpty)
      'Equipment problem': receipt.conditionNotes,
    if (receipt.isReturn) 'Overdue payment': receipt.paymentStatus,
    if (receipt.adminVerifiedAt != null)
      'Admin verified': date(receipt.adminVerifiedAt, time: true),
    if (receipt.adminVerifierName.isNotEmpty)
      'Verified by': receipt.adminVerifierName,
    if (receipt.adminRemarks.isNotEmpty)
      'Admin verification notes': receipt.adminRemarks,
    if (receipt.returnedAt != null)
      'Returned at': date(receipt.returnedAt, time: true),
    if ((receipt.overdueFee ?? 0) > 0)
      'Overdue fee': 'PHP ${receipt.overdueFee!.toStringAsFixed(2)}',
  };

  static Future<Uint8List> pdf(BorrowingReceipt receipt) async {
    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Text(
          'Receipt ${receipt.transactionCode} - Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        build: (_) => [
          pw.Text(
            'Trinidad Municipal College',
            style: const pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(receipt.title, style: const pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 12),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: receipt.qrPayload,
              width: 150,
              height: 150,
              padding: const pw.EdgeInsets.all(10),
            ),
          ),
          pw.Center(
            child: pw.Text(
              receipt.transactionCode,
              style: const pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(receipt.instructions),
          pw.SizedBox(height: 12),
          ...details(receipt).entries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                '${entry.key}: ${entry.value.isEmpty ? '-' : entry.value}',
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Equipment',
            style: const pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          ...receipt.items.expand(
            (item) => [
              pw.SizedBox(height: 10),
              pw.Text(
                '${item['name']} (quantity: ${item['quantity']})',
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Equipment #${item['equipment_id']} | Category: ${item['category'] ?? '-'} | Condition: ${item['condition'] ?? '-'}',
              ),
              if ('${item['description'] ?? ''}'.isNotEmpty)
                pw.Text('${item['description']}'),
              if ('${item['pickup_location'] ?? ''}'.isNotEmpty)
                pw.Text('School pickup location: ${item['pickup_location']}'),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Saved copies show the status at export time. Staff verify the current status in the system.',
          ),
        ],
      ),
    );
    return document.save();
  }
}
