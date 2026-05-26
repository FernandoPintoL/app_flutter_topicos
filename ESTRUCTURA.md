# Estructura de la App Flutter

## 📁 Directorios Creados

```
D:\Topicos\app_flutter\lib\
├── main.dart                    (Punto de entrada)
│
├── models/
│   └── api_response.dart        (Modelo de respuesta API)
│
├── services/
│   └── api_client.dart          (Cliente HTTP - conecta con backend)
│
├── controllers/
│   └── home_controller.dart     (Lógica y estado de la pantalla)
│
└── screens/
    └── home_screen.dart         (UI principal)
```

## 📄 Archivos Modificados

- `pubspec.yaml` - Agregadas dependencias: `http`, `provider`

## 🎨 Componentes

### 1. **main.dart**
- Configuración de la app
- MaterialApp setup
- Sin bandera de debug

### 2. **models/api_response.dart**
- Clase `ApiResponse`
- Serialización JSON (fromJson, toJson)
- Propiedades: success, input, intent, entity_type, action, confidence, result, message, error

### 3. **services/api_client.dart**
- Clase `ApiClient` con métodos estáticos
- `processCommand(input, type)` - Envía comando al servidor
- `getStatus()` - Obtiene estado del sistema
- `login(username, password)` - Autentica usuario
- Base URL configurable: **http://192.168.100.24:8000**

### 4. **controllers/home_controller.dart**
- `HomeController extends ChangeNotifier`
- `TextEditingController` para el input
- Estados: isLoading, lastResponse, errorMessage
- Métodos:
  - `sendCommand(input)` - Procesa comando
  - `clearResponse()` - Limpia respuesta
  - `activateAudio()` - TODO: Implementar audio

### 5. **screens/home_screen.dart**
- Pantalla principal
- Layout:
  - **Input de Texto**: 3 líneas, borrable
  - **Botón Enviar**: Azul, deshabilitado mientras procesa
  - **Botón Audio**: Naranja, placeholder
  - **Error Messages**: Rojo si hay error
  - **JSON Display**: Terminal negra con texto verde, formato indentado

## 🔧 Configuración Necesaria

### IP del Servidor
Edita `lib/services/api_client.dart`:
```dart
static const String baseUrl = 'http://192.168.100.24:8000';
```

Obtén tu IP con:
```powershell
ipconfig | Select-String "IPv4"
```

### Android - HTTP Cleartext
Edita `android/app/src/main/AndroidManifest.xml`:
```xml
<application android:usesCleartextTraffic="true" ... >
```

## 🚀 Cómo Usar

### 1. Instalar dependencias
```bash
cd D:\Topicos\app_flutter
flutter pub get
```

### 2. Ejecutar app
```bash
flutter run
```

### 3. En la app:
1. Escribe: "Crea un cliente llamado Juan con cedula 12345678"
2. Presiona "Enviar"
3. Ver JSON de respuesta

## 📤 Flujo de Datos

```
Usuario escribe comando
        ↓
Presiona "Enviar"
        ↓
HomeController.sendCommand()
        ↓
ApiClient.processCommand()
        ↓
HTTP POST a http://192.168.100.24:8000/api/process
        ↓
Backend procesa (LLM + Dispatchers + API)
        ↓
Response JSON
        ↓
ApiResponse.fromJson()
        ↓
lastResponse actualizado
        ↓
UI redibuja con JSON
```

## 🎯 Estado Inicial

- **TextController**: Vacío
- **isLoading**: false
- **lastResponse**: null
- **errorMessage**: null
- **Pantalla**: Mostrar mensaje "Ingresa un comando y presiona Enviar"

## 📊 Ejemplo de Respuesta Mostrada

```json
{
  "success": true,
  "input": "Crea un cliente llamado Sofia con cedula 55555555",
  "type": "text",
  "intent": null,
  "entity_type": null,
  "action": null,
  "confidence": null,
  "result": {
    "id": 17,
    "name": "Sofia",
    "ci": "55555555",
    "phone": null,
    "created_at": "2026-05-13T23:07:04.261Z",
    "updated_at": "2026-05-13T23:07:04.261Z"
  },
  "message": "Operación completada exitosamente",
  "error": null
}
```

## ⚙️ Estado Management

- **Provider**: ChangeNotifier + Consumer
- **Single Source of Truth**: HomeController
- **Reactive UI**: Automáticamente se redibuja cuando cambian los valores

## 📝 Notas

- Timeout por defecto: 60 segundos
- Manejo de errores integrado
- JSON formateado con identación 2 espacios
- Colores personalizados para terminal (negro + verde)

---

**App Lista para Comenzar Desarrollo** ✅
