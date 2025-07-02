import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Escutar mudanças no estado de autenticação
    AuthService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    _error = null;

    if (user != null) {
      try {
        _userModel = await AuthService.getUserData(user.uid);
      } catch (e) {
        _error = e.toString();
      }
    } else {
      _userModel = null;
    }

    notifyListeners();
  }

  // Registrar novo usuário
  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await AuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await AuthService.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Reset de senha
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _error = null;

      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar dados do usuário
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _error = null;

      await AuthService.updateUserData(_user!.uid, data);
      _userModel = await AuthService.getUserData(_user!.uid);
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza o nome de exibição do usuário no Firebase Auth e no Firestore.
  Future<void> updateUserName(String newName) async {
    if (_user == null) {
      _error = "Usuário não autenticado.";
      notifyListeners();
      throw Exception(_error);
    }

    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      _error = "O nome não pode ser vazio.";
      notifyListeners();
      throw Exception(_error);
    }

    _setLoading(true);
    _error = null;

    try {
      // 1. Atualiza o nome no Firebase Authentication
      await _user!.updateDisplayName(trimmedName);

      // 2. Atualiza o nome no documento do usuário no Firestore
      await AuthService.updateUserData(_user!.uid, {'displayName': trimmedName});

      // 3. Atualiza o modelo de usuário local
      _userModel = await AuthService.getUserData(_user!.uid);
    } catch (e) {
      _error = "Erro ao atualizar o nome: ${e.toString()}";
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
