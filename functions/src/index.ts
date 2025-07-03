/* eslint-disable max-len */
import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {GoogleGenerativeAI, Content, HarmCategory, HarmBlockThreshold} from "@google/generative-ai";
import {defineString} from "firebase-functions/params";

admin.initializeApp();

// Define o parâmetro da chave da API do Gemini de forma segura.
// Este é o método moderno e recomendado para lidar com "secrets".
// A chave será gerenciada pelo Secret Manager do Google Cloud.
const geminiApiKey = defineString("GEMINI_API_KEY");

// Prompt do sistema que define a personalidade e as diretrizes do Psy.
const PSY_SYSTEM_PROMPT = `Você é o Psy, um terapeuta virtual acolhedor, calmo e empático. Sua função é oferecer um espaço seguro e tranquilo para o usuário conversar sobre o que quiser. Converse de forma leve, humana e respeitosa.

Use uma linguagem clara, gentil e acessível. Evite fazer muitas perguntas seguidas — prefira responder de forma empática, demonstrando escuta ativa. Quando fizer perguntas, que sejam breves, naturais e com propósito, como quem conduz uma conversa com cuidado.

Não ofereça diagnósticos, conselhos médicos ou interpretações clínicas. Em situações graves ou de risco, oriente com delicadeza a busca por um profissional ou serviço de emergência.

Quando o usuário disser "tchau", responda com carinho e se despeça de forma acolhedora. Se ele voltar após um tempo inativo, receba com uma saudação leve e positiva.

Seu papel é conversar com empatia e sensibilidade, sem exagerar no cuidado ou na intensidade. Mantenha o tom humano, calmo e natural.`;

/**
 * Função HTTPS "chamável" que recebe um histórico de conversa do app Flutter,
 * chama a API do Gemini no servidor e retorna a resposta.
 */
export const generateWithGemini = onCall({region: "us-central1"}, async (request) => {
  // Validação: Garante que o usuário está autenticado
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "A função deve ser chamada por um usuário autenticado.",
    );
  }

  // Validação: Garante que o histórico (contents) foi enviado
  const contents = request.data.contents as Content[];
  if (!contents || !Array.isArray(contents) || contents.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "A função deve ser chamada com um argumento 'contents' que é um array de histórico não vazio.",
    );
  }

  try {
    // Inicializa o cliente usando o valor do parâmetro seguro.
    const genAI = new GoogleGenerativeAI(geminiApiKey.value());

    // Configurações de segurança para serem menos restritivas.
    // As chamadas de servidor têm padrões mais rígidos do que as do cliente.
    // ATENÇÃO: Para produção, considere usar `BLOCK_MEDIUM_AND_ABOVE` ou `BLOCK_ONLY_HIGH`
    // para um melhor equilíbrio entre segurança e funcionalidade.
    const safetySettings = [
      {
        category: HarmCategory.HARM_CATEGORY_HARASSMENT,
        threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
      },
      {
        category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
        threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
      },
      {
        category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
        threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
      },
      {
        category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
        threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
      },
    ];
    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash-latest",
      safetySettings,
      systemInstruction: PSY_SYSTEM_PROMPT,
    });

    // O SDK do Gemini é inteligente, ele usará a última mensagem como o prompt
    // e as anteriores como histórico da conversa.
    const result = await model.generateContent({contents});
    const response = result.response;

    // Validação da resposta: Verifica se a resposta não foi bloqueada e contém texto.
    const candidate = response.candidates?.[0];
    if (!candidate) {
      console.warn("A resposta do Gemini não contém candidatos.", JSON.stringify(response));
      return {text: "Desculpe, não recebi uma resposta válida. Podemos tentar de novo?"};
    }

    // Verifica se a geração foi interrompida por um motivo diferente de "STOP".
    if (candidate.finishReason && candidate.finishReason !== "STOP" && candidate.finishReason !== "MAX_TOKENS") {
      console.warn(`Geração interrompida. Razão: ${candidate.finishReason}.`, JSON.stringify(response));
      return {text: "Desculpe, não consegui gerar uma resposta para isso. Podemos tentar falar de outra forma?"};
    }

    // Extrai o texto da primeira parte da resposta.
    const text = candidate.content?.parts?.[0]?.text;
    if (!text) {
      console.warn("A resposta do Gemini não continha texto.", JSON.stringify(response));
      return {text: "Recebi uma resposta, mas ela estava vazia. Por favor, tente novamente."};
    }

    return {text};
  } catch (error) {
    console.error("Erro ao chamar a API do Gemini:", error);
    throw new HttpsError(
      "internal",
      "Erro ao processar a sua solicitação.",
      error,
    );
  }
});
