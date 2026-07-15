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

      print('[DispatchAgent] 👤 Procesando USUARIO');
      print('[DispatchAgent] Action: $action');
      print('[DispatchAgent] Params: ${params.toString()}');

      if (action == 'create') {
        if (!params.containsKey('usernick') || !params.containsKey('password')) {
          return {
            'success': false,
            'error': 'Se requiere usernick y password para crear usuario',
          };
        }

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

        if (params.containsKey('nombre') && !params.containsKey('name')) {
          params['name'] = params.remove('nombre');
        }

        print('[DispatchAgent] → Creando usuario...');
        final response = await ApiAgent.request(
          'POST',
          '/usuarios',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
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

        print('[DispatchAgent] → Actualizando usuario $userId...');
        final response = await ApiAgent.request(
          'PUT',
          '/usuarios/$userId',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        print('[DispatchAgent] → Listando usuarios...');
        final response = await ApiAgent.request('GET', '/usuarios');
        print('[DispatchAgent] Response: ${response.toString()}');
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

      print('[DispatchAgent] 🤝 Procesando CLIENTE');
      print('[DispatchAgent] Action: $action');
      print('[DispatchAgent] Params: ${params.toString()}');

      if (action == 'create') {
        if (!params.containsKey('ci')) {
          return {
            'success': false,
            'error': 'Se requiere cédula/RIF (ci) para crear cliente',
          };
        }

        if (params.containsKey('nombre') && !params.containsKey('name')) {
          params['name'] = params.remove('nombre');
        }

        if (params.containsKey('telefono') && !params.containsKey('phone')) {
          params['phone'] = params.remove('telefono');
        }

        print('[DispatchAgent] → Creando cliente...');
        final response = await ApiAgent.request(
          'POST',
          '/clientes',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
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

        print('[DispatchAgent] → Actualizando cliente $clientId...');
        final response = await ApiAgent.request(
          'PUT',
          '/clientes/$clientId',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        print('[DispatchAgent] → Listando clientes...');
        final response = await ApiAgent.request('GET', '/clientes');
        print('[DispatchAgent] Response: ${response.toString()}');
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

      print('[DispatchAgent] 🏭 Procesando PROVEEDOR');
      print('[DispatchAgent] Action: $action');
      print('[DispatchAgent] Params: ${params.toString()}');

      if (action == 'create') {
        print('[DispatchAgent] → Creando proveedor...');
        final response = await ApiAgent.request(
          'POST',
          '/proveedores',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
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

        print('[DispatchAgent] → Actualizando proveedor $supplierId...');
        final response = await ApiAgent.request(
          'PUT',
          '/proveedores/$supplierId',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        print('[DispatchAgent] → Listando proveedores...');
        final response =
            await ApiAgent.request('GET', '/proveedores');
        print('[DispatchAgent] Response: ${response.toString()}');
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

      print('[DispatchAgent] 🏢 Procesando EMPRESA');
      print('[DispatchAgent] Action: $action');
      print('[DispatchAgent] Params: ${params.toString()}');

      if (action == 'create') {
        print('[DispatchAgent] → Creando empresa...');
        final response = await ApiAgent.request(
          'POST',
          '/companies',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
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

        print('[DispatchAgent] → Actualizando empresa $companyId...');
        final response = await ApiAgent.request(
          'PUT',
          '/companies/$companyId',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        print('[DispatchAgent] → Listando empresas...');
        final response = await ApiAgent.request('GET', '/companies');
        print('[DispatchAgent] Response: ${response.toString()}');
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

      print('[DispatchAgent] 🏪 Procesando PRODUCTO');
      print('[DispatchAgent] Action: $action');
      print('[DispatchAgent] Params: ${params.toString()}');

      if (intentName == 'crear_categoria') {
        print('[DispatchAgent] → Creando categoría...');
        final response = await ApiAgent.request(
          'POST',
          '/categorias',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'create') {
        print('[DispatchAgent] → Creando producto...');
        final response = await ApiAgent.request(
          'POST',
          '/productos',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'update') {
        // Verificar si es un ajuste de stock
        if ((params.containsKey('stock') || params.containsKey('items')) && !params.containsKey('nombre') && !params.containsKey('name')) {
          // Es un ajuste de stock

          // Caso 1: Múltiples productos con items
          if (params.containsKey('items') && params['items'] is List) {
            final items = params['items'] as List;
            final results = [];

            for (final item in items) {
              if (item is! Map<String, dynamic>) continue;

              int? productToUpdate = productId;
              final itemName = item['product_name'] as String?;
              final itemStock = item['stock'];

              if (productToUpdate == null && itemName != null) {
                final productsResponse = await ApiAgent.request('GET', '/productos');

                List products = [];
                if (productsResponse is List) {
                  products = productsResponse as List;
                } else if (productsResponse is Map && productsResponse['data'] is List) {
                  products = productsResponse['data'] as List;
                }

                if (products.isNotEmpty) {
                  final productNameLower = itemName.toLowerCase();
                  final found = products.firstWhere(
                    (p) => (p['name'] as String).toLowerCase().contains(productNameLower),
                    orElse: () => null,
                  );
                  if (found != null) {
                    productToUpdate = found['id'];
                  }
                }
              }

              if (productToUpdate == null) {
                results.add({
                  'product_name': itemName,
                  'success': false,
                  'error': 'Producto no encontrado',
                });
                continue;
              }

              print('[DispatchAgent] → Ajustando stock de $itemName ($productToUpdate) a $itemStock...');
              final response = await ApiAgent.request(
                'PATCH',
                '/productos/$productToUpdate/stock',
                body: {
                  'quantity': itemStock,
                  'type': 'set',
                },
              );
              results.add({
                'product_name': itemName,
                'success': !response.containsKey('error'),
                ...response,
              });
            }

            return {
              'success': results.every((r) => r['success'] == true),
              'results': results,
            };
          }

          // Caso 2: Un solo producto
          int? productToUpdate = productId;
          if (productToUpdate == null) {
            final productsResponse = await ApiAgent.request('GET', '/productos');

            List products = [];
            if (productsResponse is List) {
              products = productsResponse as List;
            } else if (productsResponse is Map && productsResponse['data'] is List) {
              products = productsResponse['data'] as List;
            }

            if (products.isNotEmpty) {

              // Buscar por nombre primero
              if (params.containsKey('product_name')) {
                final productName = (params['product_name'] as String).toLowerCase();
                final found = products.firstWhere(
                  (p) => (p['name'] as String).toLowerCase().contains(productName),
                  orElse: () => null,
                );
                if (found != null) {
                  productToUpdate = found['id'];
                }
              }

              // Si no encontró por nombre, buscar por código
              if (productToUpdate == null && params.containsKey('codigo')) {
                final codigo = params['codigo'] as String;
                final found = products.firstWhere(
                  (p) => p['codigo'] == codigo,
                  orElse: () => null,
                );
                if (found != null) {
                  productToUpdate = found['id'];
                }
              }
            }
          }

          if (productToUpdate == null) {
            return {
              'success': false,
              'error': 'No se pudo identificar el producto para el ajuste de stock',
            };
          }

          print('[DispatchAgent] → Ajustando stock del producto $productToUpdate...');
          final response = await ApiAgent.request(
            'PATCH',
            '/productos/$productToUpdate/stock',
            body: {
              'quantity': params['stock'],
              'type': 'set', // 'set' establece el stock exacto
            },
          );
          print('[DispatchAgent] Response: ${response.toString()}');
          return response.containsKey('error')
              ? response
              : {'success': true, ...response};
        }

        // Update normal de producto
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

      print('[DispatchAgent] 📦 Procesando COMPRA');
      print('[DispatchAgent] Action: $action');
      print('[DispatchAgent] Params: ${params.toString()}');

      if (action == 'create') {
        print('[DispatchAgent] → Creando compra con nombres de proveedor y productos...');
        final response = await ApiAgent.request(
          'POST',
          '/compras',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        print('[DispatchAgent] → Listando compras...');
        final response = await ApiAgent.request('GET', '/compras');
        print('[DispatchAgent] Response: ${response.toString()}');
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

      print('[DispatchAgent] 💰 Procesando VENTA');
      print('[DispatchAgent] Action: $action');
      print('[DispatchAgent] Params: ${params.toString()}');

      if (action == 'create') {
        print('[DispatchAgent] → Creando venta con nombres de cliente y productos...');
        final response = await ApiAgent.request(
          'POST',
          '/ventas',
          body: params,
        );
        print('[DispatchAgent] Response: ${response.toString()}');
        return response.containsKey('error')
            ? response
            : {'success': true, ...response};
      } else if (action == 'list') {
        print('[DispatchAgent] → Listando ventas...');
        final response = await ApiAgent.request('GET', '/ventas');
        print('[DispatchAgent] Response: ${response.toString()}');
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
