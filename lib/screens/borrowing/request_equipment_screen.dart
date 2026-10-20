import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/equipment_icon.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a borrowing date first.')));
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

    // Guard: only admin-verified accounts can borrow.
    final appState = context.read<AppState>();
    if (appState.currentUser?.isPending == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Your account must be verified by an administrator before you can borrow equipment.'),
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_borrowDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a borrowing date.')));
      return;
    }
    if (_returnDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a return date.')));
      return;
    }
    if (_quantity > available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Requested quantity exceeds availability.')));
      return;
    }

    setState(() => _loading = true);

    final equipment = appState.equipmentById(widget.equipmentId);
    if (equipment == null) {
      setState(() => _loading = false);
      return;
    }

    final error = await appState.submitBorrowRequest(
      eq: equipment,
      quantity: _quantity,
      borrowingDate: _borrowDate!,
      returnDate: _returnDate!,
      purpose: _purposeController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (!mounted) return;
    showGlassDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GlassDialog(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: 'Request Submitted',
        message:
            'Your borrowing request has been submitted successfully. Status: Pending.',
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
      return LiquidScaffold(
        appBar: AppBar(title: const Text('Request Equipment')),
        body: const Center(child: Text('Equipment not found.')),
      );
    }

    final isPending = appState.currentUser?.isPending == true;

    return LiquidScaffold(
      appBar: AppBar(title: const Text('Request Equipment')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verification warning banner
                if (isPending) ...[
                  GlassPanel(
                    blur: 0,
                    radius: AppRadius.lg,
                    padding: const EdgeInsets.all(14),
                    shadows: AppShadows.card,
                    tint: AppColors.goldSoft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Account not yet verified. An administrator needs to verify your ID before you can borrow equipment. Go to Profile → ID Verification to submit your ID.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Equipment summary ───────────────────────────────────
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: EquipmentVisual(
                          equipment: equipment,
                          iconSize: 28,
                          iconColor: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md - 1),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              equipment.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text('${equipment.availableQuantity} available',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Quantity ────────────────────────────────────────────
                const GlassSectionLabel('Quantity to Borrow'),
                const SizedBox(height: 10),
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$_quantity unit${_quantity == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        onTap: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      _StepperButton(
                        icon: Icons.add_rounded,
                        onTap: _quantity < equipment.availableQuantity
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Dates ───────────────────────────────────────────────
                const GlassSectionLabel('Schedule'),
                const SizedBox(height: 10),
                _DateSelector(
                  icon: Icons.login_rounded,
                  label: _borrowDate == null
                      ? 'Select borrowing date'
                      : _dateFormat.format(_borrowDate!),
                  hasValue: _borrowDate != null,
                  onTap: () => _pickBorrowDate(DateTime.now()),
                ),
                const SizedBox(height: 10),
                _DateSelector(
                  icon: Icons.logout_rounded,
                  label: _returnDate == null
                      ? 'Select return date'
                      : _dateFormat.format(_returnDate!),
                  hasValue: _returnDate != null,
                  onTap: _pickReturnDate,
                ),
                const SizedBox(height: 22),

                // ── Purpose / notes ─────────────────────────────────────
                const GlassSectionLabel('Details'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _purposeController,
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Purpose — e.g. Thesis presentation, org event…',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Purpose is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Additional notes (optional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Summary ─────────────────────────────────────────────
                if (_borrowDate != null && _returnDate != null)
                  GlassPanel(
                    blur: 0,
                    radius: AppRadius.lg,
                    padding: const EdgeInsets.all(15),
                    shadows: AppShadows.card,
                    tint: AppColors.primarySoft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 7),
                            Text('Request Summary',
                                style: Theme.of(context).textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          '${equipment.name} × $_quantity',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_dateFormat.format(_borrowDate!)} → ${_dateFormat.format(_returnDate!)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                CustomButton(
                  label: isPending ? 'Verification Required' : 'Submit Request',
                  icon: isPending
                      ? Icons.lock_outline_rounded
                      : Icons.send_rounded,
                  onPressed: isPending
                      ? null
                      : () => _submit(equipment.availableQuantity),
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.primary : AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  const _DateSelector({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: hasValue ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color:
                      hasValue ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
