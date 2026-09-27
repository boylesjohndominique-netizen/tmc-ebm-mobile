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

class AppUser {
  final String id;
  String fullName;
  String idNumber;
  String email;
  String username;
  String contactNumber;
  UserType userType;
  String password;

  /// Local paths of the uploaded ID verification photos (front / back).
  String? idFrontPath;
  String? idBackPath;

  /// Current review state of the submitted ID photos.
  IdVerificationStatus idVerificationStatus;

  /// Reviewer note shown to the user when verification is rejected
  /// (set from the admin website, displayed here).
  String? verificationNote;

  AppUser({
    required this.id,
    required this.fullName,
    required this.idNumber,
    required this.email,
    required this.username,
    required this.contactNumber,
    required this.userType,
    required this.password,
    this.idFrontPath,
    this.idBackPath,
    this.idVerificationStatus = IdVerificationStatus.notSubmitted,
    this.verificationNote,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
