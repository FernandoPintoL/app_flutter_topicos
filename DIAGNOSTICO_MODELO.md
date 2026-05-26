# Diagnóstico: Modelo GGUF no carga

## El problema
El archivo `qwen2.5-3b-instruct-q4_k_m.gguf` se encuentra correctamente pero `llama_model_load_from_file()` retorna `nullptr`.

## Pasos de diagnóstico

### 1. Verifica que el archivo esté completo y no corrupto
```bash
# En tu PC, calcula el hash MD5/SHA256 del modelo
certutil -hashfile "D:\Topicos\app_flutter\assets\models\qwen2.5-3b-instruct-q4_k_m.gguf" SHA256

# En el dispositivo Android, verifica con adb
adb shell ls -lah /sdcard/Download/qwen2.5-3b-instruct-q4_k_m.gguf

# El tamaño debe ser el mismo en ambos lados
```

### 2. Comprueba la versión de llama.cpp
El modelo podría ser incompatible con la versión de llama.cpp en tu NDK.
- Busca en `android/app/src/main/cpp/` qué versión está compilada
- Qwen 2.5 funciona con versiones recientes de llama.cpp (2024+)
- Si tu versión es de 2023, necesitas actualizar

### 3. Verifica los logs en tiempo real
```bash
adb logcat -s "llama_jni" -v threadtime
# Reinstala la app y busca más detalles del error
```

### 4. Descarga el modelo nuevamente
El archivo podría estar corrupto:
```bash
# Descarga desde Hugging Face con mejor método
# O copia directamente con adb:
adb push "path_local_del_modelo" /sdcard/Download/
```

### 5. Prueba con un modelo más pequeño primero
Usa `qwen2.5-0.5b` o similar para verificar que llama.cpp funciona en general.

## Soluciones probables

### Opción A: Usar modelo en carpeta de datos de la app
En lugar de `/sdcard/Download/`, guarda en:
```
/data/data/com.example.flutter_app/files/
```
Esto evita problemas de permisos. Modifica `LLMModel.kt`:
```kotlin
val appCacheDir = File(context.cacheDir, "models")
appCacheDir.mkdirs()
```

### Opción B: Descargar automáticamente en la app
Descarga el modelo desde internet (Hugging Face) dentro de la app en lugar de copiarlo manualmente.

### Opción C: Incrustar en APK (si cabe)
Si el modelo cabe en el APK (~500MB se puede), colócalo en `assets/` y déjalo copiar a `context.filesDir`.
