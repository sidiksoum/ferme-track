/// Abstract interface for network connectivity checking
abstract class NetworkChecker {
  /// Check if device has internet connection
  Future<bool> get hasConnection;
  
  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream;
}

/// Stub implementation for testing/development
class NetworkCheckerStub implements NetworkChecker {
  @override
  Future<bool> get hasConnection async => true;

  @override
  Stream<bool> get connectivityStream => Stream.value(true);
}

/// Implementation using internet_connection_checker_plus
class NetworkCheckerImpl implements NetworkChecker {
  final dynamic _checker; // InternetConnectionCheckerPlus instance

  NetworkCheckerImpl(this._checker);

  @override
  Future<bool> get hasConnection async {
    try {
      return await _checker.hasConnection;
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<bool> get connectivityStream {
    try {
      return _checker.onStatusChange.map((status) {
        return status == 'connected';
      });
    } catch (e) {
      return Stream.value(false);
    }
  }
}
