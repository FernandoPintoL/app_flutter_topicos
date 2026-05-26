class CommandIntent {
  final String? intent;
  final String? entityType;
  final String? action;
  final double? confidence;
  final Map<String, dynamic> params;
  final int? id;
  final String? error;

  CommandIntent({
    this.intent,
    this.entityType,
    this.action,
    this.confidence,
    Map<String, dynamic>? params,
    this.id,
    this.error,
  }) : params = params ?? {};

  bool get isValid => intent != null && entityType != null && error == null;

  factory CommandIntent.fromJson(Map<String, dynamic> json) {
    return CommandIntent(
      intent: json['intent'],
      entityType: json['entity_type'],
      action: json['action'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      params: json['params'] as Map<String, dynamic>? ?? {},
      id: json['id'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      'entity_type': entityType,
      'action': action,
      'confidence': confidence,
      'params': params,
      'id': id,
      'error': error,
    };
  }
}
