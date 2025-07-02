import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:psy_therapist/apikey.dart';
import 'package:psy_therapist/models/message.dart';

//const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
const String _apiKey = APIKEYGEMINI;

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    if (_apiKey.isEmpty) {
      throw Exception('A chave GEMINI_API_KEY não foi definida.');
    }
    _model = GenerativeModel(
      // Use o modelo 'gemini-1.5-flash-latest' para respostas mais rápidas ou 'gemini-pro'
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
      // Opcional: Defina configurações de segurança
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  Future<String> sendMessage(List<Message> messages) async {
    try {
      // Converte o histórico de mensagens do seu app para o formato do Gemini.
      final content = messages.map((msg) {
        // A API do Gemini espera os papéis 'user' e 'model'.
        // Usamos a propriedade 'type' para definir o papel (role).
        final role = msg.type == MessageType.user ? 'user' : 'model';
        return Content(role, [TextPart(msg.content)]);
      }).toList();

      final response = await _model.generateContent(content);

      final text = response.text;
      if (text == null) {
        throw Exception('Recebi uma resposta nula da API do Gemini.');
      }
      return text;
    } catch (e) {
      print('Erro ao enviar mensagem para o Gemini: $e');
      return 'Desculpe, ocorreu um erro ao contatar a IA. Tente novamente.';
    }
  }
}