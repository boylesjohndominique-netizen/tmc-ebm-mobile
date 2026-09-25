import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';

class RequestEquipmentScreen extends StatefulWidget {
  final String equipmentId;
  const RequestEquipmentScreen({super.key, required this.equipmentId});

  @override
  State<RequestEquipmentScreen> createState() => _RequestEquipmentScreenState();
}

class _RequestEquipmentScreenState extends State<RequestEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  int _quantity = 1;
  DateTime? _borrowDate;
  DateTime? _returnDate;
  bool _loading = false;
  final _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickBorrowDate(DateTime firstAllowed) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: firstAllowed,
      firstDate: firstAllowed,
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked == null) return;
    setState(() {
      _borrowDate = picked;
      if (_returnDate != null && _returnDate!.isBefore(_borrowDate!)) {
        _returnDate = null;
      }
    });
  }

  Future<void> _pickReturnDate() async {
    if (_borrowDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a borrowing date first.')));
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _borrowDate!.add(const Duration(days: 1)),
      firstDate: _borrowDate!,
      lastDate: _borrowDate!.add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() => _returnDate = picked);
  }

  Future<void> _submit(int available) async {
    if (!_formKey.currentState!.validate()) return;
    if (_borrowDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a borrowing date.')));
      return;
    }
    if (_returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a return date.')));
      return;
    }
    if (_quantity > available) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Requested quantity exceeds availability.')));
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final appState = context.read<AppState>();
    final equipment = appState.equipmentById(widget.equipmentId)!;
    appState.submitBorrowRequest(
      eq: equipment,
      quantity: _quantity,
      borrowingDate: _borrowDate!,
      returnDate: _returnDate!,
      purpose: _purposeController.text.trim(),
      notes: _notesController.text.trim(),
    );

    setState(() => _loading = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Request Submitted'),
          ],
        ),
        content: const Text('Your borrowing request has been submitted successfully. Status: Pending'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final equipment = appState.equipmentById(widget.equipmentId);

    if (equipment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Equipment')),
        body: const Center(child: Text('Equipment not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Request Equipment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(12)),
                        child: Icon(equipment.icon, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(equipment.name, style: Theme.of(context).textTheme.titleMedium),
                            Text('${equipment.availableQuantity} available',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Quantity to Borrow', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton.filledTonal(
                      onPressed: _quantity < equipment.availableQuantity ? () => setState(() => _quantity++) : null,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Borrowing Date', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _DateSelector(
                  label: _borrowDate == null ? 'Select borrowing date' : _dateFormat.format(_borrowDate!),
                  onTap: () => _pickBorrowDate(DateTime.now()),
                ),
                const SizedBox(height: 16),
                Text('Return Date', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _DateSelector(
                  label: _returnDate == null ? 'Select return date' : _dateFormat.format(_returnDate!),
                  onTap: _pickReturnDate,
                ),
                const SizedBox(height: 20),
                Text('Purpose / Reason', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _purposeController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'e.g. Thesis presentation, org event...'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Purpose is required' : null,
                ),
                const SizedBox(height: 16),
                Text('Additional Notes (optional)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Any additional information...'),
                ),
                const SizedBox(height: 20),
                if (_borrowDate != null && _returnDate != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Request Summary', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('${equipment.name} × $_quantity'),
                        Text('${_dateFormat.format(_borrowDate!)} → ${_dateFormat.format(_returnDate!)}'),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Submit Request',
                  onPressed: () => _submit(equipment.availableQuantity),
                  loading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateSelector({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}
