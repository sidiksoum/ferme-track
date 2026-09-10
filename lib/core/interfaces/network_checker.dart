import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Abstract interface for network connectivity checking
abstract class NetworkChecker {
  /// Check if device has internet connection
  Future<bool> get hasConnection;

  /// Stream of connectivity status changes (true = online, false = offline)
  Stream<bool> get connectivityStream;
}

/// Stub implementation for testing/development
class NetworkCheckerStub implements NetworkChecker {
  @override
  Future<bool> get hasConnection async => true;

  @override
  Stream<bool> get connectivityStream => Stream.value(true);
}

/// Robust implementation using internet_connection_checker_plus
class NetworkCheckerImpl implements NetworkChecker {
  final InternetConnection _checker;

  NetworkCheckerImpl([InternetConnection? checker])
      : _checker = checker ?? InternetConnection();

  @override
  Future<bool> get hasConnection async {
    try {
      return await _checker.hasInternetAccess;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get connectivityStream {
    try {
      return _checker.onStatusChange.map((status) {
        return status == InternetStatus.connected;
      }).asBroadcastStream();
    } catch (_) {
      return Stream.value(false);
    }
  }
}
