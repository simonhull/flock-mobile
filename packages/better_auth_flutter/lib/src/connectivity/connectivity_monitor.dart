import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

/// Monitors network connectivity and provides streams for online/offline events.
final class ConnectivityMonitor {
  ConnectivityMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _isOnlineController = BehaviorSubject<bool>.seeded(false);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Whether the device currently has network connectivity.
  bool get isOnline => _isOnlineController.value;

  /// Stream that emits whenever connectivity status changes.
  Stream<bool> get onConnectivityChanged => _isOnlineController.stream.skip(1);

  /// Stream that emits when device transitions from offline to online.
  Stream<void> get onOnline => onConnectivityChanged
      .distinct()
      .where((isOnline) => isOnline)
      .map((_) {});

  /// Initialize the monitor and start listening for connectivity changes.
  Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _isOnlineController.add(_isConnected(result));

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isOnlineController.add(_isConnected(result));
    });
  }

  /// Dispose resources.
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _isOnlineController.close();
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (r) => r != ConnectivityResult.none,
    );
  }
}
