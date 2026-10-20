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
  // Ban lifecycle
  // ---------------------------------------------------------------------
  bool _accountBanned = false;
  String? _banReason;
  String? _bannedLogin; // username/email captured at ban time (token is dead)

  /// True when the signed-in account (or the account just used to log in)
  /// has been banned. Drives the global ban/appeal dialog.
  bool get accountBanned => _accountBanned;

  /// Reason supplied by the administrator when the account was banned.
  String? get banReason => _banReason;

  // ---------------------------------------------------------------------
  // Data (all fetched from the backend)
  // ---------------------------------------------------------------------
  List<Equipment> _equipment = const [];
  Map<String, Equipment> _equipmentById = const {};
  List<String> _categories = const [];
  List<BorrowingTransaction> _transactions = const [];
  List<BorrowingTransaction> _pendingAndApproved = const [];
  List<BorrowingTransaction> _currentlyBorrowed = const [];
  List<BorrowingTransaction> _borrowingHistory = const [];
  List<BorrowingTransaction> _returnHistory = const [];
  int _overdueCount = 0;
  List<AppNotification> _notifications = const [];
  int _unreadCount = 0;
  List<PlatformPolicy> _platformPolicies = const [];
  double _overdueFeePerDay = 0;

  bool _loadingEquipment = false;
  bool _loadingPolicies = false;

  bool get isLoadingEquipment => _loadingEquipment;
  bool get isLoadingPolicies => _loadingPolicies;
  List<PlatformPolicy> get platformPolicies => _platformPolicies;
  double get overdueFeePerDay => _overdueFeePerDay;
  List<Equipment> get equipment => _equipment;

  Equipment? equipmentById(String id) => _equipmentById[id];

  List<String> get categories => _categories;

  List<BorrowingTransaction> get transactions => _transactions;

  List<BorrowingTransaction> get pendingAndApproved => _pendingAndApproved;

  List<BorrowingTransaction> get currentlyBorrowed => _currentlyBorrowed;

  List<BorrowingTransaction> get borrowingHistory => _borrowingHistory;

  List<BorrowingTransaction> get returnHistory => _returnHistory;

  int get overdueCount => _overdueCount;

  // ---------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------
  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _unreadCount;

  void _setEquipment(List<Equipment> items) {
    _equipment = List<Equipment>.unmodifiable(items);
    _equipmentById = {for (final e in _equipment) e.id: e};
    final cats = _equipment.map((e) => e.category).toSet().toList()..sort();
    _categories = List<String>.unmodifiable(cats);
  }

  void _setTransactions(List<BorrowingTransaction> items) {
    _transactions = List<BorrowingTransaction>.unmodifiable(items);
    _pendingAndApproved = List<BorrowingTransaction>.unmodifiable(
      _transactions.where((t) =>
          t.status == RequestStatus.pending ||
          t.status == RequestStatus.approved),
    );
    _currentlyBorrowed = List<BorrowingTransaction>.unmodifiable(
      _transactions.where((t) => t.isCurrentlyBorrowed),
    );
    _borrowingHistory = List<BorrowingTransaction>.unmodifiable(
      _transactions.where((t) =>
          t.status == RequestStatus.completed ||
          t.status == RequestStatus.rejected ||
          t.status == RequestStatus.cancelled),
    );
    _returnHistory = List<BorrowingTransaction>.unmodifiable(
      _transactions.where((t) =>
          t.returnStatus == ReturnStatus.completed ||
          t.returnStatus == ReturnStatus.returnConfirmed),
    );
    _overdueCount = _transactions.where((t) => t.isOverdue).length;
  }

  void _setNotifications(List<AppNotification> items) {
    _notifications = List<AppNotification>.unmodifiable(items);
    _recomputeUnreadCount();
  }

  void _recomputeUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // ---------------------------------------------------------------------
  // Theme + onboarding flag
  // ---------------------------------------------------------------------
  bool _isDarkMode = false;
  bool _onboardingSeen = false;
  bool get isDarkMode => _isDarkMode;
  bool get onboardingSeen => _onboardingSeen;

  // ---------------------------------------------------------------------
  // ID verification (submitted from the profile screen)
  // ---------------------------------------------------------------------
  static const _idVerificationPrefix = 'tmc_id_verification_';
  final Map<String, IdVerificationStatus> _idVerification = {};

  /// ID-verification lifecycle for the signed-in user.
  ///
  /// The source of truth is the backend's `is_id_verified` flag (the
  /// `verified_at` column), which is independent of the ban lifecycle:
  ///   - verified → approved (even while banned)
  ///   - not verified + local submitted record → pending review
  ///   - otherwise → notSubmitted
  IdVerificationStatus get idVerificationStatus {
    if (currentUser?.isIdVerified == true) return IdVerificationStatus.approved;
    // Server-side submission marker wins over the local cache (survives
    // reinstalls and reflects submissions made from other devices).
    if (currentUser?.hasSubmittedId == true) {
      return IdVerificationStatus.pending;
    }
    return _idVerification[currentUser?.id] ??
        IdVerificationStatus.notSubmitted;
  }

  /// Uploads the submitted ID photos to the backend (private storage) and
  /// flags the account as pending admin review.
  ///
  /// Returns null on success or an error message. The pending state is also
  /// cached locally so the UI reflects it immediately even if the fetch of
  /// fresh account data fails.
  Future<String?> submitIdVerification({
    required String idFrontPath,
    required String idBackPath,
  }) async {
    final id = currentUser?.id;
    if (id == null) return 'Not signed in.';

    final res = await ApiService.instance.submitIdVerification(
      idFrontPath: idFrontPath,
      idBackPath: idBackPath,
    );

    if (!res.success) {
      return res.message ?? 'Could not submit ID photos.';
    }

    _idVerification[id] = IdVerificationStatus.pending;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _idVerificationPrefix + id, IdVerificationStatus.pending.name);
    notifyListeners();
    return null;
  }

  /// Restores the stored verification status for the current user.
  Future<void> _loadIdVerification() async {
    final id = currentUser?.id;
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_idVerificationPrefix + id);
    if (stored == null) return;
    _idVerification[id] = IdVerificationStatus.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => IdVerificationStatus.notSubmitted,
    );
  }

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
      await _loadIdVerification();
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
        'id_number': currentUser?.idNumber ?? '',
        'profile_photo_path': currentUser?.avatarUrl,
        'username': currentUser?.username ?? '',
        'email': currentUser?.email ?? '',
        'contact_number': currentUser?.contactNumber ?? '',
        'email_verified_at': currentUser!.emailVerified ? 'verified' : null,
        'account_status': currentUser?.accountStatus,
        'is_id_verified': currentUser?.isIdVerified ?? false,
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

    if (!res.success) {
      // Banned accounts cannot log in — surface the global ban dialog so the
      // student can read the reason and appeal instead of only seeing an error.
      if (res.statusCode == 403 && res.data?['banned'] == true) {
        _handleAccountBanned(
          reason: res.data?['ban_reason'] as String?,
          login: identifier,
        );
      }
      return res.message ?? 'Login failed.';
    }

    final user = res.data?['user'];
    if (user is Map<String, dynamic>) {
      currentUser = mapUser(user);
      await _loadIdVerification();
      await _persistUser();
      _startRealtime();
      notifyListeners();
      unawaited(refreshAll());
      return null;
    }
    return 'Login succeeded but the server returned an unexpected payload.';
  }

  /// Returns null on success, or an error message.
  Future<String?> register({
    required String firstName,
    String? middleName,
    required String lastName,
    required String idNumber,
    required String email,
    String? username,
    required String contactNumber,
    required UserType userType,
    required String password,
    bool emailVerified = false,
  }) async {
    final trimmedFirst = firstName.trim();
    final trimmedMiddle = middleName?.trim();
    final trimmedLast = lastName.trim();
    final resolvedUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim()
        : trimmedFirst;

    final res = await ApiService.instance.register(
      firstName: trimmedFirst,
      middleName: (trimmedMiddle != null && trimmedMiddle.isNotEmpty)
          ? trimmedMiddle
          : null,
      lastName: trimmedLast,
      idNumber: idNumber,
      username: resolvedUsername,
      email: email,
      contactNumber: contactNumber,
      password: password,
      passwordConfirmation: password,
      emailVerified: emailVerified,
    );

    if (!res.success) return res.message ?? 'Registration failed.';

    if (res.data != null &&
        res.data!['token'] is String &&
        res.data!['user'] is Map<String, dynamic>) {
      await loginWithTokenPayload(res.data);
    }

    return null;
  }

  /// Handles any backend response that already contains a token + user object
  /// (e.g. the email-verification endpoint after the student enters the OTP).
  /// Persists the session and loads data exactly like a normal login.
  /// Returns null on success, or an error message.
  Future<String?> loginWithTokenPayload(dynamic payload) async {
    if (payload is! Map<String, dynamic>) {
      return 'Unexpected response from server.';
    }
    final token = payload['token'] as String?;
    final userMap = payload['user'];
    if (token == null || userMap is! Map<String, dynamic>) {
      return 'Missing token or user data.';
    }
    await ApiService.instance.setAuthToken(token);
    currentUser = mapUser(userMap);
    await _loadIdVerification();
    await _persistUser();
    _startRealtime();
    notifyListeners();
    unawaited(refreshAll());
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> updateProfile({
    required String firstName,
    required String lastName,
    String? idNumber,
    String? contactNumber,
    String? avatarPath,
    bool removeAvatar = false,
  }) async {
    final res = await ApiService.instance.updateProfile(
      firstName: firstName,
      lastName: lastName,
      idNumber: idNumber,
      contactNumber: contactNumber,
      avatarPath: avatarPath,
      removeAvatar: removeAvatar,
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

  /// Uploads a new profile picture directly from the Profile header.
  Future<String?> updateProfilePhoto(String imagePath) async {
    final res = await ApiService.instance.updateAvatar(imagePath);
    if (!res.success) return res.message ?? 'Could not update profile picture.';

    final fresh = res.data?['user'];
    if (fresh is Map<String, dynamic>) {
      currentUser = mapUser(fresh);
      await _persistUser();
    }
    notifyListeners();
    return null;
  }

  /// Returns null on success, or an error message.
  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    final res = await ApiService.instance.changePassword(
      currentPassword: currentPassword,
      password: newPassword,
      passwordConfirmation: newPassword,
    );
    return res.success ? null : (res.message ?? 'Could not change password.');
  }

  /// Marks the account as banned and shows the global ban/appeal dialog.
  /// Triggered by the realtime `user.banned` event or a banned login attempt.
  void _handleAccountBanned({String? reason, String? login}) {
    _accountBanned = true;
    if (reason != null && reason.isNotEmpty) _banReason = reason;
    _bannedLogin = login ??
        _bannedLogin ??
        currentUser?.username ??
        (currentUser?.email.isNotEmpty == true ? currentUser?.email : null);
    _stopPolling(); // no point polling with a revoked token
    notifyListeners();
  }

  /// Sends an appeal message to the administrator. Returns null on success or
  /// an error message. Works without a session (the account is looked up by
  /// username/email on the server).
  Future<String?> submitBanAppeal(String message) async {
    final login = _bannedLogin ??
        currentUser?.username ??
        (currentUser?.email.isNotEmpty == true ? currentUser?.email : null);
    if (login == null || login.isEmpty) {
      return 'Could not identify your account to send the appeal.';
    }
    final res = await ApiService.instance.submitAppeal(
      login: login,
      message: message,
    );
    return res.success ? null : (res.message ?? 'Could not send your appeal.');
  }

  Future<void> logout() async {
    await ApiService.instance.logout();
    RealtimeService.instance.disconnect();
    currentUser = null;
    _setEquipment(const []);
    _setTransactions(const []);
    _setNotifications(const []);
    _accountBanned = false;
    _banReason = null;
    _bannedLogin = null;
    _stopPolling();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tmc_user');
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Realtime + polling
  // ---------------------------------------------------------------------
  StreamSubscription? _notifSub;
  StreamSubscription? _banSub;
  Timer? _pollTimer;

  void _startRealtime() {
    final id = int.tryParse(currentUser?.id ?? '');
    if (id == null) return;

    RealtimeService.instance.connect(userId: id);
    _notifSub?.cancel();
    // A notification usually means an admin acted on the student's requests
    // (approval, rejection, return confirmation) — refetch both feeds.
    _notifSub = RealtimeService.instance.notificationStream.listen((_) {
      _refreshLiveFeeds();
    });

    // The account was banned mid-session: show the ban/appeal dialog.
    _banSub?.cancel();
    _banSub = RealtimeService.instance.banStream.listen((data) {
      _handleAccountBanned(reason: data['reason'] as String?);
    });

    // Polling fallback keeps account verification and borrowings fresh even if
    // the WebSocket is unreachable (e.g. behind a firewall on campus Wi-Fi).
    _startPolling();
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (isLoggedIn) {
        _refreshLiveFeeds();
      }
    });
  }

  Future<void> _refreshLiveFeeds() async {
    await Future.wait([
      refreshProfile(notify: false),
      refreshBorrowings(notify: false),
      refreshNotifications(notify: false),
    ]);
    notifyListeners();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ---------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------
  Future<void> refreshAll() async {
    _loadingEquipment = true;
    _loadingPolicies = true;
    notifyListeners();

    await Future.wait([
      refreshProfile(notify: false),
      refreshEquipment(notify: false),
      refreshBorrowings(notify: false),
      refreshNotifications(notify: false),
      refreshSettings(notify: false),
    ]);

    _loadingEquipment = false;
    _loadingPolicies = false;
    notifyListeners();
  }

  Future<void> refreshSettings({bool notify = true}) async {
    if (notify) {
      _loadingPolicies = true;
      notifyListeners();
    }

    final res = await ApiService.instance.fetchMobileSettings();
    if (res.success && res.data != null) {
      final rawFee = res.data!['overdue_fee_per_day'];
      if (rawFee is num) {
        _overdueFeePerDay = rawFee.toDouble();
      } else if (rawFee != null) {
        _overdueFeePerDay = double.tryParse(rawFee.toString()) ?? 0;
      }

      final rawPolicies = res.data!['platform_policies'];
      if (rawPolicies is List) {
        _platformPolicies = List<PlatformPolicy>.unmodifiable(
          rawPolicies
              .whereType<Map>()
              .map((m) => PlatformPolicy.fromJson(Map<String, dynamic>.from(m)))
              .where((p) => p.title.isNotEmpty || p.content.isNotEmpty),
        );
      }
    }

    if (notify) {
      _loadingPolicies = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile({bool notify = true}) async {
    final res = await ApiService.instance.profile();
    if (res.success && res.data != null) {
      currentUser = mapUser(res.data!);
      await _persistUser();
      if (notify) notifyListeners();
    }
  }

  Future<void> refreshEquipment({bool notify = true}) async {
    if (notify) {
      _loadingEquipment = true;
      notifyListeners();
    }

    final res = await ApiService.instance.equipmentList();
    if (res.success && res.data is List) {
      _setEquipment(
        (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(mapEquipment)
            .toList(),
      );
    }
    if (notify) {
      _loadingEquipment = false;
      notifyListeners();
    }
  }

  Future<void> refreshBorrowings({bool notify = true}) async {
    final res = await ApiService.instance.myBorrowings();
    if (res.success && res.data is List) {
      _setTransactions(
        (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(mapBorrowing)
            .toList(),
      );
      if (notify) notifyListeners();
    }
  }

  Future<void> refreshNotifications({bool notify = true}) async {
    final res = await ApiService.instance.notifications();
    if (res.success && res.data is List) {
      _setNotifications(
        (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(mapNotification)
            .toList(),
      );
      if (notify) notifyListeners();
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
    await Future.wait([
      refreshBorrowings(notify: false),
      refreshEquipment(notify: false),
    ]);
    notifyListeners();
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
  Future<String?> submitReturnRequest(
    String transactionId, {
    String? remarks,
  }) async {
    final id = int.tryParse(transactionId);
    if (id == null) return 'Invalid request id.';

    final res = await ApiService.instance.submitReturn(
      borrowingId: id,
      remarks: remarks,
    );
    if (!res.success) return res.message ?? 'Could not submit return.';
    await Future.wait([
      refreshBorrowings(notify: false),
      refreshEquipment(notify: false),
    ]);
    notifyListeners();
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
    _recomputeUnreadCount();
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await ApiService.instance.markAllNotificationsRead();
    for (final n in _notifications) {
      n.isRead = true;
    }
    _recomputeUnreadCount();
    notifyListeners();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _banSub?.cancel();
    _stopPolling();
    RealtimeService.instance.disconnect();
    super.dispose();
  }
}

class PlatformPolicy {
  final String id;
  final String title;
  final String content;

  const PlatformPolicy({
    required this.id,
    required this.title,
    required this.content,
  });

  factory PlatformPolicy.fromJson(Map<String, dynamic> json) {
    return PlatformPolicy(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString().trim(),
      content: (json['content'] ?? '').toString().trim(),
    );
  }
}
