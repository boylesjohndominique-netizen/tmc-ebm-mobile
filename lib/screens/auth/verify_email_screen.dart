import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/api_service.dart';
import '../../state/app_state.dart';
import '../../widgets/auth_surface.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/pressable.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _successMessage;

  // Countdown timer for resending verification code
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Please enter the complete 6-digit code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    final res = await ApiService.instance.verifyEmail(
      email: widget.email,
      code: code,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      // Backend now returns a token+user on successful verification so we can
      // auto-login and navigate straight to the dashboard.
      final appState = context.read<AppState>();
      final loginErr = await appState.loginWithTokenPayload(res.data);
      if (!mounted) return;
      if (loginErr == null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
      } else {
        // Fallback: token missing – send to login.
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      }
    } else {
      setState(() => _error = res.message ?? 'Verification failed.');
    }
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _resending) return;

    setState(() {
      _resending = true;
      _error = null;
      _successMessage = null;
    });

    final res =
        await ApiService.instance.resendVerification(email: widget.email);

    if (!mounted) return;
    setState(() => _resending = false);

    if (res.success) {
      _startTimer();
      setState(() {
        _successMessage = 'A fresh 6-digit code has been sent to your Gmail.';
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to resend code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Verify Email'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - 48).clamp(0.0, double.infinity),
                ),
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
                        child: const Icon(Icons.mark_email_unread_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Headline ──────────────────────────────────────────────
                    Entrance(
                      delay: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDeep
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Check your inbox',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.9,
                                height: 1.1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.5),
                              children: [
                                const TextSpan(
                                    text:
                                        "We've sent a 6-digit verification code and link to\n"),
                                TextSpan(
                                  text: widget.email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Card ──────────────────────────────────────────────────
                    Entrance(
                      delay: 120,
                      child: AmbientFormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.danger.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: AppColors.danger, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: AppColors.danger,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_successMessage != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                      color: AppColors.success
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: AppColors.success,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _successMessage!,
                                        style: const TextStyle(
                                            color: AppColors.success,
                                            fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const FieldLabel('6-Digit Verification Code'),
                            const SizedBox(height: 8),
                            FocusGlow(
                              focused: _focusNode.hasFocus,
                              child: TextFormField(
                                controller: _codeController,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 10,
                                ),
                                decoration: InputDecoration(
                                  hintText: '000000',
                                  hintStyle: TextStyle(
                                    fontSize: 28,
                                    letterSpacing: 10,
                                    color: Colors.grey.withValues(alpha: 0.4),
                                  ),
                                  counterText: '',
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                                onChanged: (val) {
                                  if (val.length == 6) {
                                    _verifyCode();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              label: 'Verify Code',
                              onPressed: _verifyCode,
                              loading: _loading,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: _secondsRemaining > 0
                                  ? Text(
                                      'Resend code in ${_secondsRemaining}s',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    )
                                  : Pressable(
                                      onTap: _resending ? null : _resendCode,
                                      child: Text(
                                        _resending
                                            ? 'Sending...'
                                            : 'Resend Code',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Help info ─────────────────────────────────────────────
                    Entrance(
                      delay: 180,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .cardColor
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You can either enter the 6-digit code above or click the direct verification link in the email sent to your Gmail account.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.4),
                              ),
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
      ),
    );
  }
}
