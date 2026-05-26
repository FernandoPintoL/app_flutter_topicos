sealed class CommandRequest {
  final DateTime timestamp;

  const CommandRequest({required this.timestamp});

  factory CommandRequest.text(String text) => TextCommandRequest(
        text: text,
        timestamp: DateTime.now(),
      );

  factory CommandRequest.audio(String audioPath) => AudioCommandRequest(
        audioPath: audioPath,
        timestamp: DateTime.now(),
      );
}

class TextCommandRequest extends CommandRequest {
  final String text;

  const TextCommandRequest({
    required this.text,
    required super.timestamp,
  });
}

class AudioCommandRequest extends CommandRequest {
  final String audioPath;

  const AudioCommandRequest({
    required this.audioPath,
    required super.timestamp,
  });
}
