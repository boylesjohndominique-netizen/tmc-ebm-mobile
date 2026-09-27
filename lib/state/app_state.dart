import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_mappers.dart';
import '../data/api_service.dart';
import '../data/realtime_service.dart';
import '../models/borrowing_transaction.dart';
import '../models/equipment.dart';
import '../models/notification_item.dart';
import '../models/user.dart';

/// Single source of truth for the mobile app, backed entirely by the Laravel
/// API (shared MySQL database with the admin web system).
///
/// Realtime: the app subscribes to the user's private Reverb channel;
/// 'notification.created' events trigger an immediate refetch of the
/// notification feed. A lightweight polling cycle (45s) additionally keeps
/// borrowings fresh so admin approvals appear even without a socket.
class AppState extends ChangeNotifier {
  AppState() {
    _bootstrap();
  }

  // ---------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------
  AppUser? currentUser;
  bool rememberMe = false;
  bool get isLoggedIn => currentUser != null;

  bool _restoringSession = true;

  /// True while the app is checking for a persisted session at startup.
  bool get restoringSession => _restoringSession;

  // ---------------------------------------------------------------------
  // Data (all fetched from the backend)
  // ---------------------------------------------------------------------
  List<Equipment> _equipment = [];
  List<BorrowingTransaction> _transactions = [];
  List<AppNotification> _notifications = [];

  bool _loadingEquipment = false;

  bool get isLoadingEquipment => _loadingEquipment;
  List<Equipment> get equipment => List.unmodifiable(_equipment);

  Equipment? equipmentById(String id) {
    for (final e in _equipment) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<String> get categories =>
      _equipment.map((e) => e.category).toSet().toList()..sort();

  List<BorrowingTransaction> get transactions =>
      List.unmodifiable(_transactions);

  List<BorrowingTransaction> get pendingAndApproved => _transactions
      .where((t) => t.status == RequestStatus.pending || t.status == RequestStatus.approved)
      .toList();

  List<BorrowingTransaction> get currentlyBorrowed =>
      _transactions.where((t) => t.isCurrentlyBorrowed).toList();

  List<BorrowingTransaction> get borrowingHistory => _transactions
      .where((t) =>
          t.status == RequestStatus.completed ||
          t.status == RequestStatus.rejected ||
          t.status == RequestStatus.cancelled)
      .toList();

  List<BorrowingTransaction> get returnHistory => _transactions
      .where((t) =>
          t.returnStatus == ReturnStatus.completed ||
          t.returnStatus == ReturnStatus.returnConfirmed)
      .toList();

  int get overdueCount => _transactions.where((t) => t.isOverdue).length;

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // ---------------------------------------------------------------------
  // Theme + onboarding flag
  // ---------------------------------------------------------------------
  bool _isDarkMode = false;
  bool _onboardingSeen = false;
  bool get isDarkMode => _isDarkMode;
  bool get onboardingSeen => _onboardingSeen;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _persistPrefs();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    _persistPrefs();
    notifyListeners();
  }

  void markOnboardingSeen() {
    if (_onboardingSeen) return;
    _onboardingSeen = true;
    _persistPrefs();
    notifyListeners();
  }

  Future<void> _persistPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tmc_dark_mode', _isDarkMode);
    await prefs.setBool('tmc_onboarding_seen', _onboardingSeen);
  }

  // ---------------------------------------------------------------------
  // Bootstrap: restore persisted session + theme, then load data
  // ---------------------------------------------------------------------
  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('tmc_dark_mode') ?? false;
    _onboardingSeen = prefs.getBool('tmc_onboarding_seen') ?? false;

    final userJson = prefs.getString('tmc_user');
    final token = await ApiService.instance.restoreToken();

    if (userJson != null && token != null && token.isNotEmpty) {
      try {
        currentUser = mapUser(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        currentUser = null;
      }
    }

    _restoringSession = false;
    notifyListeners();

    if (currentUser != null) {
      final fresh = await ApiService.instance.restoreSession();
      if (fresh != null) {
        currentUser = mapUser(fresh);
        await _persistUser();
        _startRealtime();
        await refreshAll();
      } else {
        // Token invalid/expired — fall back to the login screen.
        currentUser = null;
        notifyListeners();
      }
    }
  }

  Future<void> _persistUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'tmc_user',
      jsonEncode({
        'id': currentUser?.id,
        'first_name': currentUser?.fullName.split(' ').first ?? '',
        'last_name': currentUser?.fullName.split(' ').skip(1).join(' ') ?? '',
        'username': currentUser?.username ?? '',
        'email': currentUser?.email ?? '',
        'contact_number': currentUser?.contactNumber ?? '',
        'email_verified_at': currentUser!.emailVerified ? 'verified' : null,
        'account_status': currentUser?.accountStatus,
      }),
    );
  }

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  /// Returns null on success, or an error message.
  Future<String?> login(String identifier, String password) async {
    final res = await ApiService.instance.login(
      identifier: identifier,
      password: password,
    );

    if (res.requiresEmailVerification) {
      return 'EMAIL_VERIFICATION_REQUIRED:${res.unverifiedEmail ?? identifier}';
    }

    if (!res.success) return res.message ?? 'Login failed.';

    final user = res.data?['user'];
    if (user is Map<String, dynamic>) {
      currentUser = mapUser(user);
      await _persistUser();
      _startRealtime();
      await refreshAll();
      notifyListeners();
      return null;
    }
    return 'Login succeeded but the server returned an unexpected payload.';
  }

  /// Returns null on success, or an error message.
  Future<String?> register({
    required String fullName,
    required String idNumber,
    required String email,
    required String username,
    required String contactNumber,
    required UserType userType,
    required String password,
    String? idFrontPath,
    String? idBackPath,
  }) async {
    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'Student';

    final res = await ApiService.instance.register(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      contactNumber: contactNumber,
      password: password,
      passwordConfirmation: password,
    );

    if (!res.success) return res.message ?? 'Registration failed.';
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> updateProfile({
    required String firstName,
    required String lastName,
    String? contactNumber,
  }) async {
    final res = await ApiService.instance.updateProfile(
      firstName: firstName,
      lastName: lastName,
      contactNumber: contactNumber,
    );
    if (!res.success) return res.message ?? 'Could not update profile.';

    final fresh = res.data?['user'];
    if (fresh is Map<String, dynamic>) {
      currentUser = mapUser(fresh);
      await _persistUser();
    }
    notifyListeners();
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    final res = await ApiService.instance.changePassword(
      currentPassword: currentPassword,
      password: newPassword,
      passwordConfirmation: newPassword,
    );
    return res.success ? null : (res.message ?? 'Could not change password.');
  }

  Future<void> logout() async {
    await ApiService.instance.logout();
    RealtimeService.instance.disconnect();
    currentUser = null;
    _equipment = [];
    _transactions = [];
    _notifications = [];
    _stopPolling();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tmc_user');
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Realtime + polling
  // ---------------------------------------------------------------------
  StreamSubscription? _notifSub;
  Timer? _pollTimer;

  void _startRealtime() {
    final id = int.tryParse(currentUser?.id ?? '');
    if (id == null) return;

    RealtimeService.instance.connect(userId: id);
    _notifSub?.cancel();
    // A notification usually means an admin acted on the student's requests
    // (approval, rejection, return confirmation) — refetch both feeds.
    _notifSub = RealtimeService.instance.notificationStream.listen((_) {
      refreshNotifications();
      refreshBorrowings();
    });

    // Polling fallback keeps borrowings (admin approvals) fresh even if the
    // WebSocket is unreachable (e.g. behind a firewall on campus Wi-Fi).
    _startPolling();
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (isLoggedIn) {
        refreshBorrowings();
        refreshNotifications();
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ---------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------
  Future<void> refreshAll() async {
    await Future.wait([
      refreshEquipment(),
      refreshBorrowings(),
      refreshNotifications(),
    ]);
  }

  Future<void> refreshEquipment() async {
    _loadingEquipment = true;
    notifyListeners();

    final res = await ApiService.instance.equipmentList();
    if (res.success && res.data is List) {
      _equipment = (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(mapEquipment)
          .toList();
    }
    _loadingEquipment = false;
    notifyListeners();
  }

  Future<void> refreshBorrowings() async {
    final res = await ApiService.instance.myBorrowings();
    if (res.success && res.data is List) {
      _transactions = (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(mapBorrowing)
          .toList();
      notifyListeners();
    }
  }

  Future<void> refreshNotifications() async {
    final res = await ApiService.instance.notifications();
    if (res.success && res.data is List) {
      _notifications = (res.data as List)
          .whereType<Map<String, dynamic>>()
          .map(mapNotification)
          .toList();
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Borrowing actions (all via the backend)
  // ---------------------------------------------------------------------

  /// Returns null on success, or an error message.
  Future<String?> submitBorrowRequest({
    required Equipment eq,
    required int quantity,
    required DateTime borrowingDate,
    required DateTime returnDate,
    required String purpose,
    String notes = '',
  }) async {
    final res = await ApiService.instance.submitBorrowRequest(
      equipmentId: int.tryParse(eq.id) ?? 0,
      quantity: quantity,
      borrowingDate: _dateOnly(borrowingDate),
      expectedReturnDate: _dateOnly(returnDate),
      purpose: purpose,
      notes: notes,
    );

    if (!res.success) return res.message ?? 'Could not submit request.';
    await refreshBorrowings();
    await refreshEquipment();
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> cancelRequest(String transactionId) async {
    final id = int.tryParse(transactionId);
    if (id == null) return 'Invalid request id.';

    final res = await ApiService.instance.cancelBorrowing(id);
    if (!res.success) return res.message ?? 'Could not cancel request.';
    await refreshBorrowings();
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> submitReturnRequest(String transactionId) async {
    final id = int.tryParse(transactionId);
    if (id == null) return 'Invalid request id.';

    final res = await ApiService.instance.submitReturn(borrowingId: id);
    if (!res.success) return res.message ?? 'Could not submit return.';
    await refreshBorrowings();
    await refreshEquipment();
    return null;
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------
  // Notification actions
  // ---------------------------------------------------------------------
  Future<void> markAsRead(String id) async {
    final numeric = int.tryParse(id);
    if (numeric != null) {
      await ApiService.instance.markNotificationRead(numeric);
    }
    for (final n in _notifications) {
      if (n.id == id) n.isRead = true;
    }
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await ApiService.instance.markAllNotificationsRead();
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _stopPolling();
    RealtimeService.instance.disconnect();
    super.dispose();
  }
}
