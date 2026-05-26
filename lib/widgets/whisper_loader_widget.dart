import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/whisper_service.dart';

class WhisperLoaderWidget extends StatefulWidget {
  final Function()? onModelLoaded;
  const WhisperLoaderWidget({Key? key, this.onModelLoaded}) : super(key: key);

  @override
  State<WhisperLoaderWidget> createState() => _WhisperLoaderWidgetState();
}

class _WhisperLoaderWidgetState extends State<WhisperLoaderWidget> {
  late WhisperService _whisperService;
  bool _isLoading = false;
  String? _selectedPath;
  String? _errorMessage;
  bool _isModelLoaded = false;
  OverlayEntry? _loadingOverlay;

  @override
  void initState() {
    super.initState();
    _whisperService = WhisperService.getInstance();
    print('[WhisperLoader] Usando WhisperService singleton');
  }

  void _showLoadingOverlay(String filePath) {
    print('[WhisperLoader] Creando overlay de carga...');
    _loadingOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cargando Whisper...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esto puede tomar 5 a 30 segundos',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      filePath.split('/').last,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Courier',
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      print('[WhisperLoader] Insertando overlay en la pantalla');
      Overlay.of(context).insert(_loadingOverlay!);
      print('[WhisperLoader] ✓ Overlay insertado');
    }
  }

  void _hideLoadingOverlay() {
    if (_loadingOverlay != null) {
      print('[WhisperLoader] Removiendo overlay de carga');
      _loadingOverlay!.remove();
      _loadingOverlay = null;
      print('[WhisperLoader] ✓ Overlay removido');
    }
  }

  Future<void> _pickModelFile() async {
    try {
      print('\n========== [WhisperLoader] INICIANDO FLUJO DE SELECCIÓN ==========');

      setState(() {
        _errorMessage = null;
      });

      print('[WhisperLoader] Abriendo file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Selecciona un modelo Whisper GGML',
        lockParentWindow: true,
      );

      if (result == null) {
        print('[WhisperLoader] ⚠️  Usuario canceló la selección');
        return;
      }

      final filePath = result.files.single.path!;
      print('[WhisperLoader] ✓ Archivo seleccionado: $filePath');

      if (!filePath.toLowerCase().endsWith('.bin')) {
        print('[WhisperLoader] ❌ Error: El archivo no es .bin (extensión: ${filePath.split('.').last})');
        setState(() {
          _errorMessage = 'Por favor selecciona un archivo .bin';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠ Debes seleccionar un archivo .bin'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('[WhisperLoader] ✓ Extensión válida: .bin');

      setState(() {
        _selectedPath = filePath;
        _isLoading = true;
      });

      print('[WhisperLoader] 🎬 Mostrando overlay de carga...');

      if (!mounted) {
        print('[WhisperLoader] ❌ Error: Widget no mounted, abortando');
        return;
      }

      _showLoadingOverlay(filePath);

      try {
        print('[WhisperLoader] 🔄 INICIANDO CARGA DEL MODELO');
        print('[WhisperLoader] Ruta original: $filePath');

        final dir = await getApplicationDocumentsDirectory();
        final fileName = filePath.split('/').last;
        final privatePath = '${dir.path}/$fileName';

        print('[WhisperLoader] Origen: $filePath');
        print('[WhisperLoader] Destino: $privatePath');

        final sourceFile = File(filePath);
        final destFile = await sourceFile.copy(privatePath);

        print('[WhisperLoader] ✓ Archivo copiado exitosamente');
        print('[WhisperLoader] Tamaño: ${destFile.lengthSync()} bytes');

        print('[WhisperLoader] Llamando a WhisperService.loadModel()...');
        await _whisperService.loadModel(customPath: privatePath);

        print('[WhisperLoader] Marcando modelo como cargado en WhisperService');
        _whisperService.setModelLoaded(true);

        print('[WhisperLoader] ✅ MODELO CARGADO EXITOSAMENTE');

        if (mounted) {
          print('[WhisperLoader] Actualizando UI... isLoading=false, isModelLoaded=true');
          setState(() {
            _isLoading = false;
            _isModelLoaded = true;
            _errorMessage = null;
          });

          _hideLoadingOverlay();

          print('[WhisperLoader] Mostrando SnackBar de éxito');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Whisper cargado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          print('[WhisperLoader] Ejecutando callback onModelLoaded');
          widget.onModelLoaded?.call();
          print('[WhisperLoader] ========== FLUJO COMPLETADO ==========\n');
        }
      } catch (e) {
        print('[WhisperLoader] ❌ ERROR CARGANDO MODELO');
        print('[WhisperLoader] Error: $e');

        if (mounted) {
          _hideLoadingOverlay();

          print('[WhisperLoader] Actualizando UI con error');
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });

          print('[WhisperLoader] Mostrando SnackBar de error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✗ Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isModelLoaded ? Colors.green.shade50 : Colors.orange.shade50,
            border: Border.all(
              color: _isModelLoaded ? Colors.green : Colors.orange,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _isModelLoaded ? Icons.check_circle : Icons.mic,
                    color: _isModelLoaded ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isModelLoaded
                              ? 'Whisper cargado ✓'
                              : 'Selecciona modelo Whisper',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isModelLoaded
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                            fontSize: 14,
                          ),
                        ),
                        if (_selectedPath != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedPath!.split('/').last,
                            style: TextStyle(
                              fontSize: 12,
                              color: (_isModelLoaded ? Colors.green : Colors.orange)
                                  .shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading)
                const SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(),
                )
              else
                ElevatedButton.icon(
                  onPressed: _isModelLoaded ? null : _pickModelFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Seleccionar Whisper'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isModelLoaded ? Colors.grey : Colors.orange,
                  ),
                ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Text(
              'Error: $_errorMessage',
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
