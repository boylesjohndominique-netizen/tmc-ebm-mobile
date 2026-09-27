import '../models/user.dart';

/// Predefined demo accounts. Password for all demo accounts: password123.
///
/// This mobile app serves students only — faculty and staff accounts are
/// provisioned through the admin website.
final List<AppUser> mockUsers = [
  AppUser(
    id: 'u-001',
    fullName: 'Juan Dela Cruz',
    idNumber: '2023-00123',
    email: 'student@tmc.edu',
    username: 'juan.delacruz',
    contactNumber: '09171234567',
    userType: UserType.student,
    password: 'password123',
  ),
];
