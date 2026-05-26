import 'package:flutter/material.dart';
import '../services/openai_whisper_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIConfigWidget extends StatefulWidget {
  final Function()? onConfigured;
  const OpenAIConfigWidget({Key? key, this.onConfigured}) : super(key: key);

  @override
  State<OpenAIConfigWidget> createState() => _OpenAIConfigWidgetState();
}

class _OpenAIConfigWidgetState extends State<OpenAIConfigWidget> {
  late TextEditingController _apiKeyController;
  late OpenAIWhisperService _whisperService;
  bool _isConfigured = false;
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _whisperService = OpenAIWhisperService.getInstance();
    _apiKeyController = TextEditingController();

    // Intentar cargar API key desde .env
    _loadApiKeyFromEnv();
    _isConfigured = _whisperService.isConfigured();
  }

  void _loadApiKeyFromEnv() {
    try {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? dotenv.env['OPENAI_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        _whisperService.setApiKey(apiKey);
        _apiKeyController.text = apiKey;
        _isConfigured = true;
        print('[GroqConfig] API Key cargada desde .env');
      }
    } catch (e) {
      print('[GroqConfig] Error cargando .env: $e');
    }
  }

  void _saveApiKey() {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una API key'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!apiKey.startsWith('gsk_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key debe comenzar con "gsk_"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _whisperService.setApiKey(apiKey);

    setState(() {
      _isConfigured = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ API Key guardada'),
        backgroundColor: Colors.green,
      ),
    );

    widget.onConfigured?.call();
  }

  void _clearApiKey() {
    _apiKeyController.clear();
    _whisperService.setApiKey('');

    setState(() {
      _isConfigured = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API Key eliminada'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isConfigured ? Colors.purple.shade50 : Colors.blue.shade50,
        border: Border.all(
          color: _isConfigured ? Colors.purple : Colors.blue,
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
                _isConfigured ? Icons.check_circle : Icons.settings,
                color: _isConfigured ? Colors.purple : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isConfigured
                          ? 'Groq Whisper: Configurado ✓'
                          : 'Configura Groq Whisper',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isConfigured
                            ? Colors.purple.shade800
                            : Colors.blue.shade800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Speech-to-Text en la nube',
                      style: TextStyle(
                        fontSize: 12,
                        color: (_isConfigured ? Colors.purple : Colors.blue)
                            .shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isConfigured) ...[
            TextField(
              controller: _apiKeyController,
              obscureText: !_showApiKey,
              decoration: InputDecoration(
                hintText: 'gsk_...',
                labelText: 'Groq API Key',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showApiKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showApiKey = !_showApiKey;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveApiKey,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _apiKeyController.clear();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                '💡 Obtén tu API key en: https://console.groq.com/keys',
                style: TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'API Key: ${_whisperService.getApiKey()?.substring(0, 10)}...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple.shade600,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearApiKey,
                  icon: const Icon(Icons.delete),
                  label: const Text('Cambiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
