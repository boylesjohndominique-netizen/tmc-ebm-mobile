enum UserType { student, faculty, staff }

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

  AppUser({
    required this.id,
    required this.fullName,
    required this.idNumber,
    required this.email,
    required this.username,
    required this.contactNumber,
    required this.userType,
    required this.password,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
