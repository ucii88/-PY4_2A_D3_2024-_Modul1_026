import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app/features/auth/login_controller.dart';

void main() {
  late LoginController controller;

  setUp(() {
    controller = LoginController();
  });

  group('Authentication - LoginController', () {
    test('TC01 - Login berhasil dengan data valid', () {
      // (1) Arrange
      String username = "admin";
      String password = "123";

      // (2) Act
      bool actual = controller.validateLogin(username, password);

      // (3) Assert
      expect(actual, true);
    });

    test('TC02 - Login gagal dengan password salah', () {
      // (1) Arrange
      String username = "admin";
      String password = "999";

      // (2) Act
      bool actual = controller.validateLogin(username, password);

      // (3) Assert
      expect(actual, false);
    });

    test('TC03 - Login gagal dengan username tidak terdaftar', () {
      // (1) Arrange
      String username = "tidak_ada";
      String password = "123";

      // (2) Act
      bool actual = controller.validateLogin(username, password);

      // (3) Assert
      expect(actual, false);
    });
  });
}
