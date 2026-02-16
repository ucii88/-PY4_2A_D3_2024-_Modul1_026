class LoginController {
  final String _validUsername = "admin";
  final String _validPassword = "password123";

  bool login(String username, String password) {
    if (username == _validUsername && password == _validPassword) {
      return true;
    }
    return false;
  }
}
