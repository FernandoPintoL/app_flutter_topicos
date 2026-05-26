import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/env_config.dart';
import 'react/agents/api_agent.dart';
import 'services/auth_service.dart';

late Future<void> _initFuture;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preparar la inicialización
  _initFuture = _initializeApp();

  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  try {
    // Cargar configuración desde .env
    await EnvConfig.load();

    // Inicializar cliente API
    await ApiAgent.initialize();

    // Auto-login con credenciales del .env
    await AuthService.autoLogin();

    // Nota: El modelo se carga en el SplashScreen para no bloquear el main thread
    print('[main] ✅ Inicialización completada');
  } catch (e) {
    print('[main] ❌ Error durante inicialización: $e');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema IA - Gestión de Ventas',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: SplashScreen(initFuture: _initFuture),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
