import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'app_navigator.dart';
import 'banned_account_dialog.dart';

/// Watches [AppState] and, when the account transitions to banned, shows the
/// non-dismissible ban/appeal dialog above whatever screen is open. The
/// dialog signs the user out, which clears the flag and lets the app return
/// to the login flow.
class BanGuard extends StatefulWidget {
  final Widget child;

  const BanGuard({super.key, required this.child});

  @override
  State<BanGuard> createState() => _BanGuardState();
}

class _BanGuardState extends State<BanGuard> {
  AppState? _app;
  bool _showing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppState>();
    if (!identical(app, _app)) {
      _app?.removeListener(_onStateChanged);
      _app = app;
      _app!.addListener(_onStateChanged);
      _onStateChanged();
    }
  }

  void _onStateChanged() {
    final app = _app;
    if (app == null) return;

    if (app.accountBanned) {
      if (_showing) return;
      _showing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showDialog());
    } else {
      _showing = false;
    }
  }

  Future<void> _showDialog() async {
    final navigator = appNavigatorKey.currentState;
    if (!mounted || navigator == null || _app?.accountBanned != true) {
      _showing = false;
      return;
    }

    await showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => const BannedAccountDialog(),
    );

    _showing = false;
    if (mounted && _app?.accountBanned == true) _onStateChanged();
  }

  @override
  void dispose() {
    _app?.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
