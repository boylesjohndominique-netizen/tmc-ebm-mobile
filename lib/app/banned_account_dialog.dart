import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'theme.dart';

/// Non-dismissible notice shown the moment an account is banned.
///
/// It explains the reason, lets the user send one appeal message to the
/// administrator, then signs them out. The backend already revoked the API
/// token, so the session cannot continue regardless — this makes the ending
/// explicit instead of letting requests fail silently.
class BannedAccountDialog extends StatefulWidget {
  const BannedAccountDialog({super.key});

  @override
  State<BannedAccountDialog> createState() => _BannedAccountDialogState();
}

class _BannedAccountDialogState extends State<BannedAccountDialog> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendAppeal() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Please write a message before sending.');
      return;
    }

    final app = context.read<AppState>();
    setState(() {
      _sending = true;
      _error = null;
    });

    final error = await app.submitBanAppeal(message);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _sending = false;
        _error = error;
      });
      return;
    }

    setState(() {
      _sending = false;
      _sent = true;
    });

    // Give the confirmation a beat to be read, then sign out.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) await _signOut();
  }

  Future<void> _signOut() async {
    await context.read<AppState>().logout();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final reason = context.watch<AppState>().banReason;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.block, size: 40, color: AppColors.danger),
        title: const Text('Account Banned'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_sent)
                const Text(
                  'Your appeal has been sent to the administrator for review. '
                  'You will be contacted once a decision is made.',
                )
              else ...[
                const Text(
                  'Your account has been banned by an administrator, so you can '
                  'no longer use the app.',
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Reason', style: textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(reason),
                ],
                const SizedBox(height: 16),
                const Text('You may send an appeal to the administrator:'),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  enabled: !_sending,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Explain why your account should be reinstated…',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
              ],
            ],
          ),
        ),
        actions: _sent
            ? [
                TextButton(onPressed: _signOut, child: const Text('Log Out')),
              ]
            : [
                TextButton(
                  onPressed: _sending ? null : _signOut,
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Log Out'),
                ),
                FilledButton(
                  onPressed: _sending ? null : _sendAppeal,
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Text('Send Appeal'),
                ),
              ],
      ),
    );
  }
}
