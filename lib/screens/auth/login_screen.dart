import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pressable.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _rememberMe = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    await Future.delayed(const Duration(milliseconds: 500));
    final error = appState.login(_identifierController.text, _passwordController.text);
    appState.rememberMe = _rememberMe;
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
  }

  void _fillDemo(String email) {
    _identifierController.text = email;
    _passwordController.text = 'password123';
    setState(() {});
  }

  InputDecoration _dec({String? hint, IconData? icon, Widget? suffix}) => InputDecoration(
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffix,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Entrance(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.primaryGlow,
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Entrance(
                      delay: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back', style: Theme.of(context).textTheme.headlineLarge),
                          const SizedBox(height: 6),
                          Text('Sign in to continue to TMCEBMS',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Entrance(
                      delay: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!,
                                        style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text('Username or Email', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _dec(hint: 'e.g. student@tmc.edu', icon: Icons.person_outline_rounded),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'This field is required' : null,
                          ),
                          const SizedBox(height: 16),
                          Text('Password', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            decoration: _dec(
                              hint: 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                    ),
                                    const Flexible(
                                      child: Text('Remember me',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13, color: AppColors.textSecondary)),
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pushNamed('/forgot-password'),
                                  child: const Text('Forgot Password?',
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CustomButton(label: 'Login', onPressed: _submit, loading: _loading),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Demo accounts (tap to fill)',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ActionChip(
                                        label: const Text('Student'),
                                        onPressed: () => _fillDemo('student@tmc.edu')),
                                    ActionChip(
                                        label: const Text('Faculty'),
                                        onPressed: () => _fillDemo('faculty@tmc.edu')),
                                    ActionChip(
                                        label: const Text('Staff'),
                                        onPressed: () => _fillDemo('staff@tmc.edu')),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text('Password: password123',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text("Don't have an account?",
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pushNamed('/register'),
                                  child: const Text('Register'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
