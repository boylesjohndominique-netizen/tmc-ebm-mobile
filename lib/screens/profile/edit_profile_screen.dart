import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../data/api_service.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/student_id_formatter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;
  String? _pickedAvatarPath;
  bool _removeAvatar = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    if (user == null) {
      _nameController = TextEditingController();
      _idNumberController = TextEditingController();
      _emailController = TextEditingController();
      _contactController = TextEditingController();
      return;
    }
    _nameController = TextEditingController(text: user.fullName);
    _idNumberController =
        TextEditingController(text: formatStudentId(user.idNumber));
    _emailController = TextEditingController(text: user.email);
    _contactController = TextEditingController(text: user.contactNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      setState(() {
        _pickedAvatarPath = file.path;
        _removeAvatar = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not select photo.')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final nameParts = _nameController.text.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : firstName;

    final error = await context.read<AppState>().updateProfile(
          firstName: firstName,
          lastName: lastName,
          idNumber: _idNumberController.text.trim(),
          contactNumber: _contactController.text.trim(),
          avatarPath: _pickedAvatarPath,
          removeAvatar: _removeAvatar,
        );

    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Profile updated successfully.'),
        backgroundColor: error != null ? AppColors.danger : null,
      ),
    );
    if (error == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final currentAvatarUrl =
        (!_removeAvatar && _pickedAvatarPath == null) ? user?.avatarUrl : null;

    return LiquidScaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile picture section ───────────────────────────────
                const GlassSectionLabel('Profile picture'),
                const SizedBox(height: 10),
                GlassPanel(
                  blur: 22,
                  strong: true,
                  radius: AppRadius.xl,
                  shadows: AppShadows.floating,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.premiumGradient,
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.primarySoft,
                          child: _pickedAvatarPath != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_pickedAvatarPath!),
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (currentAvatarUrl != null &&
                                      currentAvatarUrl.isNotEmpty)
                                  ? ClipOval(
                                      child: Image.network(
                                        currentAvatarUrl,
                                        headers: ApiConfig.mediaHeaders,
                                        width: 68,
                                        height: 68,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Text(
                                          user?.initials ?? '?',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      user?.initials ?? '?',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickAvatar(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined,
                                  size: 17),
                              label: const Text('Gallery'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickAvatar(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined,
                                  size: 17),
                              label: const Text('Camera'),
                            ),
                            if (_pickedAvatarPath != null ||
                                (currentAvatarUrl != null &&
                                    currentAvatarUrl.isNotEmpty))
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _pickedAvatarPath = null;
                                  _removeAvatar = true;
                                }),
                                style: TextButton.styleFrom(
                                    foregroundColor: AppColors.danger),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 17),
                                label: const Text('Remove'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                const GlassSectionLabel('Personal information'),
                const SizedBox(height: 10),
                GlassPanel(
                  blur: 22,
                  strong: true,
                  radius: AppRadius.xl,
                  shadows: AppShadows.floating,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Full Name',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_rounded),
                          hintText: 'Enter your full name',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Student ID',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _idNumberController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: const [StudentIdInputFormatter()],
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined),
                          hintText: '00-000000',
                        ),
                        validator: validateStudentId,
                      ),
                      const SizedBox(height: 16),
                      Text('Email',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'Enter your email',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Contact Number',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: 'Enter your contact number',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Contact number is required'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                CustomButton(
                  label: 'Save Changes',
                  icon: Icons.check_rounded,
                  onPressed: _save,
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
