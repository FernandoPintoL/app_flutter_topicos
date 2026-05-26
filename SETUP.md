# Setup - Flutter App

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── models/
│   └── api_response.dart     # Modelo de respuesta
├── services/
│   └── api_client.dart       # Cliente HTTP
├── controllers/
│   └── home_controller.dart  # Lógica de pantalla
└── screens/
    └── home_screen.dart      # UI principal
```

## Configuración Previa

### 1. Instalar Dependencias

```bash
flutter pub get
```

### 2. Configurar IP del Servidor

Edita `lib/services/api_client.dart` y actualiza la IP:

```dart
static const String baseUrl = 'http://192.168.100.24:8000';
// Reemplaza 192.168.100.24 con la IP de tu máquina Windows
```

Para encontrar tu IP Windows:
```powershell
ipconfig | Select-String "IPv4"
```

### 3. Android - Permitir HTTP (Desarrollo)

Edita `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ...
>
```

### 4. Ejecutar la App

```bash
flutter run
```

O en un emulador específico:
```bash
flutter run -d emulator-5554
```

## Funcionalidades Actuales

✅ **Input de Texto** - Ingresa comandos naturales  
✅ **Botón Enviar** - Procesa el comando a través de API  
✅ **Botón Audio** - Placeholder (implementar después)  
✅ **Vista JSON** - Muestra la respuesta completa formateada  

## Ejemplo de Uso

1. Inicia el servidor Python en Windows:
   ```bash
   python api_server.py
   ```

2. Abre la app Flutter

3. Ingresa un comando:
   - "Crea un cliente llamado Juan con cedula 12345678"
   - "Muéstrame todos los clientes"
   - "Lista de productos"

4. Presiona "Enviar"

5. Ver respuesta JSON en la pantalla

## Comandos Soportados

Ver `INTENTS_REFERENCE.md` en la carpeta del backend para lista completa:
- Crear clientes
- Listar clientes
- Crear usuarios
- Listar usuarios
- Crear productos
- Crear ventas
- Y más...

## Próximas Mejoras

- [ ] Implementar grabación de audio
- [ ] Agregar autenticación (login)
- [ ] Mejorar UI/UX
- [ ] Agregar historial de comandos
- [ ] Implementar caché de datos
- [ ] Agregar notificaciones

## Solución de Problemas

### "Connection refused"
- Verifica que `api_server.py` esté corriendo
- Actualiza la IP en `api_client.dart`

### "Timeout"
- Aumenta el timeout en `ApiClient.processCommand()` a 90 segundos
- Verifica que el LLM no esté sobrecargado

### "HTTP 400"
- Verifica el formato del comando
- Usa caracteres simples (sin acentos especiales)

---

**App Lista para Desarrollo** ✅
