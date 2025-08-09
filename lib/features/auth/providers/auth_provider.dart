import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boardbuddy/features/auth/data/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  AuthState _state = AuthState.initial;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuthListener();
  }

  // -------- Initialize Auth State Listener ----------
  void _initAuthListener() {
    _authRepository.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    });
  }

  // -------- Google Sign-In ----------
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user == null) {
        _setError('Google sign-in was cancelled.');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // -------- Email Sign-In ----------
  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.signInWithEmail(email, password);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // -------- Email Registration ----------
  Future<void> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.registerWithEmail(email, password, name);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // -------- Password Reset ----------
  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.sendPasswordResetEmail(email);
      // You might want to show a success message here
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // -------- Sign-Out ----------
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // -------- Delete Account ----------
  Future<void> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.deleteAccount();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // -------- Get User Data ----------
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      return await _authRepository.getUserData(uid);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // -------- Private State Management ----------
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _setState(AuthState.loading);
    }
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(AuthState.error);
  }

  void _clearError() {
    _errorMessage = null;
  }

  // -------- Clear Error (for UI) ----------
  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
