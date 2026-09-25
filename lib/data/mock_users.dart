import '../models/user.dart';

/// Predefined demo accounts. Password for all demo accounts: password123
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
  AppUser(
    id: 'u-002',
    fullName: 'Maria Santos',
    idNumber: 'F-00045',
    email: 'faculty@tmc.edu',
    username: 'maria.santos',
    contactNumber: '09181234567',
    userType: UserType.faculty,
    password: 'password123',
  ),
  AppUser(
    id: 'u-003',
    fullName: 'Pedro Ramirez',
    idNumber: 'S-00078',
    email: 'staff@tmc.edu',
    username: 'pedro.ramirez',
    contactNumber: '09191234567',
    userType: UserType.staff,
    password: 'password123',
  ),
];
