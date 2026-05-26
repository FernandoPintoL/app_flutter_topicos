import 'package:flutter/foundation.dart';
import '../entities/command_intent.dart';
import 'api_agent.dart';

class DispatchAgent {
  static String _normalizeEntityType(String entityType) {
    switch (entityType) {
      // Usuario - variantes en inglés y español
      case 'user':
      case 'users':
      case 'usuario':
      case 'usuarios':
        return 'usuario';

      // Cliente - variantes
      case 'client':
      case 'clients':
      case 'customer':
      case 'customers':
      case 'cliente':
      case 'clientes':
        return 'cliente';

      // Proveedor - variantes
      case 'supplier':
      case 'suppliers':
      case 'provider':
      case 'providers':
      case 'proveedor':
      case 'proveedores':
        return 'proveedor';

      // Empresa - variantes
      case 'company':
      case 'companies':
      case 'business':
      case 'empresa':
      case 'empresas':
        return 'empresa';

      // Producto - variantes
      case 'product':
      case 'products':
      case 'item':
      case 'items':
      case 'producto':
      case 'productos':
        return 'producto';

      // Categoría - variantes
      case 'category':
      case 'categories':
      case 'categoria':
      case 'categorias':
        return 'producto';

      // Compra - variantes
      case 'purchase':
      case 'purchases':
      case 'buy':
      case 'buying':
      case 'compra':
      case 'compras':
        return 'compra';

      // Venta - variantes
      case 'sale':
      case 'sales':
      case 'sell':
      case 'selling':
      case 'venta':
      case 'ventas':
        return 'venta';

      // Auth
      case 'auth':
      case 'login':
      case 'authentication':
        return 'auth';

      default:
        return entityType;
    }
  }

  static Future<Map<String, dynamic>> dispatch(
    CommandIntent intent,
  ) async {
    var entityType = intent.entityType?.toLowerCase() ?? 'desconocido';

    // Normalizar variantes de nombres de entidades
    entityType = _normalizeEntityType(entityType);

    if (kDebugMode) {
      print('[DispatchAgent] Routing to: $entityType');
    }

    switch (entityType) {
      case 'auth':
        return _dispatchAuth(intent);
      case 'usuario':
        return _dispatchUsuario(intent);
      case 'cliente':
        return _dispatchCliente(intent);
      case 'proveedor':
        return _dispatchProveedor(intent);
      case 'empresa':
        return _dispatchEmpresa(intent);
      case 'producto':
      case 'categoria':
        return _dispatchProducto(intent);
      case 'compra':
        return _dispatchCompra(intent);
      case 'venta':
        return _dispatchVenta(intent);
      default:
        if (kDebugMode) {
          print('[ERROR] Entity type desconocido: $entityType');
        }
        return {
          'success': false,
          'error': 'Entity type desconocido: $entityType',
        };
    }
  }

  static Future<Map<String, dynamic>> _dispatchAuth(
    CommandIntent intent,
  ) async {
    try {
      final action = intent.action?.toLowerCase() ?? '';
      final params = intent.params;

      if (action == 'login') {
        final emailOrUsername = params['email_or_username'] as String?;
        final password = params['password'] as String?;

        if (emailOrUsername == null || password == null) {
          return {
            'success': false,
            'error': 'email_or_username y password requeridos',
          };
        }

        final response = await ApiAgent.login(
          emailOrUsername,
          password,
        );
        return response;
      }

      return {
        'success': false,
        'error': 'Action desconocida: $action',
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Error en dispatch_auth: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _dispatchUsuario(
    CommandIntent intent,
  ) async {
    try {
      final action = intent.action?.toLowerCase() ?? '';
      final params = intent.params;
      final userId = intent.id;

      if (action == 'create') {
        if (!params.containsKey('email') && params.containsKey('usernick')) {
          final usernick = params['usernick'] as String;
          final usernickClean = usernick
              .replaceAll('é', 'e')
              .replaceAll('á', 'a')
              .replaceAll('í', 'i')
              .replaceAll('ó', 'o')
              .replaceAll('ú', 'u');
          params['email'] = '$usernickClean@temp.local';
        }

        final response = await ApiAgent.request(
          'POST',
          '/usuarios',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'update') {
        if (userId == null) {
          return {
            'success': false,
            'error': 'ID de usuario requerido para actualizar',
          };
        }

        final response = await ApiAgent.request(
          'PUT',
          '/usuarios/$userId',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        final response = await ApiAgent.request('GET', '/usuarios');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      }

      return {
        'success': false,
        'error': 'Action desconocida: $action',
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Error en dispatch_usuario: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _dispatchCliente(
    CommandIntent intent,
  ) async {
    try {
      final action = intent.action?.toLowerCase() ?? '';
      final params = intent.params;
      final clientId = intent.id;

      if (action == 'create') {
        final response = await ApiAgent.request(
          'POST',
          '/clientes',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'update') {
        if (clientId == null) {
          return {
            'success': false,
            'error': 'ID de cliente requerido para actualizar',
          };
        }

        final response = await ApiAgent.request(
          'PUT',
          '/clientes/$clientId',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        final response = await ApiAgent.request('GET', '/clientes');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      }

      return {
        'success': false,
        'error': 'Action desconocida: $action',
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Error en dispatch_cliente: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _dispatchProveedor(
    CommandIntent intent,
  ) async {
    try {
      final action = intent.action?.toLowerCase() ?? '';
      final params = intent.params;
      final supplierId = intent.id;

      if (action == 'create') {
        final response = await ApiAgent.request(
          'POST',
          '/proveedores',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'update') {
        if (supplierId == null) {
          return {
            'success': false,
            'error': 'ID de proveedor requerido para actualizar',
          };
        }

        final response = await ApiAgent.request(
          'PUT',
          '/proveedores/$supplierId',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        final response =
            await ApiAgent.request('GET', '/proveedores');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      }

      return {
        'success': false,
        'error': 'Action desconocida: $action',
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Error en dispatch_proveedor: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _dispatchEmpresa(
    CommandIntent intent,
  ) async {
    try {
      final action = intent.action?.toLowerCase() ?? '';
      final params = intent.params;
      final companyId = intent.id;

      if (action == 'create') {
        final response = await ApiAgent.request(
          'POST',
          '/companies',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'update') {
        if (companyId == null) {
          return {
            'success': false,
            'error': 'ID de empresa requerido para actualizar',
          };
        }

        final response = await ApiAgent.request(
          'PUT',
          '/companies/$companyId',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        final response = await ApiAgent.request('GET', '/companies');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      }

      return {
        'success': false,
        'error': 'Action desconocida: $action',
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Error en dispatch_empresa: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _dispatchProducto(
    CommandIntent intent,
  ) async {
    try {
      final intentName = intent.intent?.toLowerCase() ?? '';
      final action = intent.action?.toLowerCase() ?? '';
      final params = intent.params;
      final productId = intent.id;

      if (intentName == 'crear_categoria') {
        final response = await ApiAgent.request(
          'POST',
          '/productos/categorias',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'create') {
        final response = await ApiAgent.request(
          'POST',
          '/productos',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'update') {
        if (productId == null) {
          return {
            'success': false,
            'error': 'ID de producto requerido para actualizar',
          };
        }

        final response = await ApiAgent.request(
          'PUT',
          '/productos/$productId',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        final response = await ApiAgent.request('GET', '/productos');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      }

      return {
        'success': false,
        'error': 'Action desconocida: $action',
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Error en dispatch_producto: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _dispatchCompra(
    CommandIntent intent,
  ) async {
    try {
      final action = intent.action?.toLowerCase() ?? '';
      final params = intent.params;

      if (action == 'create') {
        final response = await ApiAgent.request(
          'POST',
          '/compras',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        final response = await ApiAgent.request('GET', '/compras');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      }

      return {
        'success': false,
        'error': 'Action desconocida: $action',
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Error en dispatch_compra: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _dispatchVenta(
    CommandIntent intent,
  ) async {
    try {
      final action = intent.action?.toLowerCase() ?? '';
      final params = intent.params;

      if (action == 'create') {
        final response = await ApiAgent.request(
          'POST',
          '/ventas',
          body: params,
        );
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        final response = await ApiAgent.request('GET', '/ventas');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      }

      return {
        'success': false,
        'error': 'Action desconocida: $action',
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ERROR] Error en dispatch_venta: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
