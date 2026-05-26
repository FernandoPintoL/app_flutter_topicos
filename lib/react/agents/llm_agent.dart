import 'dart:async';
import 'dart:convert' as json_lib;
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../types/command_request.dart';
import '../entities/command_intent.dart';
import '../entities/command_intent_list.dart';
import '../../constants/system_prompt.dart';
import '../../constants/gbnf_grammar.dart';
import '../../services/env_config.dart';

class LLMAgent {
  static const platform = MethodChannel('com.example.flutter_app/llm');
  bool _modelLoaded = false;
  String? _loadedModelPath;
  String? _customModelPath;

  static final LLMAgent _instance = LLMAgent._internal();

  factory LLMAgent() {
    return _instance;
  }

  LLMAgent._internal();

  static LLMAgent getInstance() => _instance;

  void setModelLoaded(bool loaded) {
    _modelLoaded = loaded;
    print('[LLMAgent] Modelo marcado como: ${loaded ? "CARGADO" : "NO CARGADO"}');
  }

  String? getLoadedModelPath() => _loadedModelPath;

  bool isModelLoaded() => _modelLoaded;

  Future<void> loadModel({String? customPath}) async {
    try {
      print('\n========== [LLMAgent] INICIANDO CARGA DE MODELO ==========');

      // Guardar customPath para reintentos posteriores
      if (customPath != null) {
        _customModelPath = customPath;
        print('[LLMAgent] Guardando ruta personalizada: $customPath');
        // Resetear estado si es una nueva ruta
        if (_loadedModelPath != customPath) {
          _modelLoaded = false;
          print('[LLMAgent] Nueva ruta detectada, reseteando estado');
        }
      }

      if (_modelLoaded && _loadedModelPath == (_customModelPath ?? EnvConfig.llmModelPath)) {
        print('[LLMAgent] ⚠️  Modelo ya estaba cargado con la misma ruta, retornando');
        return;
      }

      final modelPath = customPath ?? _customModelPath ?? EnvConfig.llmModelPath;
      print('[LLMAgent] Ruta del modelo: $modelPath');
      print('[LLMAgent] Ruta personalizada: ${customPath != null}');
      print('[LLMAgent] Configuración:');
      print('[LLMAgent]   - nCtx: ${EnvConfig.llmNCtx}');
      print('[LLMAgent]   - nThreads: ${EnvConfig.llmNThreads}');

      print('[LLMAgent] 🔄 Llamando a platform.invokeMethod("loadModel")...');

      final result = await platform.invokeMethod('loadModel', {
        'modelPath': modelPath,
        'nCtx': EnvConfig.llmNCtx,
        'nThreads': EnvConfig.llmNThreads,
      });

      print('[LLMAgent] ✓ Respuesta del native: $result');

      _modelLoaded = true;
      _loadedModelPath = modelPath;
      print('[LLMAgent] ✅ MODELO CARGADO EXITOSAMENTE');
      print('[LLMAgent] Ruta: $modelPath');
      print('[LLMAgent] Archivo: ${modelPath.split('/').last}');
      print('[LLMAgent] ========== CARGA COMPLETADA ==========\n');
    } on PlatformException catch (e) {
      print('[LLMAgent] ❌ PLATFORM EXCEPTION');
      print('[LLMAgent] Código: ${e.code}');
      print('[LLMAgent] Mensaje: ${e.message}');
      print('[LLMAgent] Detalles: ${e.details}');
      throw Exception('Fallo al cargar modelo: ${e.message}');
    } catch (e) {
      print('[LLMAgent] ❌ ERROR DESCONOCIDO');
      print('[LLMAgent] Error: $e');
      print('[LLMAgent] Type: ${e.runtimeType}');
      rethrow;
    }
  }

  Future<CommandIntentList> infer(CommandRequest request) async {
    try {
      print('\n========== [LLMAgent] INICIANDO INFERENCIA ==========');

      late String userInput;

      if (request is TextCommandRequest) {
        userInput = request.text;
        print('[LLMAgent] Tipo: TEXT');
        print('[LLMAgent] Input: "$userInput"');
      } else if (request is AudioCommandRequest) {
        print('[LLMAgent] Tipo: AUDIO');
        print('[LLMAgent] Audio path: ${request.audioPath}');
        userInput = await _performStt(request.audioPath);
        print('[LLMAgent] STT resultado: "$userInput"');
      } else {
        throw Exception('CommandRequest type no soportado');
      }

      if (!_modelLoaded) {
        print('[LLMAgent] ⚠️  Modelo no cargado, cargando primero...');
        await loadModel();
      } else {
        print('[LLMAgent] ✓ Modelo ya estaba cargado');
      }

      final prompt =
          '<|im_start|>system\n$SYSTEM_PROMPT<|im_end|>\n<|im_start|>user\n$userInput<|im_end|>\n<|im_start|>assistant\n';

      print('[LLMAgent] 🔄 Ejecutando inferencia...');
      print('[LLMAgent] Configuración:');
      print('[LLMAgent]   - maxTokens: ${EnvConfig.llmMaxTokens}');
      print('[LLMAgent]   - temperature: ${EnvConfig.llmTemperature}');
      print('[LLMAgent]   - topP: ${EnvConfig.llmTopP}');
      print('[LLMAgent]   - topK: ${EnvConfig.llmTopK}');

      dynamic result;
      try {
        result = await platform.invokeMethod('inference', {
          'prompt': prompt,
          'maxTokens': EnvConfig.llmMaxTokens,
          'temperature': EnvConfig.llmTemperature,
          'topP': EnvConfig.llmTopP,
          'topK': EnvConfig.llmTopK,
          'grammar': GBNF_GRAMMAR,
        });
      } catch (e) {
        final errorStr = e.toString();
        if (errorStr.contains('Modelo no cargado')) {
          print('[LLMAgent] ⚠️  Modelo se descargó, recargando...');
          _modelLoaded = false;
          await loadModel();
          print('[LLMAgent] 🔄 Reintentando inferencia después de recargar...');
          result = await platform.invokeMethod('inference', {
            'prompt': prompt,
            'maxTokens': EnvConfig.llmMaxTokens,
            'temperature': EnvConfig.llmTemperature,
            'topP': EnvConfig.llmTopP,
            'topK': EnvConfig.llmTopK,
            'grammar': GBNF_GRAMMAR,
          });
        } else {
          rethrow;
        }
      }

      print('[LLMAgent] ✅ Respuesta del modelo: $result');

      if (result is String) {
        print('[LLMAgent] 🔍 Parseando JSON de la respuesta...');

        // Limpiar respuesta: eliminar todo después de <|endoftext|>
        String cleanResult = result;
        if (result.contains('<|endoftext|>')) {
          cleanResult = result.substring(0, result.indexOf('<|endoftext|>'));
          print('[LLMAgent] ⚠️  Eliminando tokens después de <|endoftext|>');
        }

        print('[LLMAgent] Respuesta bruta: $cleanResult');

        // Extraer múltiples JSONs válidos
        String? jsonStr;
        int braceCount = 0;
        int startIdx = -1;
        List<String> jsonObjects = [];

        for (int i = 0; i < cleanResult.length; i++) {
          if (cleanResult[i] == '{') {
            if (braceCount == 0) startIdx = i;
            braceCount++;
          } else if (cleanResult[i] == '}') {
            braceCount--;
            if (braceCount == 0 && startIdx != -1) {
              String obj = cleanResult.substring(startIdx, i + 1);
              jsonObjects.add(obj);
              startIdx = -1;
            }
          }
        }

        // Si tenemos múltiples objetos, envolverlos en un array
        if (jsonObjects.length > 1) {
          jsonStr = '[${jsonObjects.join(', ')}]';
          print('[LLMAgent] 📋 Multi-intent detectado: ${jsonObjects.length} objetos JSON encontrados');
        } else if (jsonObjects.length == 1) {
          jsonStr = jsonObjects.first;
        }

        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            print('[LLMAgent] ✓ JSON extraído: $jsonStr');

            final parsed = json_lib.jsonDecode(jsonStr);
            print('[LLMAgent] ✓ JSON decodificado');

            // Parsear como lista o single object
            CommandIntentList intentList;

            if (parsed is List) {
              print('[LLMAgent] 📋 Multi-intent detectado: ${parsed.length} acciones');
              intentList = CommandIntentList.fromJson(parsed);
            } else if (parsed is Map<String, dynamic>) {
              print('[LLMAgent] 📝 Single-intent detectado');
              intentList = CommandIntentList.fromJson(parsed);
            } else {
              print('[LLMAgent] ⚠️  JSON no es válido, es: ${parsed.runtimeType}');
              return CommandIntentList(
                intents: [
                  CommandIntent(
                    intent: 'desconocido',
                    entityType: null,
                    action: null,
                    confidence: 0.0,
                    error: 'Respuesta JSON no es un objeto válido',
                  ),
                ],
              );
            }

            print('[LLMAgent] ✓ JSON parseado correctamente');
            print('[LLMAgent] ✅ ${intentList.isMultiStep ? 'Multi-step' : 'Single-step'} intent creado');

            for (var intent in intentList.intents) {
              print('[LLMAgent]   - ${intent.intent} (${intent.action}) params: ${intent.params}');
            }

            print('[LLMAgent] ========== INFERENCIA COMPLETADA ==========\n');

            return intentList;
          } catch (e) {
            print('[LLMAgent] ❌ Error al parsear JSON: $e');
            print('[LLMAgent] StackTrace: $e');
            print('[LLMAgent] Retornando intent desconocido');
            return CommandIntentList(
              intents: [
                CommandIntent(
                  intent: 'desconocido',
                  entityType: null,
                  action: null,
                  confidence: 0.0,
                  error: 'Fallo al parsear respuesta JSON: $e',
                ),
              ],
            );
          }
        } else {
          print('[LLMAgent] ❌ No se encontró JSON válido en la respuesta');
        }
      }

      print('[LLMAgent] ❌ Respuesta no es String o no contiene JSON');
      return CommandIntentList(
        intents: [
          CommandIntent(
            intent: 'desconocido',
            entityType: null,
            action: null,
            confidence: 0.0,
            error: 'Respuesta inválida del modelo',
          ),
        ],
      );
    } catch (e) {
      print('[LLMAgent] ❌ EXCEPCIÓN EN INFERENCIA');
      print('[LLMAgent] Error: $e');
      print('[LLMAgent] StackTrace: ${StackTrace.current}');
      return CommandIntentList(
        intents: [
          CommandIntent(
            intent: 'desconocido',
            entityType: null,
            action: null,
            confidence: 0.0,
            error: e.toString(),
          ),
        ],
      );
    }
  }

  Future<String> _performStt(String audioPath) async {
    try {
      print('[LLMAgent] 🔄 Iniciando STT para: $audioPath');

      dynamic result;
      try {
        result = await platform.invokeMethod('sttInference', {
          'audioPath': audioPath,
          'maxTokens': EnvConfig.llmMaxTokens,
          'temperature': EnvConfig.llmTemperature,
          'topP': EnvConfig.llmTopP,
          'topK': EnvConfig.llmTopK,
          'grammar': GBNF_GRAMMAR,
        });
      } catch (e) {
        final errorStr = e.toString();
        if (errorStr.contains('Modelo no cargado')) {
          print('[LLMAgent] ⚠️  Modelo se descargó durante STT, recargando...');
          _modelLoaded = false;
          await loadModel();
          print('[LLMAgent] 🔄 Reintentando STT después de recargar...');
          result = await platform.invokeMethod('sttInference', {
            'audioPath': audioPath,
            'maxTokens': EnvConfig.llmMaxTokens,
            'temperature': EnvConfig.llmTemperature,
            'topP': EnvConfig.llmTopP,
            'topK': EnvConfig.llmTopK,
            'grammar': GBNF_GRAMMAR,
          });
        } else {
          rethrow;
        }
      }

      if (result is String && result.isNotEmpty) {
        print('[LLMAgent] ✓ STT completado: $result');
        return result;
      }

      throw Exception('STT no devolvió un resultado válido');
    } catch (e) {
      print('[LLMAgent] ❌ Error en STT: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _parseJsonStrict(String jsonStr) {
    try {
      return Map<String, dynamic>.from(
        json_lib.jsonDecode(jsonStr) as Map,
      );
    } catch (e) {
      print('[ERROR] JSON parse error: $e');
      throw Exception('Invalid JSON: $e');
    }
  }

  // Función estática para ejecutar en Isolate
  static Future<String> _inferenceInIsolate(Map<String, dynamic> params) async {
    try {
      final result = await LLMAgent.platform.invokeMethod('inference', params);
      return result as String;
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    try {
      platform.invokeMethod('dispose');
      _modelLoaded = false;
    } catch (e) {
      print('[ERROR] Error al limpiar LLM: $e');
    }
  }
}
