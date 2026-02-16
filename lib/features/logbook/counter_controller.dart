class CounterController {
  int _counter = 0;
  int _step = 1;

  final List<String> _history = [];

  int get value => _counter;
  List<String> get history => _history;

  void setStep(int step) {
    _step = step;
  }

  void _addHistory(String action) {
    final time = _getCurrentTime();
    _history.insert(0, "$action $_counter ($time)");

    if (_history.length > 5) {
      _history.removeLast();
    }
  }

  void increment() {
    _counter += _step;
    _addHistory("Nilai bertambah +$_step, total menjadi :");
  }

  void decrement() {
    if (_counter > 0) {
      _counter -= _step;
      _addHistory("Nilai berkurang -$_step, total menjadi :");
    }
  }

  void reset() {
    _counter = 0;
    _addHistory("Nilai direset, total kembali ke ");
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";
  }
}
