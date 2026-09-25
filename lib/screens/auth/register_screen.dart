import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  UserType _userType = UserType.student;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final appState = context.read<AppState>();
    await Future.delayed(const Duration(milliseconds: 600));
    final error = appState.register(
          fullName: _fullNameController.text.trim(),
          idNumber: _idNumberController.text.trim(),
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          contactNumber: _contactController.text.trim(),
          userType: _userType,
          password: _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Registration Successful'),
          ],
        ),
        content: const Text('Your account has been created. You can now log in using your credentials.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) =>
      InputDecoration(hintText: hint, prefixIcon: Icon(icon));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join TMCEBMS', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Fill in your details to get started', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _dec('Full Name', Icons.badge_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _idNumberController,
                  decoration: _dec('Student / Employee ID', Icons.confirmation_number_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'ID number is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _dec('Email Address', Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _usernameController,
                  decoration: _dec('Username', Icons.alternate_email_rounded),
                  validator: (v) => (v == null || v.trim().length < 4) ? 'Minimum 4 characters' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: _dec('Contact Number', Icons.phone_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Contact number is required';
                    final regex = RegExp(r'^[0-9]{10,11}$');
                    if (!regex.hasMatch(v.trim())) return 'Enter a valid contact number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Text('User Type', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: UserType.values.map((t) {
                    final selected = _userType == t;
                    return ChoiceChip(
                      label: Text(t.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _userType = t),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure1 ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                  validator: (v) => (v != _passwordController.text) ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 24),
                CustomButton(label: 'Create Account', onPressed: _submit, loading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
