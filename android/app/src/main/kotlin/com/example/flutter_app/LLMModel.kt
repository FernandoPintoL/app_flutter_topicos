package com.example.flutter_app

import android.content.Context
import android.content.res.AssetManager
import android.os.Environment
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

// Declaraciones nativas
external fun llamaInit(modelPath: String, nCtx: Int, nThreads: Int): Long
external fun llamaInference(contextId: Long, prompt: String, maxTokens: Int, temperature: Float, topP: Float, topK: Int, grammar: String): String
external fun llamaFree(contextId: Long)

external fun whisperInit(modelPath: String): Long
external fun whisperInference(whisperId: Long, samples: FloatArray): String
external fun whisperFree(whisperId: Long)

class LLMModel(private val context: Context) {
  private var modelPath: String = ""
  private var isModelLoaded: Boolean = false
  private var contextId: Long = 0
  private var whisperId: Long = 0

  companion object {
    private const val TAG = "LLMModel"
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

  fun loadModel(path: String, nCtx: Int, nThreads: Int) {
    this.modelPath = path
    // Aquí iría tu lógica de búsqueda de archivo que ya tenías...
    // Simplificado para este ejemplo:
    val file = File(path)
    if (file.exists()) {
        contextId = llamaInit(file.absolutePath, nCtx, nThreads)
        isModelLoaded = contextId > 0
    }
  }

  suspend fun inference(prompt: String, maxTokens: Int, temp: Double, topP: Double, topK: Int, grammar: String): String = withContext(Dispatchers.Default) {
    if (contextId <= 0) throw Exception("LLM no cargado")
    llamaInference(contextId, prompt, maxTokens, temp.toFloat(), topP.toFloat(), topK, grammar)
  }

  suspend fun sttInference(audioPath: String): String = withContext(Dispatchers.IO) {
    if (whisperId <= 0) {
      val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
      val wFile = File(downloadsDir, "ggml-tiny.bin")
      if (!wFile.exists()) throw Exception("No se encontró ggml-tiny.bin en Descargas")
      whisperId = whisperInit(wFile.absolutePath)
      if (whisperId <= 0) throw Exception("Error al inicializar Whisper ($whisperId)")
    }

    val samples = readWav(audioPath)
    whisperInference(whisperId, samples)
  }

  private fun readWav(path: String): FloatArray {
    val bytes = File(path).readBytes()
    val samples = FloatArray((bytes.size - 44) / 2)
    for (i in samples.indices) {
      val low = bytes[44 + i * 2].toInt() and 0xff
      val high = bytes[44 + i * 2 + 1].toInt()
      val pcm = ((high shl 8) or low).toShort()
      samples[i] = pcm / 32768.0f
    }
    return samples
  }

  fun dispose() {
    if (contextId > 0) llamaFree(contextId)
  }
}
