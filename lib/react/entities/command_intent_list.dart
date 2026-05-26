import 'command_intent.dart';

class CommandIntentList {
  final List<CommandIntent> intents;
  final bool isMultiStep;

  CommandIntentList({
    required this.intents,
    this.isMultiStep = false,
  });

  factory CommandIntentList.fromJson(dynamic json) {
    if (json is List) {
      final intents = (json as List)
          .map((item) => CommandIntent.fromJson(item as Map<String, dynamic>))
          .toList();
      return CommandIntentList(
        intents: intents,
        isMultiStep: intents.length > 1,
      );
    } else if (json is Map<String, dynamic>) {
      return CommandIntentList(
        intents: [CommandIntent.fromJson(json)],
        isMultiStep: false,
      );
    }
    return CommandIntentList(
      intents: [
        CommandIntent(
          intent: 'desconocido',
          entityType: null,
          action: null,
          confidence: 0.0,
          error: 'No se pudo parsear el JSON',
        ),
      ],
      isMultiStep: false,
    );
  }

  List<Map<String, dynamic>> toJson() {
    return intents.map((intent) => intent.toJson()).toList();
  }
}
