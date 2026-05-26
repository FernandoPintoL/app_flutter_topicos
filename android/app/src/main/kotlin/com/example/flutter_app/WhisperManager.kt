package com.example.flutter_app

import android.content.Context
import android.os.Environment
import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class WhisperManager(private val context: Context) {
  private var whisperId: Long = 0
  private var modelPath: String = ""
  private var isModelLoaded: Boolean = false

  companion object {
    private const val TAG = "WhisperManager"
    init {
      try {
        System.loadLibrary("llm")
        Log.d(TAG, "Librería nativa cargada")
      } catch (e: Exception) {
        Log.e(TAG, "Error cargando librería: ${e.message}")
      }
    }
  }

  fun getModelStatus(): Boolean = isModelLoaded
  fun getModelPath(): String = modelPath

  fun loadModel(path: String) {
    Log.d(TAG, "[WhisperManager] Intentando cargar modelo desde: $path")

    // Liberar modelo anterior si existe
    if (whisperId > 0) {
      whisperFree(whisperId)
      whisperId = 0
    }

    val file = File(path)
    if (!file.exists()) {
      Log.e(TAG, "[WhisperManager] ✗ Archivo no existe: $path")
      throw Exception("Archivo no existe: $path")
    }

    Log.d(TAG, "[WhisperManager] ✓ Archivo encontrado: ${file.absolutePath}")
    Log.d(TAG, "[WhisperManager] Tamaño: ${file.length()} bytes")

    try {
      Log.d(TAG, "[WhisperManager] Inicializando Whisper...")
      whisperId = whisperInit(file.absolutePath)

      if (whisperId <= 0) {
        Log.e(TAG, "[WhisperManager] ✗ Error: whisperInit retornó $whisperId")
        throw Exception("Error inicializando Whisper (handle=$whisperId)")
      }

      modelPath = path
      isModelLoaded = true
      Log.d(TAG, "[WhisperManager] ✅ Modelo cargado exitosamente")
      Log.d(TAG, "[WhisperManager] WhisperId: $whisperId")
    } catch (e: Exception) {
      Log.e(TAG, "[WhisperManager] ✗ Exception: ${e.message}")
      throw e
    }
  }

  suspend fun transcribe(audioPath: String): String = withContext(Dispatchers.IO) {
    Log.d(TAG, "[WhisperManager] Transcribiendo: $audioPath")

    if (whisperId <= 0) {
      Log.e(TAG, "[WhisperManager] ✗ Whisper no inicializado")
      throw Exception("Whisper no está inicializado")
    }

    val file = File(audioPath)
    if (!file.exists()) {
      Log.e(TAG, "[WhisperManager] ✗ Archivo de audio no existe: $audioPath")
      throw Exception("Archivo de audio no existe: $audioPath")
    }

    try {
      Log.d(TAG, "[WhisperManager] Leyendo WAV: $audioPath")
      val samples = readWav(audioPath)
      Log.d(TAG, "[WhisperManager] Muestras leídas: ${samples.size}")

      Log.d(TAG, "[WhisperManager] Iniciando inferencia...")
      val result = whisperInference(whisperId, samples)
      Log.d(TAG, "[WhisperManager] ✅ Transcripción: $result")

      return@withContext result
    } catch (e: Exception) {
      Log.e(TAG, "[WhisperManager] ✗ Error transcribiendo: ${e.message}")
      throw e
    }
  }

  private fun readWav(path: String): FloatArray {
    Log.d(TAG, "[WhisperManager] Parseando WAV...")
    val bytes = File(path).readBytes()

    if (bytes.size < 44) {
      throw Exception("Archivo WAV inválido: demasiado pequeño")
    }

    val samples = FloatArray((bytes.size - 44) / 2)
    for (i in samples.indices) {
      val low = bytes[44 + i * 2].toInt() and 0xff
      val high = bytes[44 + i * 2 + 1].toInt()
      val pcm = ((high shl 8) or low).toShort()
      samples[i] = pcm / 32768.0f
    }

    Log.d(TAG, "[WhisperManager] ✓ WAV parseado: ${samples.size} muestras")
    return samples
  }

  fun dispose() {
    if (whisperId > 0) {
      Log.d(TAG, "[WhisperManager] Liberando recursos...")
      whisperFree(whisperId)
      whisperId = 0
      isModelLoaded = false
      modelPath = ""
      Log.d(TAG, "[WhisperManager] ✓ Recursos liberados")
    }
  }
}
