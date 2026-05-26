import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../react/containers/command_container.dart';
import '../widgets/model_status_indicator.dart';
import '../widgets/model_loader_widget.dart';
import '../widgets/openai_config_widget.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommandContainer(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema IA - Gestión de Ventas'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar pantalla',
            onPressed: () {
              context.read<CommandContainer>().clearResponse();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✓ Pantalla reiniciada'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: AuthService.isLoggedIn
                  ? Chip(
                      avatar: const Icon(Icons.check_circle, color: Colors.white),
                      label: Text('${AuthService.currentUser} ✅'),
                      backgroundColor: Colors.green,
                      labelStyle: const TextStyle(color: Colors.white),
                    )
                  : Chip(
                      avatar: const Icon(Icons.lock, color: Colors.white),
                      label: const Text('No autenticado'),
                      backgroundColor: Colors.red,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
      body: Consumer<CommandContainer>(
        builder: (context, container, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Selector de modelo
                ModelLoaderWidget(
                  onModelLoaded: () {
                    print('[HomeScreen] Modelo cargado, actualizando estado');
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (context.mounted) {
                        context.read<CommandContainer>().updateModelStatus();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Estado del modelo
                const ModelStatusIndicator(),
                const SizedBox(height: 16),

                // Configuración OpenAI Whisper
                OpenAIConfigWidget(
                  onConfigured: () {
                    print('[HomeScreen] OpenAI Whisper configurado');
                  },
                ),
                const SizedBox(height: 16),

                // Título
                const Text(
                  'Ingresa un comando:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Input de texto
                TextField(
                  controller: container.textController,
                  decoration: InputDecoration(
                    hintText: 'Ej: Crea un cliente llamado Juan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: container.textController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              container.textController.clear();
                            },
                          ),
                  ),
                  onChanged: (_) {
                    // Trigger rebuild para mostrar/ocultar botón clear
                    context.read<CommandContainer>();
                  },
                  enabled: !container.isLoading,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: container.isLoading
                            ? null
                            : () {
                                container.sendTextCommand(
                                  container.textController.text,
                                  context: context,
                                );
                              },
                        icon: container.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          container.isLoading ? 'Procesando...' : 'Enviar',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: container.isLoading
                          ? null
                          : () {
                              if (container.isRecording) {
                                container.stopRecording(context);
                              } else {
                                container.startRecording();
                              }
                            },
                      icon: Icon(container.isRecording ? Icons.stop : Icons.mic),
                      label: Text(container.isRecording ? 'Detener' : 'Audio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: container.isRecording 
                            ? Colors.red 
                            : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (container.isRecording)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      '🔴 Grabando audio...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 12),

                // Mensaje de error
                if (container.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      container.errorMessage!,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                if (container.errorMessage != null)
                  const SizedBox(height: 12),

                // Respuesta JSON
                if (container.lastResponse != null) ...[
                  const Text(
                    'Respuesta JSON:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Text(
                        JsonEncoder.withIndent('  ')
                            .convert(container.lastResponse!.toJson()),
                        style: const TextStyle(
                          color: Colors.green,
                          fontFamily: 'Courier',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      container.clearResponse();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Limpiar'),
                  ),
                ] else if (!container.isLoading)
                  SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Ingresa un comando y presiona "Enviar"',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }
}
