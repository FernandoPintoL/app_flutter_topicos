# Flutter App - Sistema IA Gestión de Ventas

## 🎯 Resumen Rápido

App Flutter **minimalista** que conecta con tu API IA para procesar comandos de texto y mostrar respuestas JSON.

## ✨ Características

- ✅ Input de texto (3 líneas)
- ✅ Botón Enviar
- ✅ Botón Audio (placeholder)
- ✅ Mostrar respuesta JSON formateada
- ✅ State Management con Provider
- ✅ Manejo de errores

## 🚀 Instalación Rápida

### 1. Instalar dependencias
```bash
cd D:\Topicos\app_flutter
flutter pub get
```

### 2. Configurar IP
Edita `lib/services/api_client.dart`:
```dart
static const String baseUrl = 'http://192.168.100.24:8000';
```

Obtén tu IP:
```powershell
ipconfig | Select-String "IPv4"
```

### 3. Android - HTTP
Edita `android/app/src/main/AndroidManifest.xml`:
```xml
<application android:usesCleartextTraffic="true">
```

### 4. Ejecutar
```bash
flutter run
```

## 📝 Ejemplo de Uso

Ingresa: `Crea un cliente llamado Sofia con cedula 55555555`

Presiona: Enviar

Ver respuesta JSON en pantalla

## 📂 Estructura

```
lib/
├── main.dart
├── models/api_response.dart
├── services/api_client.dart
├── controllers/home_controller.dart
└── screens/home_screen.dart
```

## 📚 Documentación

- `SETUP.md` - Instalación detallada
- `ESTRUCTURA.md` - Explicación de archivos
- `COMANDOS_PRUEBA.md` - Comandos de ejemplo

---

**App lista para usar** ✅
