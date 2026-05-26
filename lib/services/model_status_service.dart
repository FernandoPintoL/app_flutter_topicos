import 'dart:async';
import 'package:flutter/services.dart';

class ModelStatusService {
  static const String _channel = 'com.example.app/llm';
  static const _methodChannel = MethodChannel(_channel);

  static Future<Map<String, dynamic>> getModelStatus() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getModelStatus',
      );

      if (result != null) {
        return {
          'isLoaded': result['isLoaded'] as bool,
          'modelPath': result['modelPath'] as String,
        };
      }

      return {
        'isLoaded': false,
        'modelPath': '',
      };
    } catch (e) {
      print('[ModelStatusService] Error: $e');
      return {
        'isLoaded': false,
        'modelPath': '',
        'error': e.toString(),
      };
    }
  }

  static Stream<Map<String, dynamic>> watchModelStatus({
    Duration interval = const Duration(seconds: 2),
  }) {
    return Stream.periodic(interval, (_) => getModelStatus()).asyncExpand(
      (future) => future.asStream(),
    );
  }
}
