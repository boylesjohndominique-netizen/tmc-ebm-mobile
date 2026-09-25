import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccess(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryBlue, size: 32),
          ),
          const SizedBox(height: 20),
          Text('Reset your password', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Enter your registered email address and we\'ll send you a link to reset your password.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(label: 'Send Recovery Link', onPressed: _submit, loading: _loading),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primaryBlue, size: 44),
        ),
        const SizedBox(height: 24),
        Text('Check your email', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          'A password recovery link has been sent to ${_emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        CustomButton(label: 'Back to Login', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
