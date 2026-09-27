import 'package:flutter/material.dart';
import '../data/mock_equipment.dart';
import '../data/mock_notifications.dart';
import '../data/mock_transactions.dart';
import '../data/mock_users.dart';
import '../models/borrowing_transaction.dart';
import '../models/equipment.dart';
import '../models/notification_item.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _equipment = buildMockEquipment();
    _transactions = buildMockTransactions();
    _notifications = buildMockNotifications();
    currentUser = mockUsers.isNotEmpty ? mockUsers.first : null;
  }

  // ---------- Session ----------
  AppUser? currentUser;
  bool rememberMe = false;

  // ---------- Theme Mode ----------
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
  }

  bool get isLoggedIn => currentUser != null;

  String? login(String identifier, String password) {
    final normalized = identifier.trim().toLowerCase();
    AppUser? match;
    for (final u in mockUsers) {
      if (u.email.toLowerCase() == normalized || u.username.toLowerCase() == normalized) {
        match = u;
        break;
      }
    }
    if (match == null) return 'Invalid username/email or password.';
    if (match.password != password) return 'Invalid username/email or password.';
    currentUser = match;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  /// Returns null on success, or an error message.
  String? register({
    required String fullName,
    required String idNumber,
    required String email,
    required String username,
    required String contactNumber,
    required UserType userType,
    required String password,
    String? idFrontPath,
    String? idBackPath,
  }) {
    final emailTaken = mockUsers.any((u) => u.email.toLowerCase() == email.toLowerCase());
    final usernameTaken = mockUsers.any((u) => u.username.toLowerCase() == username.toLowerCase());
    if (emailTaken) return 'An account with this email already exists.';
    if (usernameTaken) return 'This username is already taken.';

    final newUser = AppUser(
      id: 'u-${100 + mockUsers.length}',
      fullName: fullName,
      idNumber: idNumber,
      email: email,
      username: username,
      contactNumber: contactNumber,
      userType: userType,
      password: password,
      idFrontPath: idFrontPath,
      idBackPath: idBackPath,
      idVerificationStatus: IdVerificationStatus.pending,
    );
    mockUsers.add(newUser);
    notifyListeners();
    return null;
  }

  void updateProfile({
    required String fullName,
    required String email,
    required String contactNumber,
  }) {
    final u = currentUser;
    if (u == null) return;
    u.fullName = fullName;
    u.email = email;
    u.contactNumber = contactNumber;
    notifyListeners();
  }

  String? changePassword(String currentPassword, String newPassword) {
    final u = currentUser;
    if (u == null) return 'Not logged in.';
    if (u.password != currentPassword) return 'Current password is incorrect.';
    u.password = newPassword;
    notifyListeners();
    return null;
  }

  // ---------- Equipment ----------
  late List<Equipment> _equipment;
  List<Equipment> get equipment => List.unmodifiable(_equipment);

  Equipment? equipmentById(String id) {
    try {
      return _equipment.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<String> get categories => _equipment.map((e) => e.category).toSet().toList()..sort();

  // ---------- Transactions ----------
  late List<BorrowingTransaction> _transactions;
  List<BorrowingTransaction> get transactions =>
      List.unmodifiable(_transactions.reversed.toList());

  List<BorrowingTransaction> get pendingAndApproved => _transactions
      .where((t) => t.status == RequestStatus.pending || t.status == RequestStatus.approved)
      .toList()
      .reversed
      .toList();

  List<BorrowingTransaction> get currentlyBorrowed =>
      _transactions.where((t) => t.isCurrentlyBorrowed).toList().reversed.toList();

  List<BorrowingTransaction> get borrowingHistory => _transactions
      .where((t) =>
          t.status == RequestStatus.completed ||
          t.status == RequestStatus.rejected ||
          t.status == RequestStatus.cancelled)
      .toList()
      .reversed
      .toList();

  List<BorrowingTransaction> get returnHistory => _transactions
      .where((t) => t.returnStatus == ReturnStatus.completed)
      .toList()
      .reversed
      .toList();

  int get overdueCount => _transactions.where((t) => t.isOverdue).length;

  BorrowingTransaction submitBorrowRequest({
    required Equipment eq,
    required int quantity,
    required DateTime borrowingDate,
    required DateTime returnDate,
    required String purpose,
    String notes = '',
  }) {
    final txn = BorrowingTransaction(
      transactionId: 'TXN-${DateTime.now().millisecondsSinceEpoch % 100000}',
      equipmentId: eq.id,
      equipmentName: eq.name,
      assetId: eq.assetId,
      category: eq.category,
      quantity: quantity,
      borrowingDate: borrowingDate,
      returnDate: returnDate,
      purpose: purpose,
      notes: notes,
      requestDate: DateTime.now(),
      status: RequestStatus.pending,
    );
    _transactions.add(txn);
    notifyListeners();
    return txn;
  }

  void cancelRequest(String transactionId) {
    final txn = _transactions.firstWhere((t) => t.transactionId == transactionId);
    if (txn.status != RequestStatus.pending) return;
    txn.status = RequestStatus.cancelled;
    notifyListeners();
  }

  void submitReturnRequest(String transactionId) {
    final txn = _transactions.firstWhere((t) => t.transactionId == transactionId);
    txn.returnStatus = ReturnStatus.returnPending;
    notifyListeners();
    addNotification(AppNotification(
      id: 'n-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Return Request Submitted',
      message: 'Your return request for ${txn.equipmentName} is now pending confirmation.',
      type: NotificationType.system,
      date: DateTime.now(),
    ));
  }

  // ---------- Notifications ----------
  late List<AppNotification> _notifications;
  List<AppNotification> get notifications => List.unmodifiable(_notifications.reversed.toList());

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(AppNotification n) {
    _notifications.add(n);
    notifyListeners();
  }

  void markAsRead(String id) {
    final n = _notifications.firstWhere((n) => n.id == id);
    n.isRead = true;
    notifyListeners();
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }
}
