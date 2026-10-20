import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/motion.dart';
import '../../app/theme.dart';
import '../../data/api_service.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../widgets/auth_surface.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/id_upload_field.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/pressable.dart';
import '../../widgets/student_id_formatter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Step 0: Names (First, Middle, Last)
  // Step 1: Student ID & Contact Number
  // Step 2: Email Address (Verify Email First)
  // Step 3: Password + View Overall Details + Submit ID Now / Submit ID Later
  // Step 4: Submit ID Now (after account creation)
  int _step = 0;

  final _step0FormKey = GlobalKey<FormState>();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  // Step 2: Email verification state
  bool _codeSent = false;
  bool _sendingCode = false;
  bool _verifyingCode = false;
  String? _verifiedEmail;
  String? _emailStepError;
  String? _emailStepSuccess;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  // Step 4: Optional ID upload state ("Submit ID Now")
  bool _accountCreated = false;
  String? _idFrontPath;
  String? _idBackPath;
  String? _idError;
  bool _submittingId = false;

  bool get _isEmailVerified {
    final current = _emailController.text.trim().toLowerCase();
    return current.isNotEmpty &&
        _verifiedEmail != null &&
        _verifiedEmail!.toLowerCase() == current;
  }

  String get _fullName {
    final first = _firstNameController.text.trim();
    final middle = _middleNameController.text.trim();
    final last = _lastNameController.text.trim();
    return [first, if (middle.isNotEmpty) middle, last]
        .where((p) => p.isNotEmpty)
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final current = _emailController.text.trim().toLowerCase();
    if (_verifiedEmail != null && _verifiedEmail!.toLowerCase() != current) {
      setState(() {
        _verifiedEmail = null;
        _codeSent = false;
        _emailCodeController.clear();
        _emailStepError = null;
        _emailStepSuccess = null;
      });
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    _resendTimer?.cancel();
    _emailController.removeListener(_onEmailChanged);
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _idNumberController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _emailCodeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// 0–4 password strength score based on length and character mix.
  int _passwordScore(String pw) {
    if (pw.isEmpty) return 0;
    var score = 0;
    if (pw.length >= 8) score++;
    if (pw.length >= 11) score++;
    if (pw.contains(RegExp(r'[A-Z]')) && pw.contains(RegExp(r'[a-z]'))) score++;
    if (pw.contains(RegExp(r'\d'))) score++;
    if (pw.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    if (score > 4) score = 4;
    return score;
  }

  void _goToStep(int target) {
    FocusScope.of(context).unfocus();
    setState(() => _step = target);
  }

  void _nextFromStep0() {
    FocusScope.of(context).unfocus();
    if (_step0FormKey.currentState?.validate() ?? false) {
      _goToStep(1);
    }
  }

  void _nextFromStep1() {
    FocusScope.of(context).unfocus();
    if (_step1FormKey.currentState?.validate() ?? false) {
      _goToStep(2);
    }
  }

  Future<void> _sendEmailCode() async {
    FocusScope.of(context).unfocus();
    if (!(_step2FormKey.currentState?.validate() ?? false)) return;
    if (_sendingCode) return;

    final email = _emailController.text.trim();
    setState(() {
      _sendingCode = true;
      _emailStepError = null;
      _emailStepSuccess = null;
    });

    final res = await ApiService.instance.sendRegistrationCode(
      email: email,
      firstName: _firstNameController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _sendingCode = false);

    if (res.success) {
      _startResendTimer();
      setState(() {
        _codeSent = true;
        _emailStepSuccess =
            res.message ?? 'A 6-digit verification code was sent to $email.';
      });
    } else {
      setState(() {
        _emailStepError =
            res.message ?? 'Could not send verification code. Try again.';
      });
    }
  }

  Future<void> _verifyEmailCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final code = _emailCodeController.text.trim();
    if (code.length != 6) {
      setState(
          () => _emailStepError = 'Please enter the complete 6-digit code.');
      return;
    }
    if (_verifyingCode) return;

    setState(() {
      _verifyingCode = true;
      _emailStepError = null;
      _emailStepSuccess = null;
    });

    final res = await ApiService.instance.verifyRegistrationCode(
      email: email,
      code: code,
    );

    if (!mounted) return;
    setState(() => _verifyingCode = false);

    if (res.success) {
      _resendTimer?.cancel();
      setState(() {
        _verifiedEmail = email;
        _emailStepError = null;
        _emailStepSuccess =
            'Email verified! You can now proceed to the next step.';
      });
    } else {
      setState(() {
        _emailStepError = res.message ?? 'Invalid verification code.';
      });
    }
  }

  void _nextFromStep2() {
    FocusScope.of(context).unfocus();
    if (!(_step2FormKey.currentState?.validate() ?? false)) return;
    if (!_isEmailVerified) {
      setState(() {
        _emailStepError =
            'Please verify your email address first before continuing.';
      });
      return;
    }
    _goToStep(3);
  }

  void _showOverallDetailsSheet() {
    FocusScope.of(context).unfocus();
    final first = _firstNameController.text.trim();
    final middle = _middleNameController.text.trim();
    final last = _lastNameController.text.trim();
    final idNum = _idNumberController.text.trim();
    final contact = _contactController.text.trim();
    final email = _emailController.text.trim();

    showGlassSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlassSheetHandle(),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.assignment_ind_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Account Details',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      Text(
                        'Review your information before finishing.',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  _DetailSummaryRow(
                    icon: Icons.badge_outlined,
                    label: 'First Name',
                    value: first.isEmpty ? '—' : first,
                  ),
                  const Divider(height: 1),
                  _DetailSummaryRow(
                    icon: Icons.badge_outlined,
                    label: 'Middle Name',
                    value: middle.isEmpty ? '—' : middle,
                  ),
                  const Divider(height: 1),
                  _DetailSummaryRow(
                    icon: Icons.badge_outlined,
                    label: 'Last Name',
                    value: last.isEmpty ? '—' : last,
                  ),
                  const Divider(height: 1),
                  _DetailSummaryRow(
                    icon: Icons.alternate_email_rounded,
                    label: 'Default Username',
                    value: first.isEmpty ? '—' : '@$first',
                  ),
                  const Divider(height: 1),
                  _DetailSummaryRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Student ID',
                    value: idNum.isEmpty ? '—' : idNum,
                  ),
                  const Divider(height: 1),
                  _DetailSummaryRow(
                    icon: Icons.phone_outlined,
                    label: 'Contact Number',
                    value: contact.isEmpty ? '—' : contact,
                  ),
                  const Divider(height: 1),
                  _DetailSummaryRow(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    value: email.isEmpty ? '—' : email,
                    trailing: _isEmailVerified
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            CustomButton(
              label: 'Done Reviewing',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  /// Registers the student account and signs them in. Returns true on success.
  Future<bool> _ensureAccountRegistered() async {
    if (_accountCreated) return true;
    if (_loading) return false;
    FocusScope.of(context).unfocus();

    if (!(_step3FormKey.currentState?.validate() ?? false)) {
      return false;
    }

    setState(() => _loading = true);
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final idNumber = _idNumberController.text.trim();
    final contact = _contactController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final appState = context.read<AppState>();
    final error = await appState.register(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      idNumber: idNumber,
      email: email,
      username: firstName,
      contactNumber: contact,
      userType: UserType.student,
      password: password,
      emailVerified: _isEmailVerified,
    );

    if (!mounted) return false;
    setState(() => _loading = false);

    if (error == null) {
      setState(() => _accountCreated = true);
      return true;
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
    return false;
  }

  Future<void> _handleSubmitIdNowChoice() async {
    final ok = await _ensureAccountRegistered();
    if (!ok || !mounted) return;
    _goToStep(4);
  }

  Future<void> _handleSubmitIdLaterChoice() async {
    final ok = await _ensureAccountRegistered();
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account created! You can submit your ID anytime in Profile & Settings. Borrowing is locked until your ID is verified.',
        ),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
  }

  Future<void> _uploadIdAndFinish() async {
    if (_idFrontPath == null || _idBackPath == null) {
      setState(() {
        _idError =
            'Please capture both Front and Back ID photos, or tap "Continue Without ID" to submit later in Profile.';
      });
      return;
    }
    if (_submittingId) return;

    setState(() {
      _submittingId = true;
      _idError = null;
    });

    final error = await context.read<AppState>().submitIdVerification(
          idFrontPath: _idFrontPath!,
          idBackPath: _idBackPath!,
        );

    if (!mounted) return;
    setState(() => _submittingId = false);

    if (error != null) {
      setState(() => _idError = error);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'ID submitted for admin review! You can browse equipment now; borrowing unlocks once verified.',
        ),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
  }

  void _skipIdForNowAndFinish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Welcome! You can browse equipment freely and submit your ID anytime in Profile & Settings.',
        ),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/main', (r) => false);
  }

  InputDecoration _dec(String hint, IconData icon) =>
      InputDecoration(hintText: hint, prefixIcon: Icon(icon));

  void _handleBackButton() {
    if (_step == 4) {
      _skipIdForNowAndFinish();
      return;
    }
    if (_step > 0 && !_accountCreated) {
      _goToStep(_step - 1);
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = [
      'Your Name',
      'Student Details',
      'Verify Email',
      'Password & ID',
      'Submit School ID',
    ];
    final stepSubtitles = [
      'Step 1 of 4 · Enter your first, middle, and last name.',
      'Step 2 of 4 · Enter your Student ID and contact number.',
      'Step 3 of 4 · Enter and verify your email address first.',
      'Step 4 of 4 · Set your password, review details, and choose when to submit your ID.',
      'Account Created · Upload your school ID now or continue to the app.',
    ];

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBackButton),
          title: const Text('Create Account'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Entrance(child: AmbientLogoHeader()),
                const SizedBox(height: 22),

                // ── Headline + Step Subtitle ──────────────────────────────
                Entrance(
                  delay: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.headlineGradient.createShader(bounds),
                        child: Text(
                          stepTitles[_step],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.9,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stepSubtitles[_step],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13.5,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── 4-Step Progress Bar ───────────────────────────────────
                if (_step < 4) ...[
                  _StepProgressIndicator(currentStep: _step, totalSteps: 4),
                  const SizedBox(height: 20),
                ],

                // ── Active Step Card ──────────────────────────────────────
                Entrance(
                  delay: 120,
                  child: AmbientFormCard(
                    child: AnimatedSwitcher(
                      duration: AppMotion.normal,
                      switchInCurve: AppMotion.emphasized,
                      child: switch (_step) {
                        0 => _buildStep0Names(context),
                        1 => _buildStep1StudentContact(context),
                        2 => _buildStep2EmailVerification(context),
                        3 => _buildStep3PasswordAndFinish(context),
                        _ => _buildStep4SubmitIdNow(context),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 0: First Name, Middle Name, Last Name
  // ---------------------------------------------------------------------------
  Widget _buildStep0Names(BuildContext context) {
    return Form(
      key: _step0FormKey,
      child: Column(
        key: const ValueKey('step-0'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('First Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _firstNameController,
            textInputAction: TextInputAction.next,
            decoration: _dec('Enter your first name', Icons.badge_outlined),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'First name is required'
                : null,
          ),
          const SizedBox(height: 16),
          const FieldLabel('Middle Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _middleNameController,
            textInputAction: TextInputAction.next,
            decoration:
                _dec('Enter your middle name (optional)', Icons.badge_outlined),
          ),
          const SizedBox(height: 16),
          const FieldLabel('Last Name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastNameController,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _nextFromStep0(),
            decoration: _dec('Enter your last name', Icons.badge_outlined),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Last name is required'
                : null,
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _firstNameController,
            builder: (context, value, _) {
              final previewUsername = value.text.trim();
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alternate_email_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        previewUsername.isEmpty
                            ? 'Your default username will be your first name.'
                            : 'Default username: @$previewUsername',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 22),
          CustomButton(
            label: 'Next',
            icon: Icons.arrow_forward_rounded,
            onPressed: _nextFromStep0,
          ),
          const SizedBox(height: 14),
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
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1: Student ID & Contact Number
  // ---------------------------------------------------------------------------
  Widget _buildStep1StudentContact(BuildContext context) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step-1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Student ID (00-000000)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _idNumberController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: const [StudentIdInputFormatter()],
            decoration: _dec('00-000000', Icons.confirmation_number_outlined),
            validator: validateStudentId,
          ),
          const SizedBox(height: 16),
          const FieldLabel('Contact Number'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _nextFromStep1(),
            decoration: _dec('Enter your contact number', Icons.phone_outlined),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Contact number is required';
              }
              final regex = RegExp(r'^[0-9]{10,11}$');
              if (!regex.hasMatch(v.trim())) {
                return 'Enter a valid 10–11 digit contact number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Previous',
                  outlined: true,
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => _goToStep(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _nextFromStep1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2: Email Address (Verify Email First)
  // ---------------------------------------------------------------------------
  Widget _buildStep2EmailVerification(BuildContext context) {
    final verified = _isEmailVerified;

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey('step-2'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Email Address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: _dec('Enter your email', Icons.email_outlined).copyWith(
              suffixIcon: verified
                  ? const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                    )
                  : null,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Email is required';
              }
              final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!regex.hasMatch(v.trim())) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          if (_emailStepError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _emailStepError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (_emailStepSuccess != null && !verified) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.success,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _emailStepSuccess!,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (verified) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email Verified',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_emailController.text.trim()} has been verified.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            CustomButton(
              label: _codeSent
                  ? (_resendSeconds > 0
                      ? 'Resend Code (${_resendSeconds}s)'
                      : 'Resend Verification Code')
                  : 'Send Verification Code',
              outlined: _codeSent,
              icon: Icons.send_rounded,
              loading: _sendingCode,
              onPressed:
                  (_codeSent && _resendSeconds > 0) ? null : _sendEmailCode,
            ),
            if (_codeSent) ...[
              const SizedBox(height: 18),
              const FieldLabel('6-Digit Verification Code'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCodeController,
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
                  counterText: '',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                ),
                onChanged: (v) {
                  if (v.trim().length == 6) {
                    _verifyEmailCode();
                  }
                },
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: 'Verify Email Code',
                icon: Icons.check_circle_outline_rounded,
                loading: _verifyingCode,
                onPressed: _verifyEmailCode,
              ),
            ],
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Previous',
                  outlined: true,
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => _goToStep(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _nextFromStep2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 3: Password + View Overall Details + Submit ID Now / Submit ID Later
  // ---------------------------------------------------------------------------
  Widget _buildStep3PasswordAndFinish(BuildContext context) {
    return Form(
      key: _step3FormKey,
      child: Column(
        key: const ValueKey('step-3'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure1,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Enter your password (min. 8 characters)',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure1
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 8) ? 'Minimum 8 characters' : null,
          ),

          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _passwordController,
            builder: (context, value, _) => _buildStrengthMeter(value.text),
          ),

          const SizedBox(height: 16),
          const FieldLabel('Confirm Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure2,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure2
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
            validator: (v) => (v != _passwordController.text)
                ? 'Passwords do not match'
                : null,
          ),
          const SizedBox(height: 18),

          // ── View Overall Details Button ───────────────────────────────────
          CustomButton(
            label: 'View Overall Details',
            outlined: true,
            icon: Icons.assignment_ind_outlined,
            onPressed: _showOverallDetailsSheet,
          ),
          const SizedBox(height: 18),

          // ── ID Verification Choice Info Box ───────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.goldSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Choose whether to submit your school ID now or later in Profile & Settings. Until an admin verifies your ID, you can browse equipment freely but cannot request to borrow equipment.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Submit ID Now / Submit ID Later Buttons ───────────────────────
          CustomButton(
            label: 'Submit ID Now',
            icon: Icons.badge_outlined,
            loading: _loading,
            onPressed: _loading ? null : _handleSubmitIdNowChoice,
          ),
          const SizedBox(height: 10),
          CustomButton(
            label: 'Submit ID Later',
            outlined: true,
            icon: Icons.schedule_rounded,
            onPressed: _loading ? null : _handleSubmitIdLaterChoice,
          ),
          const SizedBox(height: 14),
          CustomButton(
            label: 'Previous',
            outlined: true,
            icon: Icons.arrow_back_rounded,
            onPressed: _loading ? null : () => _goToStep(2),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4: Submit ID Now (Front & Back capture + Option to Continue)
  // ---------------------------------------------------------------------------
  Widget _buildStep4SubmitIdNow(BuildContext context) {
    return Column(
      key: const ValueKey('step-4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Welcome, $_fullName! Capture the front and back of your school ID below. You can still enter the app even while unverified — borrowing equipment simply requires admin verification.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: IdPhotoField(
                label: 'Front of ID',
                imagePath: _idFrontPath,
                onChanged: (p) => setState(() {
                  _idFrontPath = p;
                  if (_idFrontPath != null && _idBackPath != null) {
                    _idError = null;
                  }
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: IdPhotoField(
                label: 'Back of ID',
                imagePath: _idBackPath,
                onChanged: (p) => setState(() {
                  _idBackPath = p;
                  if (_idFrontPath != null && _idBackPath != null) {
                    _idError = null;
                  }
                }),
              ),
            ),
          ],
        ),
        if (_idError != null) ...[
          const SizedBox(height: 12),
          Text(
            _idError!,
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 22),
        CustomButton(
          label: 'Submit ID & Enter App',
          icon: Icons.cloud_upload_outlined,
          loading: _submittingId,
          onPressed: _submittingId ? null : _uploadIdAndFinish,
        ),
        const SizedBox(height: 10),
        CustomButton(
          label: 'Continue Without ID (Submit in Profile)',
          outlined: true,
          icon: Icons.arrow_forward_rounded,
          onPressed: _submittingId ? null : _skipIdForNowAndFinish,
        ),
      ],
    );
  }

  Widget _buildStrengthMeter(String pw) {
    if (pw.isEmpty) return const SizedBox.shrink();
    final score = _passwordScore(pw);
    final index = (score - 1).clamp(0, 3);
    const labels = ['Weak', 'Fair', 'Good', 'Strong'];
    const colors = [
      AppColors.danger,
      AppColors.warning,
      AppColors.success,
      AppColors.primary,
    ];
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

class _StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isActive = index == currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: AppMotion.normal,
            curve: AppMotion.emphasized,
            height: 6,
            margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
            decoration: BoxDecoration(
              gradient:
                  (isCompleted || isActive) ? AppColors.premiumGradient : null,
              color: (isCompleted || isActive)
                  ? null
                  : AppColors.divider.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        );
      }),
    );
  }
}

class _DetailSummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _DetailSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
