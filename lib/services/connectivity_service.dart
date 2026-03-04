import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final ValueNotifier<bool> isConnected = ValueNotifier(true);
  Timer? _checkTimer;
  bool _isInitialized = false;

  ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await checkConnectivity();

    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => checkConnectivity(),
    );

    _isInitialized = true;
  }

  Future<void> checkConnectivity() async {
    try {
      final result = await _testInternetConnection();
      isConnected.value = result;
    } catch (e) {
      isConnected.value = false;
    }
  }

  Future<bool> _testInternetConnection() async {
    try {
      final result = await Future.wait<bool>([_testConnection('8.8.8.8', 53)])
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              return [false];
            },
          );
      return result.any((success) => success);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testConnection(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _checkTimer?.cancel();
    _isInitialized = false;
  }

  bool get hasConnection => isConnected.value;
}
