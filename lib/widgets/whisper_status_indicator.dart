import 'package:flutter/material.dart';
import '../services/whisper_service.dart';

class WhisperStatusIndicator extends StatelessWidget {
  const WhisperStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final whisperService = WhisperService.getInstance();
    final isLoaded = whisperService.isModelLoaded();
    final modelPath = whisperService.getLoadedModelPath();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLoaded ? Colors.orange.shade50 : Colors.grey.shade100,
        border: Border.all(
          color: isLoaded ? Colors.orange : Colors.grey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isLoaded ? Icons.check_circle : Icons.schedule,
            color: isLoaded ? Colors.orange : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoaded ? 'Whisper: Listo' : 'Whisper: No cargado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isLoaded ? Colors.orange.shade800 : Colors.grey.shade700,
                  ),
                ),
                if (isLoaded && modelPath != null)
                  Text(
                    modelPath.split('/').last,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
