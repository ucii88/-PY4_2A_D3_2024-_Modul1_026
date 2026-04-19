import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  late final ValueNotifier<bool> isConnected = ValueNotifier(false);

  StreamSubscription? _connectivitySubscription;
  bool _isInitialized = false;
  final Connectivity _connectivity = Connectivity();

  ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await checkConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );
      isConnected.value = hasConnection;

      print('[ConnectivityService] Status berubah: $results');
      if (isConnected.value) {
        print(' Internet TERSEDIA (WiFi/Cellular)');
      } else {
        print(' Internet TIDAK TERSEDIA');
      }
    });

    _isInitialized = true;
  }

  Future<void> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );
      isConnected.value = hasConnection;
    } catch (e) {
      print(' Error checking connectivity: $e');
      isConnected.value = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _isInitialized = false;
  }

  bool get hasConnection => isConnected.value;
}
