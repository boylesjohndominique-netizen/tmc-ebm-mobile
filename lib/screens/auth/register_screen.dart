import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../widgets/auth_surface.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pressable.dart';

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
  // One key per text field, in tab order, used to scroll to the first error.
  final List<GlobalKey<FormFieldState<String>>> _fieldKeys =
      List.generate(7, (_) => GlobalKey<FormFieldState<String>>());
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

  /// 0–4 password strength score based on length and character mix.
  int _passwordScore(String pw) {
    if (pw.isEmpty) return 0;
    var score = 0;
    if (pw.length >= 6) score++;
    if (pw.length >= 10) score++;
    if (pw.contains(RegExp(r'[A-Z]')) && pw.contains(RegExp(r'[a-z]'))) score++;
    if (pw.contains(RegExp(r'\d'))) score++;
    if (pw.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    if (score > 4) score = 4;
    return score;
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState!.validate();

    if (!formValid) {
      // Give the frame a beat to lay out validation errors, then reveal the
      // first problem area so users always know what to fix next.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final key in _fieldKeys) {
          final state = key.currentState;
          if (state != null && state.hasError) {
            Scrollable.ensureVisible(
              state.context,
              duration: AppMotion.normal,
              curve: AppMotion.emphasized,
              alignment: 0.2,
            );
            break;
          }
        }
      });
      return;
    }

    setState(() => _loading = true);
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();
    final contact = _contactController.text.trim();

    // Register through the backend API — creates a Pending student account
    // and emails a 6-digit verification code. No local fallback: the same
    // database powers the admin website.
    final appState = context.read<AppState>();
    final error = await appState.register(
      fullName: fullName,
      idNumber: _idNumberController.text.trim(),
      email: email,
      username: username,
      contactNumber: contact,
      userType: UserType.student,
      password: password,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      // Navigate to verification screen with email pre-filled.
      Navigator.of(context).pushReplacementNamed(
        '/verify-email',
        arguments: email,
      );
      return;
    }

    final isAlreadyTaken = error.toLowerCase().contains('already been taken');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAlreadyTaken
              ? 'This account already exists! Please log in instead.'
              : error,
        ),
        backgroundColor: AppColors.danger,
        action: isAlreadyTaken
            ? SnackBarAction(
                label: 'LOG IN',
                textColor: Colors.white,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) =>
      InputDecoration(hintText: hint, prefixIcon: Icon(icon));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: AmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Entrance(child: AmbientLogoHeader()),
                  const SizedBox(height: 28),

                  // ── Headline with gradient ink ───────────────────────────
                  Entrance(
                    delay: 60,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDeep],
                      ).createShader(bounds),
                      child: const Text(
                        'Join TMCEBMS',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.9,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Elevated form card ────────────────────────────────────
                  Entrance(
                    delay: 120,
                    child: AmbientFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FieldLabel('Full Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: _fieldKeys[0],
                            controller: _fullNameController,
                            decoration: _dec('Enter your full name', Icons.badge_outlined),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Student / Employee ID'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: _fieldKeys[1],
                            controller: _idNumberController,
                            decoration:
                                _dec('Enter your ID number', Icons.confirmation_number_outlined),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'ID number is required' : null,
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Email Address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: _fieldKeys[2],
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: _dec('Enter your email', Icons.email_outlined),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                              if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Username'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: _fieldKeys[3],
                            controller: _usernameController,
                            autofillHints: const [AutofillHints.newUsername],
                            decoration: _dec('Enter your username', Icons.alternate_email_rounded),
                            validator: (v) =>
                                (v == null || v.trim().length < 4) ? 'Minimum 4 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Contact Number'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: _fieldKeys[4],
                            controller: _contactController,
                            keyboardType: TextInputType.phone,
                            decoration: _dec('Enter your contact number', Icons.phone_outlined),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Contact number is required';
                              final regex = RegExp(r'^[0-9]{10,11}$');
                              if (!regex.hasMatch(v.trim())) return 'Enter a valid contact number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          const FieldLabel('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: _fieldKeys[5],
                            controller: _passwordController,
                            obscureText: _obscure1,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'Enter your password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure1
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded),
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                          ),

                          // ── Live password strength meter ────────────────
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _passwordController,
                            builder: (context, value, _) =>
                                _buildStrengthMeter(value.text),
                          ),

                          const SizedBox(height: 16),
                          const FieldLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: _fieldKeys[6],
                            controller: _confirmController,
                            obscureText: _obscure2,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              hintText: 'Re-enter your password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure2
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded),
                                onPressed: () => setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                            validator: (v) =>
                                (v != _passwordController.text) ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 24),

                          // ── Primary CTA ───────────────────────────────────
                          CustomButton(
                              label: 'Create Account', onPressed: _submit, loading: _loading),
                          const SizedBox(height: 14),

                          // ── Divider + secondary CTA ───────────────────────
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or', style: Theme.of(context).textTheme.bodySmall),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 14),
                          CustomButton(
                            label: 'I already have an account',
                            outlined: true,
                            icon: Icons.login_rounded,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthMeter(String pw) {
    if (pw.isEmpty) return const SizedBox.shrink();
    final score = _passwordScore(pw);
    final index = (score - 1).clamp(0, 3);
    const labels = ['Weak', 'Fair', 'Good', 'Strong'];
    const colors = [AppColors.danger, AppColors.warning, AppColors.success, AppColors.primary];
    final color = colors[index];
    final activeBars = score.clamp(1, 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: AppMotion.normal,
                  curve: AppMotion.emphasized,
                  height: 4,
                  margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i < activeBars ? color : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
