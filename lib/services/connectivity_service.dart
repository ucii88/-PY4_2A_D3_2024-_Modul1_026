import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service yang memantau status koneksi jaringan secara real-time
/// menggunakan active listener untuk WiFi/Cellular changes
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  // ValueNotifier: true jika ada koneksi (WiFi atau Cellular)
  late final ValueNotifier<bool> isConnected = ValueNotifier(false);

  StreamSubscription? _connectivitySubscription;
  bool _isInitialized = false;
  final Connectivity _connectivity = Connectivity();

  ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  /// Inisialisasi: check status awal + setup listener aktif
  Future<void> initialize() async {
    if (_isInitialized) return;

    // ========== STEP 1: Check koneksi awal ==========
    await checkConnectivity();

    // ========== STEP 2: Setup Active Listener ==========
    // onConnectivityChanged mengembalikan List<ConnectivityResult>
    // Listener ini dipanggil SETIAP kali ada perubahan WiFi/Cellular
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      // Cek apakah ada WiFi atau Cellular (exclude none)
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );
      isConnected.value = hasConnection;

      print('[ConnectivityService] Status berubah: $results');
      if (isConnected.value) {
        print('🟢 Internet TERSEDIA (WiFi/Cellular)');
      } else {
        print('🔴 Internet TIDAK TERSEDIA');
      }
    });

    _isInitialized = true;
  }

  /// Manual check koneksi (sekali saja)
  Future<void> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // results adalah List<ConnectivityResult>
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );
      isConnected.value = hasConnection;
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      isConnected.value = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _isInitialized = false;
  }

  bool get hasConnection => isConnected.value;
}
