class LoginController {
  final Map<String, String> _users = {"admin": "123", "uci": "456"};

  bool validateLogin(String username, String password) {
    if (_users.containsKey(username)) {
      return _users[username] == password;
    }
    return false;
  }
}
