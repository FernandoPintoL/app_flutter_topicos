# Pruebas - Selector Manual de Modelo

## Cambios implementados

1. **file_picker** - Añadido a pubspec.yaml para permitir seleccionar archivos
2. **ModelLoaderWidget** - Nuevo widget en `lib/widgets/model_loader_widget.dart` que permite:
   - Seleccionar un archivo .gguf desde el dispositivo
   - Mostrar estado de carga
   - Mostrar errores de forma clara

3. **LLMService** - Modificado para soportar rutas absolutas
4. **LLMModel.kt** - Mejorado para detectar y usar rutas absolutas

## Pasos para compilar y probar

### 1. Obtener dependencias
```powershell
cd D:\Topicos\app_flutter
flutter pub get
```

### 2. Compilar la app
```powershell
flutter build apk --release
# O para debug:
flutter run
```

### 3. Instalar en el dispositivo
```powershell
adb install build/app/outputs/flutter-app-release.apk
```

O si usas Flutter:
```powershell
flutter install
```

### 4. Probar el selector de modelo

**En la app:**
1. Abre la app
2. Verás un nuevo widget "Selecciona un modelo GGUF" en la parte superior
3. Presiona "Seleccionar modelo"
4. Elige el archivo .gguf desde tu dispositivo (por ejemplo, `/sdcard/Download/qwen2.5-3b-instruct-q4_k_m.gguf`)
5. Espera a que cargue

**Los logs dirán:**
```
D/LLMModel: Usando ruta absoluta: /sdcard/Download/qwen2.5-3b-instruct-q4_k_m.gguf
D/LLMModel: Tamaño: 1873902011 bytes
I/llama_jni: [LLM] Iniciando llama con modelo: /sdcard/Download/...
```

## Flujo esperado

```
1. Usuario abre app
   ↓
2. Widget muestra "Selecciona un modelo GGUF"
   ↓
3. Usuario presiona "Seleccionar modelo"
   ↓
4. Se abre el file picker
   ↓
5. Usuario selecciona archivo .gguf
   ↓
6. App muestra "Cargando..." (con progress bar)
   ↓
7. Si carga OK:
   - Widget verde con ✓
   - Muestra nombre del archivo
   - Botón deshabilitado
   ↓
8. Si falla:
   - Mensaje de error rojo
   - Botón disponible para intentar nuevamente
```

## Diagnosticar si aún falla

Si llama.cpp sigue sin cargar el modelo:

1. **Verifica los logs:**
```powershell
adb logcat -s "llama_jni" -v threadtime
```

2. **Posibles problemas:**
   - ❌ Archivo corrupto → descárgalo nuevamente
   - ❌ Modelo incompatible → prueba con qwen2.5-0.5b (más pequeño)
   - ❌ Versión de llama.cpp vieja → actualiza el NDK

3. **Copia el archivo correctamente:**
```powershell
# Descarga desde tu PC
# Copia a descargas del celular
adb push "C:\ruta\modelo.gguf" /sdcard/Download/

# Verifica que existe
adb shell ls -lah /sdcard/Download/modelo.gguf
```

## Si todo funciona

¡Listo! Ya puedes usar la app. El usuario puede seleccionar cualquier modelo .gguf desde su dispositivo sin necesidad de rutas fijas.
