class User {
  final String username;
  final String password;
  final String teamId;
  final String role;

  User({
    required this.username,
    required this.password,
    required this.teamId,
    required this.role,
  });
}

class LoginController {
  final List<User> _users = [
    User(
      username: "admin",
      password: "123",
      teamId: "MEKTRA_KLP_01",
      role: "Ketua",
    ),
    User(
      username: "uci",
      password: "456",
      teamId: "MEKTRA_KLP_01",
      role: "Anggota",
    ),
    User(
      username: "maul",
      password: "456",
      teamId: "MEKTRA_KLP_01",
      role: "Anggota",
    ),
    User(
      username: "maul2",
      password: "456",
      teamId: "MEKTRA_KLP_02",
      role: "Anggota",
    ),
  ];

  User? _findUser(String username) {
    try {
      return _users.firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }

  bool validateLogin(String username, String password) {
    final user = _findUser(username);
    if (user != null) {
      return user.password == password;
    }
    return false;
  }

  String getTeamIdForUser(String username) {
    final user = _findUser(username);
    return user?.teamId ?? "MEKTRA_KLP_DEFAULT";
  }

  String getRoleForUser(String username) {
    final user = _findUser(username);
    return user?.role ?? "Anggota";
  }
}
