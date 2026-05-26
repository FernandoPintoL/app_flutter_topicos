# 🎤 Integración de Whisper STT (Speech-to-Text)

## 1. Descargar el Modelo Whisper

### 📌 Aclaración: Formatos de Archivo

- **Qwen (LLM):** `.gguf` (GGUF format - usado por llama.cpp)
- **Whisper (STT):** `.bin` (GGML format - usado por whisper.cpp)

Son **diferentes formatos** porque cada herramienta tiene su propio formato de cuantización.

### Opciones de Descarga (elegir UNA):

**Opción A: Tiny (39 MB - MÁS RÁPIDO, recomendado para pruebas)**
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin
```

**Opción B: Base (142 MB - BUEN BALANCE)**
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```

**Opción C: Small (466 MB - MÁS PRECISO)**
```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin
```

Una vez descargado, guarda el archivo `.bin` en una ubicación accesible.

---

## 2. Archivos Creados

✅ **Ya hemos creado:**
- `lib/services/whisper_service.dart` - Servicio para cargar y usar Whisper
- `lib/widgets/whisper_loader_widget.dart` - Widget para seleccionar modelo
- `lib/widgets/whisper_status_indicator.dart` - Indicador de estado

---

## 3. Modificar `CommandContainer` para Integrar Whisper

Abre `lib/react/containers/command_container.dart` y realiza estos cambios:

### 3.1 Importar WhisperService

En la sección de imports (línea ~5), agrega:
```dart
import '../../services/whisper_service.dart';
```

### 3.2 Agregar instancia de WhisperService

Después de la línea `final AudioService _audioService = AudioService();` agrega:
```dart
final WhisperService _whisperService = WhisperService.getInstance();
```

### 3.3 Agregar método para transcribir audio

Agrega este método después del método `stopRecording`:

```dart
Future<void> stopRecording(BuildContext context) async {
  isRecording = false;
  notifyListeners();
  
  final path = await _audioService.stopRecording();
  if (path != null) {
    // NUEVO: Transcribir con Whisper si está cargado
    if (_whisperService.isModelLoaded()) {
      try {
        print('[CommandContainer] 🎤 Transcribiendo audio con Whisper...');
        final transcribedText = await _whisperService.transcribeAudio(path);
        
        if (transcribedText != null && transcribedText.isNotEmpty) {
          print('[CommandContainer] ✅ Transcripción: $transcribedText');
          // Usar el texto transcrito en lugar del archivo de audio
          textController.text = transcribedText;
          await sendTextCommand(transcribedText, context: context);
          return;
        }
      } catch (e) {
        print('[CommandContainer] ⚠️ Error transcribiendo: $e');
        // Si falla Whisper, continuar con audio normal
      }
    }
    
    // Fallback: procesar como audio si Whisper no está disponible
    await sendAudioCommand(path, context: context);
  }
}
```

---

## 4. Modificar `home_screen.dart` para Agregar Whisper Loader

Abre `lib/screens/home_screen.dart` y realiza estos cambios:

### 4.1 Importar WhisperLoaderWidget

En la sección de imports, agrega:
```dart
import '../widgets/whisper_loader_widget.dart';
import '../widgets/whisper_status_indicator.dart';
```

### 4.2 Agregar Whisper Loader en la UI

Dentro del `Column` de la pantalla (después de `ModelLoaderWidget`, ~línea 73), agrega:

```dart
const SizedBox(height: 16),

// Selector de modelo Whisper
WhisperLoaderWidget(
  onModelLoaded: () {
    print('[HomeScreen] Whisper cargado');
  },
),
const SizedBox(height: 16),

// Estado de Whisper
const WhisperStatusIndicator(),
```

El resultado debería verse así:

```dart
// Selector de modelo (Qwen)
ModelLoaderWidget(
  onModelLoaded: () {
    print('[HomeScreen] Modelo cargado, actualizando estado');
    Future.delayed(const Duration(milliseconds: 500), () {
      if (context.mounted) {
        context.read<CommandContainer>().updateModelStatus();
      }
    });
  },
),
const SizedBox(height: 16),

// Estado del modelo (Qwen)
const ModelStatusIndicator(),
const SizedBox(height: 16),

// Selector de modelo Whisper (NUEVO)
WhisperLoaderWidget(
  onModelLoaded: () {
    print('[HomeScreen] Whisper cargado');
  },
),
const SizedBox(height: 16),

// Estado de Whisper (NUEVO)
const WhisperStatusIndicator(),
const SizedBox(height: 16),

// Título
const Text(
  'Ingresa un comando:',
  ...
```

---

## 5. Implementar en Código Nativo (Kotlin)

Para que Whisper funcione realmente, necesitas agregar código nativo en Kotlin.

### 5.1 Crear archivo: `android/app/src/main/kotlin/com/example/flutter_app/WhisperManager.kt`

```kotlin
package com.example.flutter_app

import android.content.Context
import java.io.File

class WhisperManager(private val context: Context) {
    private var whisperContextHandle: Long = 0
    
    companion object {
        init {
            System.loadLibrary("whisper")
        }
    }

    external fun initWhisper(modelPath: String): Long
    external fun transcribeAudio(contextHandle: Long, audioPath: String): String
    external fun freeWhisper(contextHandle: Long)

    fun loadModel(modelPath: String) {
        if (whisperContextHandle != 0L) {
            freeWhisper(whisperContextHandle)
        }
        whisperContextHandle = initWhisper(modelPath)
    }

    fun transcribe(audioPath: String): String? {
        return if (whisperContextHandle != 0L) {
            transcribeAudio(whisperContextHandle, audioPath)
        } else {
            null
        }
    }

    fun release() {
        if (whisperContextHandle != 0L) {
            freeWhisper(whisperContextHandle)
            whisperContextHandle = 0
        }
    }
}
```

### 5.2 Modificar `MainActivity.kt`

Agrega estos métodos al MethodChannel:

```kotlin
// En el bloque de MethodChannel (después de "loadModel")
"loadWhisperModel" -> {
    val modelPath = call.argument<String>("modelPath")
    if (modelPath != null) {
        whisperManager?.loadModel(modelPath)
        result.success("Whisper model loaded")
    } else {
        result.error("INVALID", "Model path is null", null)
    }
}

"transcribeAudio" -> {
    val audioPath = call.argument<String>("audioPath")
    if (audioPath != null && whisperManager != null) {
        val text = whisperManager!!.transcribe(audioPath)
        result.success(text)
    } else {
        result.error("INVALID", "Audio path is null or Whisper not loaded", null)
    }
}
```

Agrega la instancia en la clase:
```kotlin
private var whisperManager: WhisperManager? = null

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    whisperManager = WhisperManager(this)
    // ... resto del código
}
```

---

## 6. Compilar NDK con Whisper

Si aún no tienes compilado whisper.cpp:

```bash
# Descargar y compilar whisper.cpp
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp

# Compilar para Android NDK
./build-android.sh

# Los .so se generarán en libs/
```

Copia los archivos `.so` (libwhisper.so) a:
```
android/app/src/main/jniLibs/armeabi-v7a/
android/app/src/main/jniLibs/arm64-v8a/
```

---

## 7. Flujo de Uso

### Desde la UI:

1. **Cargar Qwen** → Click en "Seleccionar modelo" (ModelLoaderWidget)
2. **Cargar Whisper** → Click en "Seleccionar Whisper" (WhisperLoaderWidget)
3. **Grabar Audio** → Click en botón "Audio"
4. **Detener** → Click en "Detener"
5. ✨ **Automático**: Whisper transcribe → Qwen procesa → Resultado

### Diagrama de Flujo:

```
[Grabar Audio] 
    ↓
[Detener Recording]
    ↓
[Whisper transcribe] ← Aquí ocurre la magia STT
    ↓
[CommandContainer.stopRecording() obtiene texto]
    ↓
[sendTextCommand()] ← Envía texto a Qwen
    ↓
[LLMAgent.infer()]
    ↓
[DispatchAgent.dispatch()]
    ↓
[Respuesta JSON en pantalla]
```

---

## 8. Testing

### Primero (sin compilar NDK):

1. Carga los modelos desde la UI
2. Intenta transcribir
3. Si da error de MethodChannel, significa que falta código nativo

### Después (con NDK):

1. La transcripción debería funcionar automáticamente
2. El texto aparecerá en el TextController
3. Qwen procesará el comando

---

## 📝 Checklist

- [ ] Descargar modelo Whisper (.bin)
- [ ] Modificar `CommandContainer.stopRecording()`
- [ ] Modificar `home_screen.dart` para agregar widgets
- [ ] Crear `WhisperManager.kt`
- [ ] Modificar `MainActivity.kt`
- [ ] Compilar whisper.cpp para NDK
- [ ] Copiar .so a jniLibs
- [ ] Probar carga de modelo desde UI
- [ ] Probar grabación y transcripción
- [ ] Verificar que Qwen reciba el texto transcrito

---

## ⚠️ Posibles Errores

**Error: "loadWhisperModel" not found**
→ Falta implementar el método en MainActivity.kt

**Error: Modelo no carga**
→ Verifica que la ruta sea absoluta y el archivo sea .bin válido

**Error: Audio no se transcribe**
→ Falta compilar whisper.cpp o no está en jniLibs

---

## 📚 Referencias

- Whisper.cpp: https://github.com/ggerganov/whisper.cpp
- Modelos: https://huggingface.co/ggerganov/whisper.cpp
- Android NDK: https://developer.android.com/ndk

