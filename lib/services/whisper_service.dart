import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class WhisperService {
  static const platform = MethodChannel('com.example.flutter_app/whisper');
  bool _modelLoaded = false;
  String? _loadedModelPath;
  String? _customModelPath;

  static final WhisperService _instance = WhisperService._internal();

  factory WhisperService() {
    return _instance;
  }

  WhisperService._internal();

  static WhisperService getInstance() => _instance;

  void setModelLoaded(bool loaded) {
    _modelLoaded = loaded;
    print('[WhisperService] Modelo marcado como: ${loaded ? "CARGADO" : "NO CARGADO"}');
  }

  String? getLoadedModelPath() => _loadedModelPath;

  bool isModelLoaded() => _modelLoaded;

  Future<void> loadModel({String? customPath}) async {
    try {
      print('\n========== [WhisperService] INICIANDO CARGA DE MODELO ==========');

      if (customPath != null) {
        _customModelPath = customPath;
        print('[WhisperService] Guardando ruta personalizada: $customPath');
        if (_loadedModelPath != customPath) {
          _modelLoaded = false;
          print('[WhisperService] Nueva ruta detectada, reseteando estado');
        }
      }

      if (_modelLoaded && _loadedModelPath == _customModelPath) {
        print('[WhisperService] ⚠️  Modelo ya estaba cargado con la misma ruta, retornando');
        return;
      }

      final modelPath = customPath ?? _customModelPath;
      if (modelPath == null) {
        throw Exception('Ruta del modelo no proporcionada');
      }

      print('[WhisperService] Ruta del modelo: $modelPath');
      print('[WhisperService] 🔄 Llamando a platform.invokeMethod("loadWhisperModel")...');

      final result = await platform.invokeMethod('loadWhisperModel', {
        'modelPath': modelPath,
      });

      print('[WhisperService] ✓ Respuesta del native: $result');

      _modelLoaded = true;
      _loadedModelPath = modelPath;
      print('[WhisperService] ✅ MODELO CARGADO EXITOSAMENTE');
      print('[WhisperService] Ruta: $modelPath');
      print('[WhisperService] Archivo: ${modelPath.split('/').last}');
      print('[WhisperService] ========== CARGA COMPLETADA ==========\n');
    } on PlatformException catch (e) {
      print('[WhisperService] ❌ PLATFORM EXCEPTION');
      print('[WhisperService] Código: ${e.code}');
      print('[WhisperService] Mensaje: ${e.message}');
      print('[WhisperService] Detalles: ${e.details}');
      throw Exception('Fallo al cargar modelo Whisper: ${e.message}');
    } catch (e) {
      print('[WhisperService] ❌ ERROR DESCONOCIDO');
      print('[WhisperService] Error: $e');
      rethrow;
    }
  }

  Future<String?> transcribeAudio(String audioPath) async {
    try {
      if (!_modelLoaded) {
        throw Exception('Modelo Whisper no está cargado');
      }

      print('[WhisperService] Iniciando transcripción de: $audioPath');

      final result = await platform.invokeMethod('transcribeAudio', {
        'audioPath': audioPath,
      });

      print('[WhisperService] ✅ Transcripción completada: $result');
      return result as String?;
    } on PlatformException catch (e) {
      print('[WhisperService] ❌ Error en transcripción: ${e.message}');
      throw Exception('Error transcribiendo audio: ${e.message}');
    } catch (e) {
      print('[WhisperService] ❌ Error: $e');
      rethrow;
    }
  }

  Future<String?> transcribeAudioFile(File audioFile) async {
    return transcribeAudio(audioFile.path);
  }
}
