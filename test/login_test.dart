// test/module2_authentication_test.dart
// ========================================
// MODULE 2: AUTHENTICATION TEST SUITE
// Test Cases untuk LoginController
// Total: 9 Test Cases (3 Test Functions × 3 Flows)
// ========================================

import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app/features/auth/login_controller.dart';

void main() {
  var actual, expected;

  group('Module 2 - LoginController (Authentication)', () {
    late LoginController controller;

    setUp(() {
      // (1) SETUP: Initialize LoginController
      controller = LoginController();
    });

    // ========================================
    // FUNCTION 1: validateLogin()
    // Test 3 different flows for credential validation
    // ========================================

    group('Function 1: validateLogin()', () {
      test(
        'Flow 1 - Valid Credentials: should return true for correct username and password',
        () {
          // (1) SETUP (Arrange)
          const username = "admin";
          const password = "123";

          // (2) EXERCISE (Act)
          actual = controller.validateLogin(username, password);
          expected = true;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason: 'Expected $expected but got $actual for valid credentials',
          );
        },
      );

      test(
        'Flow 2 - Invalid Password: should return false for wrong password',
        () {
          // (1) SETUP (Arrange)
          const username = "admin";
          const wrongPassword = "wrong123";

          // (2) EXERCISE (Act)
          actual = controller.validateLogin(username, wrongPassword);
          expected = false;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason: 'Expected $expected but got $actual for invalid password',
          );
        },
      );

      test(
        'Flow 3 - Non-existent User: should return false for user not found',
        () {
          // (1) SETUP (Arrange)
          const nonExistentUser = "unknown_user";
          const password = "123";

          // (2) EXERCISE (Act)
          actual = controller.validateLogin(nonExistentUser, password);
          expected = false;

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason: 'Expected $expected but got $actual for non-existent user',
          );
        },
      );
    });

    // ========================================
    // FUNCTION 2: getTeamIdForUser()
    // Test 3 different flows for team ID retrieval
    // ========================================

    group('Function 2: getTeamIdForUser()', () {
      test(
        'Flow 1 - Valid User: should return correct teamId for existing user',
        () {
          // (1) SETUP (Arrange)
          const username = "admin";
          expected = "MEKTRA_KLP_01";

          // (2) EXERCISE (Act)
          actual = controller.getTeamIdForUser(username);

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason:
                'Expected teamId $expected but got $actual for user $username',
          );
        },
      );

      test(
        'Flow 2 - Invalid User: should return default teamId for non-existent user',
        () {
          // (1) SETUP (Arrange)
          const nonExistentUser = "invalid_user";
          expected = "MEKTRA_KLP_DEFAULT";

          // (2) EXERCISE (Act)
          actual = controller.getTeamIdForUser(nonExistentUser);

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason:
                'Expected default teamId $expected but got $actual for non-existent user',
          );
        },
      );

      test(
        'Flow 3 - Different Users from Different Teams: should return correct teamId for each user',
        () {
          // (1) SETUP (Arrange) - Test multiple users from different teams
          const userTeam1 = "uci"; // MEKTRA_KLP_01
          const userTeam2 = "maul2"; // MEKTRA_KLP_02

          // (2) EXERCISE (Act) & (3) VERIFY (Assert)
          actual = controller.getTeamIdForUser(userTeam1);
          expected = "MEKTRA_KLP_01";
          expect(
            actual,
            expected,
            reason: 'Expected $expected but got $actual for user $userTeam1',
          );

          actual = controller.getTeamIdForUser(userTeam2);
          expected = "MEKTRA_KLP_02";
          expect(
            actual,
            expected,
            reason: 'Expected $expected but got $actual for user $userTeam2',
          );
        },
      );
    });

    // ========================================
    // FUNCTION 3: getRoleForUser()
    // Test 3 different flows for role retrieval
    // ========================================

    group('Function 3: getRoleForUser()', () {
      test(
        'Flow 1 - Admin User: should return correct role for admin user',
        () {
          // (1) SETUP (Arrange)
          const adminUser = "admin";
          expected = "Ketua";

          // (2) EXERCISE (Act)
          actual = controller.getRoleForUser(adminUser);

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason: 'Expected role $expected but got $actual for admin user',
          );
        },
      );

      test(
        'Flow 2 - Invalid User: should return default role for non-existent user',
        () {
          // (1) SETUP (Arrange)
          const nonExistentUser = "unknown_user";
          expected = "Anggota"; // Default role

          // (2) EXERCISE (Act)
          actual = controller.getRoleForUser(nonExistentUser);

          // (3) VERIFY (Assert)
          expect(
            actual,
            expected,
            reason:
                'Expected default role $expected but got $actual for non-existent user',
          );
        },
      );

      test(
        'Flow 3 - Different User Roles: should return correct role for each user type',
        () {
          // (1) SETUP (Arrange) - Test different user types
          const adminUser = "admin"; // Ketua
          const memberUser = "uci"; // Anggota

          // (2) EXERCISE (Act) & (3) VERIFY (Assert)
          actual = controller.getRoleForUser(adminUser);
          expected = "Ketua";
          expect(
            actual,
            expected,
            reason: 'Expected $expected but got $actual for admin user',
          );

          actual = controller.getRoleForUser(memberUser);
          expected = "Anggota";
          expect(
            actual,
            expected,
            reason: 'Expected $expected but got $actual for member user',
          );
        },
      );
    });
  });
}
