import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/api_service.dart';
import '../../widgets/auth_surface.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pressable.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _loading = false;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _successMessage;

  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_refocus);
    _codeFocus.addListener(_refocus);
    _passwordFocus.addListener(_refocus);
    _confirmFocus.addListener(_refocus);
  }

  void _refocus() {
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _codeFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  /// Step 1: Send 6-digit reset code to user's Gmail
  Future<void> _sendResetCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await ApiService.instance.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      setState(() {
        _codeSent = true;
        _successMessage = 'A 6-digit password reset code has been sent to your Gmail.';
      });
      _startTimer();
    } else {
      setState(() => _error = res.message ?? 'Failed to send reset code.');
    }
  }

  /// Resend code
  Future<void> _resendCode() async {
    if (_resendSeconds > 0 || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await ApiService.instance.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      _startTimer();
      setState(() {
        _successMessage = 'A new reset code has been sent to your Gmail.';
      });
    } else {
      setState(() => _error = res.message ?? 'Failed to resend code.');
    }
  }

  /// Step 2: Submit code & new password to backend
  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await ApiService.instance.resetPassword(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Expanded(child: Text('Password Reset Successful')),
            ],
          ),
          content: const Text(
            'Your password has been reset successfully. You can now sign in with your new password.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      setState(() => _error = res.message ?? 'Password reset failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_codeSent ? 'Enter Reset Code' : 'Forgot Password'),
      ),
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
                ),
                child: _codeSent ? _buildResetForm(context) : _buildEmailForm(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1: Request email
  Widget _buildEmailForm(BuildContext context) {
    final emailActive = _emailFocus.hasFocus;

    return Column(
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
            child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 20),

        Entrance(
          delay: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                ).createShader(bounds),
                child: const Text(
                  'Reset password',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Enter your registered Gmail address and we'll send you a 6-digit code to reset your password.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Entrance(
          delay: 120,
          child: AmbientFormCard(
            child: Form(
              key: _emailFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const FieldLabel('Gmail / Email Address'),
                  const SizedBox(height: 8),
                  FocusGlow(
                    focused: emailActive,
                    child: TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _sendResetCode(),
                      decoration: const InputDecoration(
                        hintText: 'you@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                        if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    label: 'Send Reset Code',
                    onPressed: _sendResetCode,
                    loading: _loading,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        Entrance(
          delay: 200,
          child: Center(
            child: Text(
              'A code will be sent to your Gmail inbox within seconds.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 2: Enter 6-digit code and new password
  Widget _buildResetForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Entrance(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8C4C), Color(0xFFEF4455)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(Icons.pin_rounded, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 20),

        Entrance(
          delay: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDeep],
                ).createShader(bounds),
                child: const Text(
                  'Set new password',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Enter the 6-digit reset code sent to ${_emailController.text.trim()} and choose a new password.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Entrance(
          delay: 120,
          child: AmbientFormCard(
            child: Form(
              key: _resetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),

                  if (_successMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppColors.success, fontSize: 13),
                      ),
                    ),

                  const FieldLabel('6-Digit Reset Code'),
                  const SizedBox(height: 8),
                  FocusGlow(
                    focused: _codeFocus.hasFocus,
                    child: TextFormField(
                      controller: _codeController,
                      focusNode: _codeFocus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                      ),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        counterText: '',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().length != 6) {
                          return 'Enter 6-digit code';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  const FieldLabel('New Password'),
                  const SizedBox(height: 8),
                  FocusGlow(
                    focused: _passwordFocus.hasFocus,
                    child: TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'At least 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  const FieldLabel('Confirm New Password'),
                  const SizedBox(height: 8),
                  FocusGlow(
                    focused: _confirmFocus.hasFocus,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocus,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        prefixIcon: const Icon(Icons.lock_reset_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    label: 'Update Password',
                    onPressed: _resetPassword,
                    loading: _loading,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: _resendSeconds > 0
                        ? Text(
                            'Resend code in ${_resendSeconds}s',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          )
                        : Pressable(
                            onTap: _loading ? null : _resendCode,
                            child: const Text(
                              'Resend Code',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
