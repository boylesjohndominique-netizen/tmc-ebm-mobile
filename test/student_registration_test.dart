import 'package:flutter_test/flutter_test.dart';
import 'package:tmcebms/data/mock_users.dart';
import 'package:tmcebms/models/user.dart';
import 'package:tmcebms/state/app_state.dart';

void main() {
  test('student registration stores ID photos and starts as pending review', () {
    final appState = AppState();
    final error = appState.register(
      fullName: 'Test Student',
      idNumber: '2024-55555',
      email: 'new.student@tmc.edu',
      username: 'test.student',
      contactNumber: '09211234567',
      userType: UserType.student,
      password: 'password123',
      idFrontPath: '/tmp/id_front.jpg',
      idBackPath: '/tmp/id_back.jpg',
    );

    expect(error, isNull);
    final created = mockUsers.lastWhere((u) => u.username == 'test.student');
    expect(created.userType, UserType.student);
    expect(created.idFrontPath, '/tmp/id_front.jpg');
    expect(created.idBackPath, '/tmp/id_back.jpg');
    expect(created.idVerificationStatus, IdVerificationStatus.pending);
  });

  test('registration without ID photos still creates the account', () {
    final appState = AppState();
    final error = appState.register(
      fullName: 'No Photo Student',
      idNumber: '2024-66666',
      email: 'no.photo@tmc.edu',
      username: 'no.photo',
      contactNumber: '09221234567',
      userType: UserType.student,
      password: 'password123',
    );

    expect(error, isNull);
    final created = mockUsers.lastWhere((u) => u.username == 'no.photo');
    expect(created.idVerificationStatus, IdVerificationStatus.pending);
    expect(created.idFrontPath, isNull);
  });
}
