import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/auth_surface.dart';
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
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _rememberMe = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _identifierFocus.addListener(_refocus);
    _passwordFocus.addListener(_refocus);
  }

  void _refocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    final appState = context.read<AppState>();
    final error = await appState.login(identifier, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      appState.rememberMe = _rememberMe;
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      return;
    }

    // Backend asks for email verification — route to the verify screen.
    if (error.startsWith('EMAIL_VERIFICATION_REQUIRED:')) {
      final email = error.substring('EMAIL_VERIFICATION_REQUIRED:'.length);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email address first.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.of(context).pushNamed('/verify-email', arguments: email);
      return;
    }

    setState(() => _error = error);
  }

  InputDecoration _dec(String hint, IconData icon) =>
      InputDecoration(hintText: hint, prefixIcon: Icon(icon));

  @override
  Widget build(BuildContext context) {
    final identifierActive = _identifierFocus.hasFocus;
    final passwordActive = _passwordFocus.hasFocus;

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - 48).clamp(0.0, double.infinity),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Brand header ───────────────────────────────────────
                    const Entrance(child: AmbientLogoHeader()),
                    const SizedBox(height: 40),

                    // ── Headline with gradient ink + value proposition ────
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
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 33,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                height: 1.1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Elevated form card ────────────────────────────────
                    Entrance(
                      delay: 120,
                      child: AmbientFormCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_error != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger
                                        .withValues(alpha: 0.08),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md),
                                    border: Border.all(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          color: AppColors.danger, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: AppColors.danger,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // ── Identifier field with focus glow ─────
                              FocusGlow(
                                focused: identifierActive,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FieldLabel('Username or Email'),
                                    const SizedBox(height: 8),
                                    AutofillGroup(
                                      child: TextFormField(
                                        controller: _identifierController,
                                        focusNode: _identifierFocus,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.username,
                                          AutofillHints.email,
                                        ],
                                        onFieldSubmitted: (_) =>
                                            FocusScope.of(context)
                                                .requestFocus(_passwordFocus),
                                        textInputAction: TextInputAction.next,
                                        decoration: _dec(
                                          'Enter your username or email',
                                          Icons.person_outline_rounded,
                                        ),
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                                ? 'This field is required'
                                                : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // ── Password field with focus glow ───────
                              FocusGlow(
                                focused: passwordActive,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const FieldLabel('Password'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      obscureText: _obscure,
                                      autofillHints: const [
                                        AutofillHints.password
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your password',
                                        prefixIcon: const Icon(
                                            Icons.lock_outline_rounded),
                                        suffixIcon: IconButton(
                                          icon: Icon(_obscure
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded),
                                          onPressed: () => setState(
                                              () => _obscure = !_obscure),
                                        ),
                                      ),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Password is required'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // ── Remember me switch + forgot password ──
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                      onTap: () => setState(
                                          () => _rememberMe = !_rememberMe),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Switch.adaptive(
                                              value: _rememberMe,
                                              onChanged: (v) => setState(
                                                  () => _rememberMe = v),
                                              activeTrackColor:
                                                  AppColors.primary,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            Flexible(
                                              child: Text(
                                                'Remember me',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: () => Navigator.of(context)
                                          .pushNamed('/forgot-password'),
                                      child: const Text(
                                        'Forgot Password?',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // ── Primary CTA ───────────────────────────
                              CustomButton(
                                label: 'Login',
                                onPressed: _submit,
                                loading: _loading,
                              ),
                              const SizedBox(height: 20),

                              // ── Divider + secondary CTA ───────────────
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      'or',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              CustomButton(
                                label: 'Create an account',
                                outlined: true,
                                icon: Icons.person_add_alt_1_rounded,
                                onPressed: () => Navigator.of(context)
                                    .pushNamed('/register'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Trust footer ────────────────────────────────────────
                    Entrance(
                      delay: 200,
                      child: Center(
                        child: Text(
                          'Borrow smart. Return on time.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                  ),
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
