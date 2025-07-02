import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Salvar mensagens do chat
  static Future<void> saveMessages(String userId, List<Message> messages) async {
    try {
      final batch = _firestore.batch();
      final chatRef = _firestore.collection('users').doc(userId).collection('chats');

      // Limpar mensagens antigas
      final oldMessages = await chatRef.get();
      for (final doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }

      // Adicionar novas mensagens
      for (final message in messages) {
        final docRef = chatRef.doc(message.id);
        batch.set(docRef, message.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao salvar mensagens: $e');
    }
  }

  // Carregar mensagens do chat
  static Future<List<Message>> loadMessages(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .orderBy('timestamp')
          .get();

      return snapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Limpar mensagens do chat
  static Future<void> clearMessages(String userId) async {
    try {
      final batch = _firestore.batch();
      final chatRef = _firestore.collection('users').doc(userId).collection('chats');
      
      final messages = await chatRef.get();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Erro ao limpar mensagens: $e');
    }
  }

  // Salvar analytics de uso
  static Future<void> saveUsageAnalytics(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('analytics')
          .add({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Analytics não são críticos, apenas log do erro
      print('Erro ao salvar analytics: $e');
    }
  }
}
