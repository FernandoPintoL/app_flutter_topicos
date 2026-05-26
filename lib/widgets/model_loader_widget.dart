import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../react/agents/llm_agent.dart';

class ModelLoaderWidget extends StatefulWidget {
  final Function()? onModelLoaded;
  const ModelLoaderWidget({Key? key, this.onModelLoaded}) : super(key: key);

  @override
  State<ModelLoaderWidget> createState() => _ModelLoaderWidgetState();
}

class _ModelLoaderWidgetState extends State<ModelLoaderWidget> {
  late LLMAgent _llmAgent;
  bool _isLoading = false;
  String? _selectedPath;
  String? _errorMessage;
  bool _isModelLoaded = false;
  OverlayEntry? _loadingOverlay;

  @override
  void initState() {
    super.initState();
    _llmAgent = LLMAgent.getInstance();
    print('[ModelLoader] Usando LLMAgent singleton');
  }

  void _showLoadingOverlay(String filePath) {
    print('[ModelLoader] Creando overlay de carga...');
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Cargando modelo...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esto puede tomar 10 a 60 segundos',
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
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
      print('[ModelLoader] Insertando overlay en la pantalla');
      Overlay.of(context).insert(_loadingOverlay!);
      print('[ModelLoader] ✓ Overlay insertado');
    }
  }

  void _hideLoadingOverlay() {
    if (_loadingOverlay != null) {
      print('[ModelLoader] Removiendo overlay de carga');
      _loadingOverlay!.remove();
      _loadingOverlay = null;
      print('[ModelLoader] ✓ Overlay removido');
    }
  }

  Future<void> _pickModelFile() async {
    try {
      print('\n========== [ModelLoader] INICIANDO FLUJO DE SELECCIÓN ==========');

      setState(() {
        _errorMessage = null;
      });

      print('[ModelLoader] Abriendo file picker...');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Selecciona un modelo GGUF',
        lockParentWindow: true,
      );

      if (result == null) {
        print('[ModelLoader] ⚠️  Usuario canceló la selección');
        return;
      }

      final filePath = result.files.single.path!;
      print('[ModelLoader] ✓ Archivo seleccionado: $filePath');

      // Validar que sea un archivo .gguf
      if (!filePath.toLowerCase().endsWith('.gguf')) {
        print('[ModelLoader] ❌ Error: El archivo no es .gguf (extensión: ${filePath.split('.').last})');
        setState(() {
          _errorMessage = 'Por favor selecciona un archivo .gguf';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠ Debes seleccionar un archivo .gguf'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('[ModelLoader] ✓ Extensión válida: .gguf');
      print('[ModelLoader] Actualizando UI... isLoading=true');

      setState(() {
        _selectedPath = filePath;
        _isLoading = true;
      });

      print('[ModelLoader] 🎬 Mostrando overlay de carga...');

      if (!mounted) {
        print('[ModelLoader] ❌ Error: Widget no mounted, abortando');
        return;
      }

      _showLoadingOverlay(filePath);

      try {
        print('[ModelLoader] 🔄 INICIANDO CARGA DEL MODELO');
        print('[ModelLoader] Ruta original: $filePath');

        // Copiar archivo a ubicación privada de la app para evitar permisos
        print('[ModelLoader] 📋 Copiando archivo a almacenamiento privado...');
        final dir = await getApplicationDocumentsDirectory();
        final fileName = filePath.split('/').last;
        final privatePath = '${dir.path}/$fileName';

        print('[ModelLoader] Origen: $filePath');
        print('[ModelLoader] Destino: $privatePath');

        final sourceFile = File(filePath);
        final destFile = await sourceFile.copy(privatePath);

        print('[ModelLoader] ✓ Archivo copiado exitosamente');
        print('[ModelLoader] Tamaño: ${destFile.lengthSync()} bytes');

        // Cargar el modelo desde la ubicación privada
        print('[ModelLoader] Llamando a LLMAgent.loadModel()...');
        await _llmAgent.loadModel(customPath: privatePath);

        // Marcar como cargado en LLMAgent para futuras inferencias
        print('[ModelLoader] Marcando modelo como cargado en LLMAgent');
        _llmAgent.setModelLoaded(true);

        print('[ModelLoader] ✅ MODELO CARGADO EXITOSAMENTE');

        if (mounted) {
          print('[ModelLoader] Actualizando UI... isLoading=false, isModelLoaded=true');
          setState(() {
            _isLoading = false;
            _isModelLoaded = true;
            _errorMessage = null;
          });

          // Cerrar overlay de carga
          _hideLoadingOverlay();

          // Mostrar confirmación
          print('[ModelLoader] Mostrando SnackBar de éxito');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Modelo cargado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          print('[ModelLoader] Ejecutando callback onModelLoaded');
          widget.onModelLoaded?.call();
          print('[ModelLoader] ========== FLUJO COMPLETADO ==========\n');
        }
      } catch (e) {
        print('[ModelLoader] ❌ ERROR CARGANDO MODELO');
        print('[ModelLoader] Error: $e');
        print('[ModelLoader] StackTrace: ${StackTrace.current}');

        if (mounted) {
          // Cerrar overlay de carga
          _hideLoadingOverlay();

          print('[ModelLoader] Actualizando UI con error');
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          });

          print('[ModelLoader] Mostrando SnackBar de error');
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
            color: _isModelLoaded ? Colors.green.shade50 : Colors.blue.shade50,
            border: Border.all(
              color: _isModelLoaded ? Colors.green : Colors.blue,
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
                    _isModelLoaded ? Icons.check_circle : Icons.cloud_upload,
                    color: _isModelLoaded ? Colors.green : Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isModelLoaded
                              ? 'Modelo cargado ✓'
                              : 'Selecciona un modelo GGUF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isModelLoaded
                                ? Colors.green.shade800
                                : Colors.blue.shade800,
                            fontSize: 14,
                          ),
                        ),
                        if (_selectedPath != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedPath!.split('/').last,
                            style: TextStyle(
                              fontSize: 12,
                              color: (_isModelLoaded ? Colors.green : Colors.blue)
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
                  label: const Text('Seleccionar modelo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isModelLoaded ? Colors.grey : Colors.blue,
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
