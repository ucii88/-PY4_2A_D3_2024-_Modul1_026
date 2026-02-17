import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;

  final List<String> _history = [];

  int get value => _counter;
  List<String> get history => _history;

  void setStep(int step) {
    _step = step;
  }

  Future<void> loadData(String username) async {
    final prefs = await SharedPreferences.getInstance();

    _counter = prefs.getInt('counter_$username') ?? 0;

    final historyString = prefs.getString('history_$username');
    if (historyString != null) {
      final decoded = jsonDecode(historyString) as List;
      _history.clear();
      _history.addAll(decoded.cast<String>());
    }
  }

  Future<void> _saveData(String username) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('counter_$username', _counter);
    await prefs.setString('history_$username', jsonEncode(_history));
  }

  void _addHistory(String username, String action) {
    final time = _getCurrentTime();
    _history.insert(0, "User $username $action $_counter ($time)");

    if (_history.length > 5) {
      _history.removeLast();
    }
  }

  Future<void> increment(String username) async {
    _counter += _step;
    _addHistory(username, "menambah +$_step menjadi");
    await _saveData(username);
  }

  Future<void> decrement(String username) async {
    if (_counter > 0) {
      _counter -= _step;
      _addHistory(username, "mengurangi -$_step menjadi");
      await _saveData(username);
    }
  }

  Future<void> reset(String username) async {
    _counter = 0;
    _addHistory(username, "mereset ke");
    await _saveData(username);
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";
  }
}
