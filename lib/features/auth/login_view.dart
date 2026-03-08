import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logbook_app/features/auth/login_controller.dart';
import 'package:logbook_app/features/logbook/log_view.dart';
import 'package:logbook_app/services/access_control_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isPasswordHidden = true;
  int _loginAttempts = 0;
  bool _isButtonDisabled = false;
  String _selectedRole = AccessControlService.roleAnggota; // Default role

  void _handleLogin() {
    String username = _userController.text.trim();
    String password = _passController.text.trim();

    if (username.isEmpty && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username dan Password wajib diisi")),
      );
      return;
    }

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username tidak boleh kosong")),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password tidak boleh kosong")),
      );
      return;
    }

    bool isSuccess = controller.validateLogin(username, password);

    if (isSuccess) {
      _loginAttempts = 0;
      // Buat userId dari username (bisa diperbaiki dengan UUID nanti)
      final userId = username.toLowerCase();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LogView(
            username: username,
            userId: userId,
            userRole: _selectedRole,
          ),
        ),
      );
    } else {
      _loginAttempts++;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Login gagal. Anda telah mencoba $_loginAttempts dari 3 kali. Silakan periksa kembali data Anda.",
          ),
        ),
      );

      if (_loginAttempts >= 3) {
        setState(() {
          _isButtonDisabled = true;
        });

        Timer(const Duration(seconds: 10), () {
          setState(() {
            _loginAttempts = 0;
            _isButtonDisabled = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Gatekeeper"),
        backgroundColor: const Color.fromARGB(255, 254, 166, 209),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Image.asset("assets/images/login.png", height: 180),
              const SizedBox(height: 16),
              Text(
                "Let’s Begin",
                style: TextStyle(
                  fontSize: 40,
                  fontFamily: "Relationship",
                  color: const Color.fromARGB(255, 253, 145, 197),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Access your account",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 249, 146, 196),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userController,
                cursorColor: const Color.fromARGB(255, 248, 146, 195),
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 248, 146, 195),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF0F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 254, 166, 209),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passController,
                obscureText: _isPasswordHidden,
                cursorColor: const Color.fromARGB(255, 254, 166, 209),
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 254, 166, 209),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFFF0F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 254, 166, 209),
                      width: 2,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color.fromARGB(255, 254, 166, 209),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ========== ROLE SELECTION DROPDOWN ==========
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(
                      value: AccessControlService.roleAnggota,
                      child: Text(
                        'Anggota',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 254, 166, 209),
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: AccessControlService.roleKetua,
                      child: Text(
                        'Ketua',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 254, 166, 209),
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: AccessControlService.roleAsisten,
                      child: Text(
                        'Asisten',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 254, 166, 209),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value ?? AccessControlService.roleAnggota;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 254, 166, 209),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _isButtonDisabled ? null : _handleLogin,
                child: Text(_isButtonDisabled ? "Tunggu 10 detik..." : "Masuk"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
