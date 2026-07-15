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

        // Limpiar caracteres basura como |>, #, etc. que rompen el JSON
        cleanResult = cleanResult.replaceAll(RegExp(r'[|>#]+$'), '').trim();

        // Encontrar el primer { y el último } válido
        int firstBrace = cleanResult.indexOf('{');
        int lastBrace = cleanResult.lastIndexOf('}');
        if (firstBrace >= 0 && lastBrace > firstBrace) {
          cleanResult = cleanResult.substring(firstBrace, lastBrace + 1);
          print('[LLMAgent] 🧹 Limpiado: extrayendo JSON entre primeras { y últimas }');
        }

        print('[LLMAgent] Respuesta bruta: $cleanResult');

        // Detectar y eliminar secuencias largas de caracteres repetidos (modelo pegado)
        String processedResult = cleanResult;

        // Buscar patrones de repetición: 0000, 1111, etc. o cualquier char 5+ veces
        RegExp repeatedChars = RegExp(r'(.)\1{4,}');
        var match = repeatedChars.firstMatch(processedResult);
        if (match != null) {
          print('[LLMAgent] ⚠️  Detectada secuencia repetida: "${match.group(0)}" en posición ${match.start}');
          print('[LLMAgent] Truncando respuesta en ese punto...');
          processedResult = processedResult.substring(0, match.start);
        }

        // También buscar patrones problemáticos: cantidad, descripcion, notas (que no deberían estar en producto)
        if (processedResult.contains('"cantidad"')) {
          print('[LLMAgent] ⚠️  Campo "cantidad" detectado en respuesta (no permitido para producto)');
          // Truncar antes de "cantidad"
          int quantityIndex = processedResult.indexOf('"cantidad"');
          if (quantityIndex > 0) {
            // Encontrar el último "," o ":" válido antes de cantidad
            String beforeQuantity = processedResult.substring(0, quantityIndex);
            int lastCommaIndex = beforeQuantity.lastIndexOf(',');
            if (lastCommaIndex > 0) {
              processedResult = beforeQuantity.substring(0, lastCommaIndex) + '}}}';
              print('[LLMAgent] Truncado antes de "cantidad", cerrando JSON correctamente');
            }
          }
        }

        // Extraer múltiples JSONs válidos
        String? jsonStr;
        int braceCount = 0;
        int startIdx = -1;
        List<String> jsonObjects = [];

        for (int i = 0; i < processedResult.length; i++) {
          if (processedResult[i] == '{') {
            if (braceCount == 0) startIdx = i;
            braceCount++;
          } else if (processedResult[i] == '}') {
            braceCount--;
            if (braceCount == 0 && startIdx != -1) {
              String obj = processedResult.substring(startIdx, i + 1);
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
        } else {
          // Fallback: Si no se extrajeron JSONs válidos, intentar parsear processedResult directamente
          print('[LLMAgent] ⚠️  No se extrajeron JSONs con búsqueda de llaves, intentando parsear processedResult directamente...');
          jsonStr = processedResult;
        }

        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            // Limpiar caracteres de control y no imprimibles
            jsonStr = jsonStr.replaceAll(RegExp(r'[\p{Cc}\p{Cn}]+', unicode: true), '');
            // Eliminar caracteres nulos específicamente
            jsonStr = jsonStr.replaceAll(' ', '');
            // Limpiar espacios en blanco problemáticos
            jsonStr = jsonStr.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
            print('[LLMAgent] ✓ JSON extraído: $jsonStr');

            dynamic parsed;
            try {
              parsed = json_lib.jsonDecode(jsonStr);
            } catch (e) {
              // Si el parsing falla, intenta limpieza más agresiva
              print('[LLMAgent] ⚠️  Primer intento falló, aplicando limpieza agresiva...');

              // Convertir a códigos de carácter, filtrar inválidos, convertir de vuelta
              List<int> codeUnits = jsonStr.codeUnits;
              List<int> cleaned = [];

              for (int code in codeUnits) {
                // Mantener: ASCII imprimible (32-126) + JSON quotes (34) + básico UTF-8 (128+)
                if ((code >= 32 && code <= 126) || (code >= 128)) {
                  cleaned.add(code);
                } else if (code == 10 || code == 13 || code == 9) {
                  // Mantener newlines y tabs como espacios
                  cleaned.add(32);
                }
              }

              jsonStr = String.fromCharCodes(cleaned).trim();
              print('[LLMAgent] Reintentando con limpieza agresiva: $jsonStr');
              parsed = json_lib.jsonDecode(jsonStr);
            }
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
          print('[LLMAgent] Respuesta procesada: $processedResult');
          return CommandIntentList(
            intents: [
              CommandIntent(
                intent: 'desconocido',
                entityType: null,
                action: null,
                confidence: 0.0,
                error: 'No se encontró JSON válido en la respuesta del modelo',
              ),
            ],
          );
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
