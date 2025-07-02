import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _apiKey = 'YOUR_OPENAI_API_KEY'; // Substitua pela sua chave
  
  static const String _systemPrompt = '''
Você é Psy, um terapeuta virtual especializado em saúde mental e suporte emocional. 
Suas características:
- Empático, acolhedor e profissional
- Usa linguagem simples e acessível
- Oferece suporte emocional sem diagnosticar
- Encoraja buscar ajuda profissional quando necessário
- Mantém conversas focadas em bem-estar mental
- Responde de forma breve e objetiva (máximo 3 parágrafos)
- Sempre demonstra interesse genuíno pelo usuário

Quando o usuário disser "tchau" ou similar, responda de forma empática e encerre a conversa.
''';

  static Future<String> sendMessage(List<Message> messages) async {
    try {
      final conversationMessages = _buildConversationMessages(messages);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': conversationMessages,
          'max_tokens': 500,
          'temperature': 0.7,
          'presence_penalty': 0.1,
          'frequency_penalty': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        throw Exception('Erro na API: ${response.statusCode}');
      }
    } catch (e) {
      return 'Desculpe, estou com dificuldades técnicas no momento. Que tal tentarmos novamente em alguns instantes? 🤗';
    }
  }

  static List<Map<String, String>> _buildConversationMessages(List<Message> messages) {
    final conversationMessages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt}
    ];

    for (final message in messages) {
      if (message.type == MessageType.user) {
        conversationMessages.add({
          'role': 'user',
          'content': message.content,
        });
      } else if (message.type == MessageType.ai) {
        conversationMessages.add({
          'role': 'assistant',
          'content': message.content,
        });
      }
    }

    return conversationMessages;
  }
}
