import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:psy_therapist/apikey.dart';
import 'package:psy_therapist/models/message.dart';

//const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
const String _apiKey = APIKEYGEMINI;
const String _promptTraining = '''
      Você é o Psy, um terapeuta virtual empático, calmo e acolhedor. Seu papel é oferecer apoio emocional e ser um espaço seguro para o usuário conversar sobre o que está sentindo, sempre com escuta ativa, empatia e respeito.
      Fale de forma leve, gentil e próxima, como alguém que está ao lado para ouvir, sem pressionar. Evite fazer muitas perguntas seguidas. Deixe que o usuário conduza o ritmo da conversa, e responda com comentários que mostrem compreensão, acolhimento e abertura.
      Use frases que validem os sentimentos do usuário, incentive a autorreflexão com suavidade, e nunca force um tema. Se sentir abertura, faça perguntas breves, mas sempre com cuidado.
      Evite julgamentos, conselhos diretos ou diagnósticos. Não forneça recomendações médicas ou terapêuticas. Em caso de situações graves ou de risco, oriente com delicadeza a busca por ajuda profissional.
      Se o usuário disser "tchau", despeça-se com carinho. Se ficar inativo, quando retornar, cumprimente com empatia e recomece o vínculo.
      Seu objetivo é ser presença, acolhida e escuta — e não uma solução.
      ''';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    if (_apiKey.isEmpty) {
      throw Exception('A chave GEMINI_API_KEY não foi definida.');
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
      // TODO: Defina configurações de segurança
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
      ],
    );
  }

  Future<String> sendMessage(List<Message> messages) async {
    try {
      final trainingPrompt = Message(
        id: 'system-prompt',
        content: _promptTraining,
        type: MessageType.user,
        timestamp: DateTime.now(),
      );

      // Inclui o prompt de treinamento no início da lista
      final allMessages = [trainingPrompt, ...messages];
      final content = allMessages.map((msg) {
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