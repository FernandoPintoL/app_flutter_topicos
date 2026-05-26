import 'package:flutter/material.dart';
import '../types/command_request.dart';
import '../entities/api_response.dart';
import '../entities/command_intent.dart';
import '../agents/llm_agent.dart';
import '../agents/dispatch_agent.dart';
import '../../widgets/inference_loading_dialog.dart';
import '../../services/audio_service.dart';
import '../../services/openai_whisper_service.dart';

class CommandContainer extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final LLMAgent _llmAgent = LLMAgent.getInstance();
  final AudioService _audioService = AudioService();
  final OpenAIWhisperService _whisperService = OpenAIWhisperService.getInstance();

  bool isLoading = false;
  bool isRecording = false;
  ApiResponse? lastResponse;
  String? errorMessage;
  String? loadedModelPath;
  bool isModelLoaded = false;

  void updateModelStatus() {
    loadedModelPath = _llmAgent.getLoadedModelPath();
    isModelLoaded = _llmAgent.isModelLoaded();
    print('[CommandContainer] Modelo actualizado: isLoaded=$isModelLoaded, path=$loadedModelPath');
    notifyListeners();
  }

  Future<void> process(CommandRequest request, {BuildContext? context}) async {
    if (request is TextCommandRequest && request.text.isEmpty) {
      errorMessage = 'Por favor ingresa un comando';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    String input = request is TextCommandRequest
        ? request.text
        : (request as AudioCommandRequest).audioPath;

    if (context != null) {
      InferenceLoadingDialog.show(context, input);
    }

    try {
      print('\n========== [CommandContainer] PROCESANDO SOLICITUD ==========');

      if (request is TextCommandRequest) {
        print('[CommandContainer] Tipo: TEXT');
        print('[CommandContainer] Input: "${request.text}"');
      } else if (request is AudioCommandRequest) {
        print('[CommandContainer] Tipo: AUDIO');
        print('[CommandContainer] Audio: ${request.audioPath}');
      }

      updateModelStatus();
      print('[CommandContainer] Modelo cargado: $isModelLoaded');
      print('[CommandContainer] Ruta del modelo: $loadedModelPath');

      // 1. Procesar comando con LLM local
      final commandIntentList = await _llmAgent.infer(request);

      // 2. Procesar múltiples intents secuencialmente
      final List<Map<String, dynamic>> results = [];
      final Map<String, dynamic> context = {}; // Para almacenar referencias entre comandos

      for (int i = 0; i < commandIntentList.intents.length; i++) {
        final commandIntent = commandIntentList.intents[i];
        print('[CommandContainer] Procesando intent ${i + 1}/${commandIntentList.intents.length}: ${commandIntent.intent}');

        // Reemplazar referencias en params
        var params = _substituteReferences(commandIntent.params, context);

        // Despachar a API
        final apiResult = await DispatchAgent.dispatch(
          CommandIntent(
            intent: commandIntent.intent,
            entityType: commandIntent.entityType,
            action: commandIntent.action,
            confidence: commandIntent.confidence,
            params: params,
            id: commandIntent.id,
          ),
        );

        results.add(apiResult);

        // Guardar ID si fue un create para referencias futuras
        if (commandIntent.action?.toLowerCase() == 'create' &&
            apiResult['success'] == true &&
            apiResult['id'] != null) {
          final refKey = '${commandIntent.entityType}_id';
          context[refKey] = apiResult['id'];
          print("[CommandContainer] Guardando referencia: $refKey = ${apiResult['id']}");
        }
      }

      // 3. Envolver resultado en ApiResponse
      final input = request is TextCommandRequest
          ? request.text
          : (request as AudioCommandRequest).audioPath;

      final allSuccess = results.every((r) => r['success'] == true);
      final firstIntent = commandIntentList.intents.first;

      lastResponse = ApiResponse(
        success: allSuccess,
        input: input,
        type: request is TextCommandRequest ? 'text' : 'audio',
        intent: firstIntent.intent,
        entityType: firstIntent.entityType,
        action: firstIntent.action,
        confidence: firstIntent.confidence,
        result: commandIntentList.isMultiStep ? results : results.first,
        error: !allSuccess
            ? results.firstWhere((r) => r['success'] != true)['error'] as String?
            : null,
        message: commandIntentList.isMultiStep
            ? 'Ejecutadas ${results.length} acciones'
            : null,
      );

      if (!lastResponse!.success) {
        errorMessage = lastResponse!.error ?? 'Error desconocido';
      }
      print('[CommandContainer] ========== SOLICITUD COMPLETADA ==========\n');
    } catch (e) {
      errorMessage = 'Error: $e';
      lastResponse = ApiResponse(
        success: false,
        input: input,
        type: request is TextCommandRequest ? 'text' : 'audio',
        error: e.toString(),
      );
      print('[CommandContainer] ❌ ERROR: $e\n');
    } finally {
      if (context != null) {
        InferenceLoadingDialog.hide();
      }
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> startRecording() async {
    final started = await _audioService.startRecording();
    if (started) {
      isRecording = true;
      notifyListeners();
    }
  }

  Future<void> stopRecording(BuildContext context) async {
    isRecording = false;
    notifyListeners();

    final path = await _audioService.stopRecording();
    if (path != null) {
      // Transcribir con Groq Whisper si está configurado
      if (_whisperService.isConfigured()) {
        try {
          print('[CommandContainer] 🎤 Transcribiendo audio con Groq Whisper...');
          final transcribedText = await _whisperService.transcribeAudio(path);

          if (transcribedText != null && transcribedText.isNotEmpty) {
            print('[CommandContainer] ✅ Transcripción: $transcribedText');
            textController.text = transcribedText;
            await sendTextCommand(transcribedText, context: context);
            return;
          }
        } catch (e) {
          print('[CommandContainer] ⚠️ Error transcribiendo: $e');
          errorMessage = 'Error en transcripción: $e';
          notifyListeners();
        }
      } else {
        errorMessage = 'OpenAI API Key no configurada';
        notifyListeners();
      }

      // Fallback: procesar como audio si Whisper no está disponible
      await sendAudioCommand(path, context: context);
    }
  }

  Future<void> sendTextCommand(String input, {BuildContext? context}) async {
    final request = CommandRequest.text(input);
    await process(request, context: context);
  }

  Future<void> sendAudioCommand(String audioPath, {BuildContext? context}) async {
    final request = CommandRequest.audio(audioPath);
    await process(request, context: context);
  }

  Map<String, dynamic> _substituteReferences(
    Map<String, dynamic>? params,
    Map<String, dynamic> context,
  ) {
    if (params == null || params.isEmpty) return {};

    final Map<String, dynamic> result = {};

    params.forEach((key, value) {
      if (value is String && value.startsWith('{ref_') && value.endsWith('}')) {
        // Reemplazar referencia
        final refKey = value.substring(1, value.length - 1); // Quitar { y }
        result[key] = context[refKey] ?? value;
        print('[CommandContainer] Sustituyendo $key: $refKey → ${result[key]}');
      } else if (value is List) {
        // Procesar items en lista (para ventas)
        result[key] = (value as List).map((item) {
          if (item is Map<String, dynamic>) {
            return _substituteReferences(item, context);
          }
          return item;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        result[key] = _substituteReferences(value, context);
      } else {
        result[key] = value;
      }
    });

    return result;
  }

  void clearResponse() {
    lastResponse = null;
    textController.clear();
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    _llmAgent.dispose();
    super.dispose();
  }
}
