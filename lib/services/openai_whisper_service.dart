import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OpenAIWhisperService {
  static const String _apiBaseUrl = 'https://api.groq.com/openai/v1';
  static const String _model = 'whisper-large-v3-turbo';

  String? _apiKey;
  bool _isConfigured = false;

  static final OpenAIWhisperService _instance = OpenAIWhisperService._internal();

  factory OpenAIWhisperService() {
    return _instance;
  }

  OpenAIWhisperService._internal();

  static OpenAIWhisperService getInstance() => _instance;

  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    _isConfigured = apiKey.isNotEmpty;
    print('[GroqWhisper] API Key configurada: ${apiKey.substring(0, 10)}...');
  }

  String? getApiKey() => _apiKey;

  bool isConfigured() => _isConfigured;

  Future<String?> transcribeAudio(String audioPath) async {
    try {
      if (!_isConfigured || _apiKey == null) {
        throw Exception('API Key no configurada');
      }

      print('[GroqWhisper] Iniciando transcripción de: $audioPath');

      final file = File(audioPath);
      if (!file.existsSync()) {
        throw Exception('Archivo de audio no existe: $audioPath');
      }

      print('[GroqWhisper] Tamaño del archivo: ${file.lengthSync()} bytes');

      // Crear request multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/audio/transcriptions'),
      );

      // Agregar headers
      request.headers['Authorization'] = 'Bearer $_apiKey';

      // Agregar archivo de audio
      request.files.add(
        await http.MultipartFile.fromPath('file', audioPath),
      );

      // Agregar parámetros
      request.fields['model'] = _model;
      request.fields['language'] = 'es'; // Español

      print('[GroqWhisper] Enviando a OpenAI API...');

      // Enviar request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('[GroqWhisper] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parsear respuesta JSON
        final responseBody = response.body;
        print('[GroqWhisper] Respuesta: $responseBody');

        // Extraer texto de la respuesta JSON
        final jsonMap = _parseJson(responseBody);
        final text = jsonMap['text'] as String?;

        if (text != null && text.isNotEmpty) {
          print('[GroqWhisper] ✅ Transcripción: $text');
          return text;
        } else {
          throw Exception('No se obtuvo texto en la respuesta');
        }
      } else {
        final error = response.body;
        print('[GroqWhisper] ❌ Error ${response.statusCode}: $error');
        throw Exception('Error OpenAI: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('[GroqWhisper] ❌ Exception: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      // Parsing manual para evitar dependencias adicionales
      if (jsonString.contains('"text":')) {
        final startIndex = jsonString.indexOf('"text":"') + 8;
        final endIndex = jsonString.indexOf('"', startIndex);
        final text = jsonString.substring(startIndex, endIndex);
        return {'text': text};
      }
      throw Exception('Formato JSON inesperado');
    } catch (e) {
      print('[GroqWhisper] Error parseando JSON: $e');
      throw Exception('Error parseando respuesta: $e');
    }
  }
}
