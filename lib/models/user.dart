enum UserType { student, faculty, staff }

/// Lifecycle of the ID verification photos submitted at registration.
enum IdVerificationStatus { notSubmitted, pending, approved, rejected }

extension UserTypeLabel on UserType {
  String get label {
    switch (this) {
      case UserType.student:
        return 'Student';
      case UserType.faculty:
        return 'Faculty';
      case UserType.staff:
        return 'Staff';
    }
  }
}

/// The signed-in user, mirrored from the backend `users` table.
/// Passwords never live on the client — auth uses bearer tokens.
class AppUser {
  final String id;
  final String fullName;
  final String idNumber;
  final String email;
  final String username;
  final String contactNumber;
  final UserType userType;

  /// Email verification (6-digit code) — gates login.
  final bool emailVerified;

  /// Admin verification lifecycle: Pending | Active | Banned.
  final String accountStatus;

  AppUser({
    required this.id,
    required this.fullName,
    required this.idNumber,
    required this.email,
    required this.username,
    required this.contactNumber,
    required this.userType,
    this.emailVerified = false,
    this.accountStatus = 'Active',
  });

  bool get isPending => accountStatus == 'Pending';
  bool get isActive => accountStatus == 'Active';
  bool get isBanned => accountStatus == 'Banned';

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
