import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final Directory tempDir = await getTemporaryDirectory();
        _currentPath = '${tempDir.path}/command_${DateTime.now().millisecondsSinceEpoch}.wav';

        const config = RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        );

        await _recorder.start(config, path: _currentPath!);
        return true;
      }
      return false;
    } catch (e) {
      print('[AudioService] Error al iniciar grabación: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      print('[AudioService] Error al detener grabación: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
