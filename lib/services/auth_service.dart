import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psy_therapist/errors/errors_utils.dart';
import 'package:psy_therapist/errors/exceptions.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream do usuário atual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuário atual
  User? get currentUser => _auth.currentUser;

  // Registrar novo usuário
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // O usuário não será nulo em caso de sucesso.
      final user = credential.user!;

      // Atualizar display name se fornecido
      if (displayName != null && displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // Criar documento do usuário no Firestore
      await _createUserDocument(user);

      return credential;
    } catch (_) {
      rethrow;
    }
  }

  // Login com email e senha
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) {
        throw const AuthException('Falha na autenticação');
      }
      
      await _updateLastLogin(credential.user!.uid);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(ErrorUtils.tratarErroFirebaseAuth(e.code));
    } catch (e) {
      throw AuthException('Erro inesperado: ${e.toString()}');
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      // É uma boa prática logar este erro.
      rethrow;
    }
  }

  // Reset de senha
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (_) {
      rethrow;
    }
  }

  // Obter dados do usuário do Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      // É uma boa prática logar este erro.
      rethrow;
    }
  }

  // Atualizar dados do usuário
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      // É uma boa prática logar este erro.
      rethrow;
    }
  }

  // Criar documento do usuário no Firestore
  Future<void> _createUserDocument(User user) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoURL: user.photoURL,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      preferences: {
        'theme': 'light',
        'notifications': true,
        'language': 'pt-BR',
      },
    );

    await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
  }

  // Atualizar último login
  Future<void> _updateLastLogin(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'lastLoginAt': DateTime.now().toIso8601String(),
    });
  }

  // Tratar exceções do Firebase Auth
  /// Converte uma [FirebaseAuthException] em uma mensagem de erro legível para o usuário.
  /// Este método pode ser movido para uma classe de utilitários ou para a camada de UI
  /// para ser usado ao capturar as exceções relançadas pelos métodos do serviço.
  String handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este email já está sendo usado por outra conta.';
      case 'invalid-email':
        return 'O email fornecido é inválido.';
      case 'user-not-found':
        return 'O email fornecido é inválido.';
      case 'wrong-password':
        return 'O email fornecido é inválido.';
      case 'invalid-credential':
      // Por razões de segurança, o Firebase agora retorna 'invalid-credential'
      // tanto para "usuário não encontrado" quanto para "senha incorreta".
        return 'Credenciais inválidas. Verifique seu email e senha.';
      case 'user-disabled':
        return 'Esta conta foi desabilitada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
