import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  bool _isLoading = false;
  bool _isConversationEnded = false;
  final Uuid _uuid = const Uuid();
  String? _userId;
  FirestoreService? _firestoreService;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isConversationEnded => _isConversationEnded;
  
  final GeminiService _geminiService = GeminiService();

  static const String _welcomeMessage = 
    "Olá, eu sou o Psy! 👋\n\nEstou aqui para conversar com você sobre como está se sentindo. Este é um espaço seguro onde podemos falar sobre suas emoções, pensamentos e qualquer coisa que esteja em sua mente.\n\nComo está se sentindo hoje?";

  // Inicializar chat para usuário específico
  Future<void> initializeChat(String userId) async {
    _userId = userId;
    _firestoreService = FirestoreService(sessionId: userId);
    await _loadMessages();
    
    if (_messages.isEmpty) {
      _addWelcomeMessage();
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

  void _addWelcomeMessage() {
    final welcomeMsg = Message(
      id: _uuid.v4(),
      content: _welcomeMessage,
      type: MessageType.ai,
      timestamp: DateTime.now(),
    );
    _messages.add(welcomeMsg);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || _isLoading || _isConversationEnded || _userId == null) return;

    final isGoodbye = _isGoodbyeMessage(content);

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
      // Envia o histórico para o Gemini, mas sem a mensagem de "loading"
      final historyForApi =
          _messages.where((msg) => !msg.isLoading).toList();
      final response = await _geminiService.sendMessage(historyForApi);
      
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

      if (isGoodbye) {
        _isConversationEnded = true;
      }

      // Salvar analytics
      await FirestoreService.saveUsageAnalytics(_userId!, {
        'action': 'message_sent',
        'message_count': _messages.length,
        'conversation_ended': _isConversationEnded,
      });
      
    } catch (e) {
      _messages.removeLast();
      
      final errorMessage = Message(
        id: _uuid.v4(),
        content: 'Desculpe, tive um problema técnico. Vamos tentar novamente? 🤗',
        type: MessageType.ai,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  bool _isGoodbyeMessage(String message) {
    final goodbyeWords = ['tchau', 'bye', 'adeus', 'até logo', 'até mais', 'obrigado', 'obrigada'];
    final lowerMessage = message.toLowerCase();
    return goodbyeWords.any((word) => lowerMessage.contains(word));
  }

  Future<void> startNewConversation() async {
    if (_firestoreService == null) return;
    
    _messages.clear();
    _isConversationEnded = false;
    await _firestoreService!.clearMessages();
    _addWelcomeMessage();
    // Salva a nova mensagem de boas-vindas no Firestore
    await _firestoreService!.addMessage(_messages.first);
    notifyListeners();
  }

  Future<void> clearChat() async {
    if (_firestoreService == null) return;
    
    _messages.clear();
    _isConversationEnded = false;
    await _firestoreService!.clearMessages();
    notifyListeners();
  }
}
