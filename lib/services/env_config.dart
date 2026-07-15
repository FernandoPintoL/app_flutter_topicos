import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // API Configuration
  static String get businessApiUrl =>
    dotenv.env['BUSINESS_API_URL'] ?? 'http://localhost:8080';

  static int get businessApiTimeout =>
    int.parse(dotenv.env['BUSINESS_API_TIMEOUT'] ?? '30');

  // LLM Configuration
  static String get llmModelPath =>
    dotenv.env['LLM_MODEL_PATH'] ?? 'assets/models/qwen2.5-1.5b-instruct-q4_k_m.gguf';

  static int get llmNCtx =>
    int.parse(dotenv.env['LLM_N_CTX'] ?? '2048');

  static int get llmNThreads =>
    int.parse(dotenv.env['LLM_N_THREADS'] ?? '4');

  static int get llmMaxTokens =>
    int.parse(dotenv.env['LLM_MAX_TOKENS'] ?? '256');

  static double get llmTemperature =>
    double.parse(dotenv.env['LLM_TEMPERATURE'] ?? '0.1');

  static double get llmTopP =>
    double.parse(dotenv.env['LLM_TOP_P'] ?? '0.95');

  static int get llmTopK =>
    int.parse(dotenv.env['LLM_TOP_K'] ?? '40');

  // App Configuration
  static String get appName =>
    dotenv.env['APP_NAME'] ?? 'Sistema IA - Gestión de Ventas';

  static String get appVersion =>
    dotenv.env['APP_VERSION'] ?? '1.0.0';

  static bool get debugMode =>
    dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  // Load all env variables
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}
