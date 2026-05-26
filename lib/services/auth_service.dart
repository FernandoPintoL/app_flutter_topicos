import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../react/agents/api_agent.dart';

class AuthService {
  static bool _isLoggedIn = false;
  static String? _currentUser;

  static bool get isLoggedIn => _isLoggedIn;
  static String? get currentUser => _currentUser;

  static Future<bool> autoLogin() async {
    try {
      final username = dotenv.env['DEFAULT_LOGIN_USER'];
      final password = dotenv.env['DEFAULT_LOGIN_PASSWORD'];

      if (username == null || password == null) {
        print('[AuthService] ❌ Credenciales no configuradas en .env');
        return false;
      }

      print('[AuthService] 🔐 Intentando login automático con usuario: $username');

      await ApiAgent.initialize();
      final response = await ApiAgent.login(username, password);

      if (response['token'] != null) {
        _isLoggedIn = true;
        _currentUser = username;
        print('[AuthService] ✅ Login exitoso para usuario: $username');
        print('[AuthService] 🔑 Token obtenido');
        return true;
      } else {
        print('[AuthService] ❌ Login fallido: ${response['error']}');
        return false;
      }
    } catch (e) {
      print('[AuthService] ❌ Error en login automático: $e');
      return false;
    }
  }

  static void logout() {
    _isLoggedIn = false;
    _currentUser = null;
    print('[AuthService] 👋 Sesión cerrada');
  }
}
