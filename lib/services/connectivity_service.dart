import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  // Singleton
  ConnectivityService._();
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Callback when connectivity changes
  Function(bool isOnline)? onConnectivityChanged;

  // Get current status
  bool get isOnline => _isOnline;

  // Initialize and start listening
  Future<void> init() async {
    // Check initial status
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(results);

    print('📶 Initial connectivity: ${_isOnline ? "Online ✅" : "Offline 📴"}');

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(results);

      if (wasOnline != _isOnline) {
        print(
          '📶 Connectivity changed: ${_isOnline ? "Online ✅" : "Offline 📴"}',
        );
        onConnectivityChanged?.call(_isOnline);
      }
    });
  }

  // Check if any result indicates connectivity
  bool _isConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // If any result is not 'none', we're online
    return results.any((result) => result != ConnectivityResult.none);
  }

  // Check connectivity once
  Future<bool> checkNow() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(results);
    print('📶 Check now: ${_isOnline ? "Online ✅" : "Offline 📴"}');
    return _isOnline;
  }

  // Dispose
  void dispose() {
    _subscription?.cancel();
  }
}
