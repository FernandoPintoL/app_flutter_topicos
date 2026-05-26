package com.example.flutter_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
  private val CHANNEL = "com.example.flutter_app/llm"
  private val WHISPER_CHANNEL = "com.example.flutter_app/whisper"
  private var llmModel: LLMModel? = null
  private var whisperManager: WhisperManager? = null
  private val TAG = "MainActivity"
  private val PERMISSION_REQUEST_CODE = 100

  override fun onCreate(savedInstanceState: android.os.Bundle?) {
    super.onCreate(savedInstanceState)
    Log.d(TAG, "MainActivity creada - esperando que usuario seleccione modelo")
    whisperManager = WhisperManager(this)
    Log.d(TAG, "WhisperManager inicializado")
    requestStoragePermissions()
  }

  private fun requestStoragePermissions() {
    val permissionsNeeded = mutableListOf<String>()

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      // Android 13+: permisos específicos por tipo de media
      if (ContextCompat.checkSelfPermission(
          this,
          Manifest.permission.READ_MEDIA_IMAGES
        ) != PackageManager.PERMISSION_GRANTED
      ) {
        permissionsNeeded.add(Manifest.permission.READ_MEDIA_IMAGES)
      }
      if (ContextCompat.checkSelfPermission(
          this,
          Manifest.permission.READ_MEDIA_AUDIO
        ) != PackageManager.PERMISSION_GRANTED
      ) {
        permissionsNeeded.add(Manifest.permission.READ_MEDIA_AUDIO)
      }
      if (ContextCompat.checkSelfPermission(
          this,
          Manifest.permission.RECORD_AUDIO
        ) != PackageManager.PERMISSION_GRANTED
      ) {
        permissionsNeeded.add(Manifest.permission.RECORD_AUDIO)
      }
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      // Android 11+: MANAGE_EXTERNAL_STORAGE
      if (ContextCompat.checkSelfPermission(
          this,
          Manifest.permission.MANAGE_EXTERNAL_STORAGE
        ) != PackageManager.PERMISSION_GRANTED
      ) {
        permissionsNeeded.add(Manifest.permission.MANAGE_EXTERNAL_STORAGE)
      }
    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      // Android 6+: permisos legacy
      if (ContextCompat.checkSelfPermission(
          this,
          Manifest.permission.READ_EXTERNAL_STORAGE
        ) != PackageManager.PERMISSION_GRANTED
      ) {
        permissionsNeeded.add(Manifest.permission.READ_EXTERNAL_STORAGE)
      }
      if (ContextCompat.checkSelfPermission(
          this,
          Manifest.permission.WRITE_EXTERNAL_STORAGE
        ) != PackageManager.PERMISSION_GRANTED
      ) {
        permissionsNeeded.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
      }
    }

    if (permissionsNeeded.isEmpty()) {
      Log.d(TAG, "Permisos ya otorgados")
    } else {
      Log.d(TAG, "Pidiendo permisos: ${permissionsNeeded.joinToString(", ")}")
      ActivityCompat.requestPermissions(
        this,
        permissionsNeeded.toTypedArray(),
        PERMISSION_REQUEST_CODE
      )
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<String>,
    grantResults: IntArray
  ) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode == PERMISSION_REQUEST_CODE) {
      val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
      if (allGranted) {
        Log.d(TAG, "✓ Permisos otorgados")
      } else {
        Log.e(TAG, "✗ Algunos permisos fueron denegados")
      }
    }
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "loadModel" -> {
            try {
              val modelPath = call.argument<String>("modelPath") ?: ""
              val nCtx = call.argument<Int>("nCtx") ?: 2048
              val nThreads = call.argument<Int>("nThreads") ?: 4

              if (llmModel == null) {
                llmModel = LLMModel(this)
              }
              llmModel!!.loadModel(modelPath, nCtx, nThreads)

              result.success("Modelo cargado exitosamente")
            } catch (e: Exception) {
              result.error("LOAD_ERROR", e.message, null)
            }
          }

          "inference" -> {
            val prompt = call.argument<String>("prompt") ?: ""
            val maxTokens = call.argument<Int>("maxTokens") ?: 256
            val temperature = call.argument<Double>("temperature") ?: 0.1
            val topP = call.argument<Double>("topP") ?: 0.95
            val topK = call.argument<Int>("topK") ?: 40
            val grammar = call.argument<String>("grammar") ?: ""

            if (llmModel == null) {
              result.error("INFERENCE_ERROR", "Modelo no inicializado", null)
              return@setMethodCallHandler
            }

            CoroutineScope(Dispatchers.Main).launch {
              try {
                val response = llmModel!!.inference(
                  prompt,
                  maxTokens,
                  temperature,
                  topP,
                  topK,
                  grammar
                )
                result.success(response)
              } catch (e: Exception) {
                Log.e(TAG, "Error en inferencia: ${e.message}", e)
                result.error("INFERENCE_ERROR", e.message, null)
              }
            }
          }

          "sttInference" -> {
            val audioPath = call.argument<String>("audioPath") ?: ""
            Log.d(TAG, "STT solicitado para: $audioPath")
            
            if (llmModel == null) {
              llmModel = LLMModel(this)
            }

            CoroutineScope(Dispatchers.Main).launch {
              try {
                val transcription = llmModel!!.sttInference(audioPath)
                result.success(transcription)
              } catch (e: Exception) {
                Log.e(TAG, "Error en STT: ${e.message}", e)
                result.error("STT_ERROR", e.message, null)
              }
            }
          }

          "dispose" -> {
            try {
              if (llmModel != null) {
                llmModel!!.dispose()
              }
              result.success("Recursos liberados")
            } catch (e: Exception) {
              result.error("DISPOSE_ERROR", e.message, null)
            }
          }

          "getModelStatus" -> {
            try {
              val isLoaded = llmModel?.getModelStatus() ?: false
              val modelPath = llmModel?.getModelPath() ?: ""
              result.success(mapOf(
                "isLoaded" to isLoaded,
                "modelPath" to modelPath
              ))
            } catch (e: Exception) {
              result.error("STATUS_ERROR", e.message, null)
            }
          }

          else -> result.notImplemented()
        }
      }

    // MethodChannel para Whisper
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WHISPER_CHANNEL)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "loadWhisperModel" -> {
            try {
              val modelPath = call.argument<String>("modelPath") ?: ""
              Log.d(TAG, "[Whisper] Cargando modelo desde: $modelPath")

              if (whisperManager == null) {
                whisperManager = WhisperManager(this)
              }

              whisperManager!!.loadModel(modelPath)
              result.success("Whisper model loaded successfully")
              Log.d(TAG, "[Whisper] ✅ Modelo cargado")
            } catch (e: Exception) {
              Log.e(TAG, "[Whisper] ✗ Error cargando: ${e.message}")
              result.error("LOAD_ERROR", e.message, null)
            }
          }

          "transcribeAudio" -> {
            val audioPath = call.argument<String>("audioPath") ?: ""
            Log.d(TAG, "[Whisper] Transcribiendo: $audioPath")

            if (whisperManager == null) {
              result.error("NOT_LOADED", "WhisperManager no inicializado", null)
              return@setMethodCallHandler
            }

            CoroutineScope(Dispatchers.Main).launch {
              try {
                val transcription = whisperManager!!.transcribe(audioPath)
                Log.d(TAG, "[Whisper] ✅ Transcripción completada: $transcription")
                result.success(transcription)
              } catch (e: Exception) {
                Log.e(TAG, "[Whisper] ✗ Error transcribiendo: ${e.message}")
                result.error("TRANSCRIBE_ERROR", e.message, null)
              }
            }
          }

          "disposeWhisper" -> {
            try {
              if (whisperManager != null) {
                whisperManager!!.dispose()
                Log.d(TAG, "[Whisper] ✓ Recursos liberados")
              }
              result.success("Whisper disposed")
            } catch (e: Exception) {
              result.error("DISPOSE_ERROR", e.message, null)
            }
          }

          else -> result.notImplemented()
        }
      }
  }
}
