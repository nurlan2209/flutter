import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authRepository.authStateChanges.listen((User? user) async {
      if (user != null) {
        _currentUser = await _userRepository.getUser(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      _currentUser = await _authRepository.signUp(
        email: email,
        password: password,
        name: name,
      );
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _error = null;
      
      _currentUser = await _authRepository.signIn(
        email: email,
        password: password,
      );
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;
      
      _currentUser = await _authRepository.signInWithGoogle();
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      await _authRepository.resetPassword(email);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}