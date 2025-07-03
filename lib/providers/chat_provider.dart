import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/message.dart';
import '../services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;
  final Uuid _uuid = const Uuid();
  String? _userId;
  FirestoreService? _firestoreService;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  
  // Instância do Firebase Functions (verifique a região no seu console do Firebase)
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  static const String _welcomeMessage = 
    "Olá, eu sou o Psy! 👋\n\nEstou aqui para conversar com você sobre como está se sentindo. Este é um espaço seguro onde podemos falar sobre suas emoções, pensamentos e qualquer coisa que esteja em sua mente.\n\nComo está se sentindo hoje?";

  // Inicializar chat para usuário específico
  Future<void> initializeChat(String userId) async {
    _userId = userId;
    _firestoreService = FirestoreService(sessionId: userId);
    await _loadMessages();
    
    if (_messages.isEmpty) {
      final welcomeMsg = _createWelcomeMessage();
      _messages.add(welcomeMsg);
      // Salva a mensagem de boas-vindas se o histórico estiver vazio
      await _firestoreService?.addMessage(welcomeMsg);
    }
    
    notifyListeners();
  }

  Future<void> _loadMessages() async {
    if (_firestoreService == null) return;

    try {
      final savedMessages = await _firestoreService!.loadMessages();
      _messages.clear();
      _messages.addAll(savedMessages);
    } catch (e) {
      print('Erro ao carregar mensagens: $e');
    }
  }

  Message _createWelcomeMessage() {
    return Message(
      id: _uuid.v4(),
      content: _welcomeMessage,
      type: MessageType.ai,
      timestamp: DateTime.now(),
    );
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isLoading || _userId == null) return;


    // Adicionar mensagem do usuário
    final userMessage = Message(
      id: _uuid.v4(),
      content: content.trim(),
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _firestoreService?.addMessage(userMessage); // Salva a mensagem do usuário imediatamente

    // Adicionar mensagem de loading da IA
    final loadingMessage = Message(
      id: _uuid.v4(),
      content: '',
      type: MessageType.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );
    _messages.add(loadingMessage);

    _isLoading = true;
    notifyListeners();

    try {
      // Converte o histórico de mensagens para o formato que a Cloud Function espera
      final historyForFunction = _messages
          .where((msg) => !msg.isLoading)
          .map((msg) => {
                'role': msg.type == MessageType.user ? 'user' : 'model',
                'parts': [{'text': msg.content}]
              })
          .toList();

      // Chama a nossa Cloud Function segura
      final callable = _functions.httpsCallable('generateWithGemini');
      final result = await callable.call<Map<String, dynamic>>({
        'contents': historyForFunction,
      });
      final response = result.data['text'] as String? ?? 'Desculpe, não consegui processar a resposta.';
      
      // Remover mensagem de loading
      _messages.removeLast();
      
      // Adicionar resposta da IA
      final aiMessage = Message(
        id: _uuid.v4(),
        content: response,
        type: MessageType.ai,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
      _firestoreService?.addMessage(aiMessage); // Salva a resposta da IA

      // Salvar analytics
      await FirestoreService.saveUsageAnalytics(_userId!, {
        'action': 'message_sent',
        'message_count': _messages.length,
      });
      
    } on FirebaseFunctionsException catch (e) {
      print('Erro na Cloud Function: ${e.code} - ${e.message}');
      _messages.removeLast(); // Remove o loading
      _addErrorMessage();
    } catch (e) {
      print('Erro inesperado ao enviar mensagem: $e');
      _messages.removeLast(); // Remove o loading
      _addErrorMessage();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _addErrorMessage() {
    final errorMessage = Message(
      id: _uuid.v4(),
      content: 'Desculpe, tive um problema técnico. Vamos tentar novamente? 🤗',
      type: MessageType.ai,
      timestamp: DateTime.now(),
    );
    _messages.add(errorMessage);
  }

  Future<void> startNewConversation() async {
    if (_firestoreService == null) return;
    
    _messages.clear();
    await _firestoreService!.clearMessages();
    final welcomeMsg = _createWelcomeMessage();
    _messages.add(welcomeMsg);
    // Salva a nova mensagem de boas-vindas no Firestore
    await _firestoreService!.addMessage(welcomeMsg);
    notifyListeners();
  }

  Future<void> clearChat() async {
    if (_firestoreService == null) return;

    _isLoading = false;
    _messages.clear();
    await _firestoreService!.clearMessages();
    notifyListeners();
  }
}
