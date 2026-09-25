import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _contactController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser!;
    _nameController = TextEditingController(text: user.fullName);
    _emailController = TextEditingController(text: user.email);
    _contactController = TextEditingController(text: user.contactNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    context.read<AppState>().updateProfile(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          contactNumber: _contactController.text.trim(),
        );
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
                    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Contact Number', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Contact number is required' : null,
                ),
                const SizedBox(height: 24),
                CustomButton(label: 'Save Changes', onPressed: _save, loading: _loading),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
