import 'package:flutter/services.dart';

class ModelValidatorService {
  static const platform = MethodChannel('com.example.flutter_app/model');

  static Future<bool> checkModelExists(String modelPath) async {
    try {
      final exists = await platform.invokeMethod<bool>(
        'checkFileExists',
        {'path': modelPath},
      );
      return exists ?? false;
    } catch (e) {
      print('[ModelValidator] Error checking model: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getModelInfo(String modelPath) async {
    try {
      final info = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'getFileInfo',
        {'path': modelPath},
      );
      return Map<String, dynamic>.from(info ?? {});
    } catch (e) {
      print('[ModelValidator] Error getting model info: $e');
      return {};
    }
  }

  static String getInstructions(String expectedPath) {
    return '''
Modelo no encontrado

El modelo no está en: $expectedPath

SOLUCIÓN - Transfiere el archivo con ADB:

1. Abre PowerShell en la carpeta del modelo
2. Ejecuta:

   adb push "qwen2.5-1.5b-instruct-q4_k_m.gguf" "/sdcard/Download/"

3. Verifica:

   adb shell ls -lh /sdcard/Download/qwen2.5-1.5b-instruct-q4_k_m.gguf

4. Reinicia la app
    ''';
  }
}
