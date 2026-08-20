import 'package:flutter/material.dart';

import '../../../domain/entities/authentication.dart';
import '../../../domain/repositories/authentication_repository.dart';

/// Authentication State Notifier
class AuthNotifier extends ChangeNotifier {
  final AuthenticationRepository _authRepository;

  AuthNotifier(this._authRepository);

  // State
  User? _currentUser;
  SessionInfo? _sessionInfo;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  bool _isBiometricEnabled = false;

  // Getters
  User? get currentUser => _currentUser;
  SessionInfo? get sessionInfo => _sessionInfo;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isBiometricEnabled => _isBiometricEnabled;

  /// Initialize auth state
  Future<void> init() async {
    if (_isLoading) return;
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      // Check if user is logged in
      final loggedInResult = await _authRepository.isLoggedIn();
      _isLoggedIn = loggedInResult.fold((l) => false, (r) => r);

      if (_isLoggedIn) {
        // Get current user
        final userResult = await _authRepository.getCurrentUser();
        _currentUser = userResult.fold((l) => null, (r) => r);

        // Get session info
        final sessionResult = await _authRepository.getSessionInfo();
        _sessionInfo = sessionResult.fold((l) => null, (r) => r);

        // Check biometric
        final bioResult = await _authRepository.isBiometricEnabled();
        _isBiometricEnabled = bioResult.fold((l) => false, (r) => r);
      }

      _error = null;
    } catch (e) {
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(username, password);
      return result.fold(
        (exception) {
          _error = exception.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (authResponse) {
          _currentUser = authResponse.user;
          _isLoggedIn = true;
          _isLoading = false;
          _error = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _error = 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<bool> logout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.logout();
      return result.fold(
        (exception) {
          _error = exception.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (success) {
          _currentUser = null;
          _sessionInfo = null;
          _isLoggedIn = false;
          _isLoading = false;
          _error = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _error = 'Logout failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.authenticateWithBiometric();
      return result.fold(
        (exception) {
          _error = exception.message;
          _isLoading = false;
          notifyListeners();
          return false;
        },
        (authResponse) {
          _currentUser = authResponse.user;
          _isLoggedIn = true;
          _isLoading = false;
          _error = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _error = 'Biometric authentication failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Enable biometric
  Future<bool> enableBiometric(String password) async {
    try {
      final result = await _authRepository.enableBiometric(password);
      return result.fold(
        (exception) {
          _error = exception.message;
          notifyListeners();
          return false;
        },
        (success) {
          _isBiometricEnabled = true;
          _error = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _error = 'Failed to enable biometric';
      notifyListeners();
      return false;
    }
  }

  /// Disable biometric
  Future<bool> disableBiometric() async {
    try {
      final result = await _authRepository.disableBiometric();
      return result.fold(
        (exception) {
          _error = exception.message;
          notifyListeners();
          return false;
        },
        (success) {
          _isBiometricEnabled = false;
          _error = null;
          notifyListeners();
          return true;
        },
      );
    } catch (e) {
      _error = 'Failed to disable biometric';
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
