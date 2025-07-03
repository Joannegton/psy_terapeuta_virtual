import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isProfileLoading = false; // Novo loading exclusivo para perfil
  String? _error;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isProfileLoading => _isProfileLoading;

  AuthProvider(this._authService) {
    // Escutar mudanças no estado de autenticação
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
  _user = user;
  _error = null;
  _isLoading = true; // Indicar carregamento enquanto busca dados

  if (user != null) {
    try {
      _userModel = await _authService.getUserData(user.uid);
    } catch (e) {
      _error = 'Erro ao carregar dados do usuário: $e';
      _userModel = null;
    }
  } else {
    _userModel = null;
  }

  _isLoading = false;
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

      await _authService.registerWithEmailAndPassword(
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

    print('Tentando login com email: $email'); // Log para depuração

    await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return true;
  } on FirebaseAuthException catch (e) {
    _error = _authService.handleAuthException(e);
    print('Erro de autenticação: $_error'); // Log para depuração
    return false;
  } catch (e) {
    _error = 'Erro inesperado ao fazer login: $e';
    print('Erro inesperado: $_error'); // Log para depuração
    return false;
  } finally {
    _setLoading(false);
  }
}

  // Logout
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
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

      await _authService.resetPassword(email);
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

      await _authService.updateUserData(_user!.uid, data);
      _userModel = await _authService.getUserData(_user!.uid);
      
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

    _isProfileLoading = true;
    notifyListeners();
    _error = null;

    //TODO mover para o AuthService
    try {
      await _user!.updateDisplayName(trimmedName);

      await _authService.updateUserData(_user!.uid, {'displayName': trimmedName});

      await _user!.reload();
      _user = _authService.currentUser;

      _userModel = await _authService.getUserData(_user!.uid);
    } catch (e) {
      _error = "Erro ao atualizar o nome: ${e.toString()}";
      rethrow;
    } finally {
      _isProfileLoading = false;
      notifyListeners();
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
