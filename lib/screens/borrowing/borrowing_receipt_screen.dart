import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/receipt_exporter.dart';
import '../../models/borrowing_receipt.dart';
import '../../state/app_state.dart';

class BorrowingReceiptScreen extends StatefulWidget {
  final String transactionId;
  final bool isReturnReceipt;
  final String? returnReceiptCode;

  const BorrowingReceiptScreen({
    super.key,
    required this.transactionId,
    this.isReturnReceipt = false,
    this.returnReceiptCode,
  });

  @override
  State<BorrowingReceiptScreen> createState() => _BorrowingReceiptScreenState();
}

class _BorrowingReceiptScreenState extends State<BorrowingReceiptScreen> {
  final _receiptKey = GlobalKey();
  bool _exporting = false;

  Future<void> _export(BorrowingReceipt receipt, bool image) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _exporting = true);
    try {
      final bytes = image
          ? await _imageBytes()
          : await ReceiptExporter.pdf(receipt);
      final extension = image ? 'png' : 'pdf';
      await SharePlus.instance.share(
        ShareParams(
          title: 'Equipment receipt ${receipt.transactionCode}',
          files: [
            XFile.fromData(
              bytes,
              mimeType: image ? 'image/png' : 'application/pdf',
            ),
          ],
          fileNameOverrides: [
            'TMC-${receipt.isReturn ? 'return-' : ''}receipt-${receipt.transactionCode}.$extension',
          ],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to export the receipt. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<Uint8List> _imageBytes() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _receiptKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Receipt image unavailable.');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final transactions = appState.transactions.where(
      (item) => item.transactionId == widget.transactionId,
    );
    final returns = transactions.isEmpty
        ? <BorrowingReceipt>[]
        : transactions.first.returnReceipts;
    final matchingReturns = returns.where(
      (receipt) =>
          widget.returnReceiptCode == null ||
          receipt.transactionCode == widget.returnReceiptCode,
    );
    final receipt = widget.isReturnReceipt
        ? (matchingReturns.isEmpty ? null : matchingReturns.first)
        : (transactions.isEmpty ? null : transactions.first.receipt);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isReturnReceipt ? 'Return Receipt' : 'Approval Receipt',
        ),
      ),
      body: receipt == null
          ? const Center(
              child: Text(
                'An approval receipt is not available for this request.',
              ),
            )
          : RefreshIndicator(
              onRefresh: appState.refreshBorrowings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _exporting
                              ? null
                              : () => _export(receipt, true),
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Save image'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _exporting
                              ? null
                              : () => _export(receipt, false),
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Export PDF'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _exporting
                          ? 'Preparing receipt…'
                          : 'Choose a save or share destination in the export menu.',
                    ),
                    const SizedBox(height: 16),
                    RepaintBoundary(
                      key: _receiptKey,
                      child: Theme(
                        data: ThemeData.light(),
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trinidad Municipal College',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  receipt.title,
                                  style: const TextStyle(fontSize: 17),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: QrImageView(
                                    data: receipt.qrPayload,
                                    size: 210,
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                                Center(
                                  child: SelectableText(
                                    receipt.transactionCode,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(receipt.instructions),
                                const Divider(height: 28),
                                ...ReceiptExporter.details(receipt).entries.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 9),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${entry.key}: ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: entry.value.isEmpty
                                                ? '-'
                                                : entry.value,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(height: 28),
                                const Text(
                                  'Equipment',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ...receipt.items.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item['name']} × ${item['quantity']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Equipment #${item['equipment_id']}',
                                        ),
                                        Text(
                                          'Category: ${item['category'] ?? '-'}',
                                        ),
                                        Text(
                                          'Condition: ${item['condition'] ?? '-'}',
                                        ),
                                        if ('${item['pickup_location'] ?? ''}'
                                            .isNotEmpty)
                                          Text(
                                            'School pickup location: ${item['pickup_location']}',
                                          ),
                                        if ('${item['description'] ?? ''}'
                                            .isNotEmpty)
                                          Text('${item['description']}'),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Saved copies show the status at export time. Staff verify the current status in the system.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
