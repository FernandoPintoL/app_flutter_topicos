import 'package:flutter/material.dart';
import '../services/model_status_service.dart';
import '../react/agents/llm_agent.dart';

class ModelStatusIndicator extends StatefulWidget {
  const ModelStatusIndicator({Key? key}) : super(key: key);

  @override
  State<ModelStatusIndicator> createState() => _ModelStatusIndicatorState();
}

class _ModelStatusIndicatorState extends State<ModelStatusIndicator> {
  bool _isLoaded = false;
  String _modelPath = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    // Check LLMAgent singleton first
    final llmAgent = LLMAgent.getInstance();
    final modelPath = llmAgent.getLoadedModelPath();
    final isLoaded = llmAgent.isModelLoaded();

    print('[ModelStatusIndicator] LLMAgent status: isLoaded=$isLoaded, modelPath=$modelPath');

    if (modelPath != null && modelPath.isNotEmpty && isLoaded) {
      setState(() {
        _isLoaded = true;
        _modelPath = modelPath;
        _isLoading = false;
      });
      return;
    }

    // Fallback: check native code
    final status = await ModelStatusService.getModelStatus();
    setState(() {
      _isLoaded = status['isLoaded'] as bool;
      _modelPath = status['modelPath'] as String;
      _error = status['error'] as String?;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isLoaded ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: _isLoaded ? Colors.green : Colors.orange,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _isLoaded ? Icons.check_circle : Icons.warning,
              color: _isLoaded ? Colors.green : Colors.orange,
              size: 24,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isLoading
                      ? 'Verificando modelo...'
                      : _isLoaded
                          ? 'Modelo cargado ✓'
                          : 'Modelo no encontrado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isLoaded ? Colors.green.shade800 : Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
                if (!_isLoading && _modelPath.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _modelPath.split('/').last,
                    style: TextStyle(
                      fontSize: 12,
                      color: (_isLoaded ? Colors.green : Colors.orange).shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_error != null && _error!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: ${_error!.split(':').first}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.red,
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
    );
  }
}
