import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _o1 = true, _o2 = true, _o3 = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final appState = context.read<AppState>();
    await Future.delayed(const Duration(milliseconds: 500));
    final error = appState.changePassword(_currentController.text, _newController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
    Navigator.of(context).pop();
  }

  Widget _field(TextEditingController controller, String hint, bool obscure, VoidCallback toggle,
      String? Function(String?) validator) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
          onPressed: toggle,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Password', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _field(_currentController, 'Enter current password', _o1, () => setState(() => _o1 = !_o1),
                    (v) => (v == null || v.isEmpty) ? 'Current password is required' : null),
                const SizedBox(height: 16),
                const Text('New Password', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _field(_newController, 'Enter new password', _o2, () => setState(() => _o2 = !_o2),
                    (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null),
                const SizedBox(height: 16),
                const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _field(_confirmController, 'Re-enter new password', _o3, () => setState(() => _o3 = !_o3),
                    (v) => (v != _newController.text) ? 'Passwords do not match' : null),
                const SizedBox(height: 24),
                CustomButton(label: 'Update Password', onPressed: _submit, loading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
