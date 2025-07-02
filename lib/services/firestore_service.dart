import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psy_therapist/models/message.dart';

class FirestoreService {
  // Instância do Cloud Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<Message> _messagesRef;
  final String _sessionId;

  FirestoreService({required String sessionId}) : _sessionId = sessionId {
    _messagesRef = _db
        .collection('chats')
        .doc(_sessionId)
        .collection('messages')
        .withConverter<Message>(
          fromFirestore: (snapshots, _) => Message.fromJson(snapshots.data()!),
          toFirestore: (message, _) => message.toJson(),
        );
  }

  /// Carrega as mensagens de uma sessão de uma única vez.
  Future<List<Message>> loadMessages() async {
    final snapshot =
        await _messagesRef.orderBy('timestamp', descending: false).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Salva uma única nova mensagem no Firestore.
  Future<void> addMessage(Message message) async {
    try {
      await _messagesRef.doc(message.id).set(message);
    } catch (e) {
      print("Erro ao salvar mensagem no Firestore: $e");
      rethrow;
    }
  }

  /// Apaga todas as mensagens da sessão de chat atual.
  Future<void> clearMessages() async {
    final snapshot = await _messagesRef.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Método estático para salvar dados de analytics.
  static Future<void> saveUsageAnalytics(
      String userId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('analytics')
          .add({...data, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Erro ao salvar analytics: $e');
    }
  }
}