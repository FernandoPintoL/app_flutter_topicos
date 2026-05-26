class ApiResponse {
  final bool success;
  final String input;
  final String type;
  final String? intent;
  final String? entityType;
  final String? action;
  final double? confidence;
  final dynamic result;
  final String? message;
  final String? error;

  ApiResponse({
    required this.success,
    required this.input,
    required this.type,
    this.intent,
    this.entityType,
    this.action,
    this.confidence,
    this.result,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      input: json['input'] ?? '',
      type: json['type'] ?? 'text',
      intent: json['intent'],
      entityType: json['entity_type'],
      action: json['action'],
      confidence: (json['confidence'] as num?)?.toDouble(),
      result: json['result'],
      message: json['message'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'input': input,
      'type': type,
      'intent': intent,
      'entity_type': entityType,
      'action': action,
      'confidence': confidence,
      'result': result,
      'message': message,
      'error': error,
    };
  }
}
