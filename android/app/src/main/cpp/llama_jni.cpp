#include <jni.h>
#include <string>
#include <android/log.h>
#include <map>
#include <memory>
#include <vector>
#include <cmath>
#include <algorithm>
#include <cstring>
#include <mutex>
#include <thread>
#include <atomic>
#include "llama.cpp/include/llama.h"
// Intentar incluir whisper si está disponible
#if __has_include("whisper.cpp/include/whisper.h")
#include "whisper.cpp/include/whisper.h"
#define HAS_WHISPER
#endif

#define LOG_TAG "native_jni"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

struct LlamaContext {
    llama_model* model;
    llama_context* ctx;
    std::mutex ctx_mutex;
};

#ifdef HAS_WHISPER
struct WhisperContext {
    struct whisper_context* ctx;
    std::mutex ctx_mutex;
};
static std::map<long, std::unique_ptr<WhisperContext>> whisper_contexts;
#endif

static std::map<long, std::unique_ptr<LlamaContext>> contexts;
static std::mutex contexts_mutex;
static long nextContextId = 1;
static long nextWhisperId = 1;

extern "C" {

// --- LLAMA METHODS (Ya existentes) ---

JNIEXPORT jlong JNICALL Java_com_example_flutter_1app_LLMModelKt_llamaInit(
    JNIEnv* env,
    jclass clazz,
    jstring modelPath,
    jint nCtx,
    jint nThreads) {

    const char* path = env->GetStringUTFChars(modelPath, nullptr);

    LOGI("[LLM] Iniciando llama con modelo: %s, nCtx: %d, nThreads: %d",
         path, nCtx, nThreads);

    try {
        auto context = std::make_unique<LlamaContext>();

        llama_backend_init();
        LOGI("[LLM] Backend de llama inicializado");

        llama_model_params model_params = llama_model_default_params();
        context->model = llama_model_load_from_file(path, model_params);

        if (!context->model) {
            LOGE("[LLM] Error: No se pudo cargar el modelo");
            throw std::runtime_error("No se pudo cargar el modelo");
        }

        llama_context_params ctx_params = llama_context_default_params();
        ctx_params.n_ctx = nCtx;
        ctx_params.n_threads = nThreads;
        ctx_params.n_threads_batch = nThreads;

        context->ctx = llama_init_from_model(context->model, ctx_params);

        if (!context->ctx) {
            llama_model_free(context->model);
            LOGE("[LLM] Error: No se pudo crear contexto");
            throw std::runtime_error("No se pudo crear el contexto");
        }

        long contextId = nextContextId++;
        {
            std::lock_guard<std::mutex> lock(contexts_mutex);
            contexts[contextId] = std::move(context);
        }

        LOGI("[LLM] Modelo cargado exitosamente con ID: %ld", contextId);
        env->ReleaseStringUTFChars(modelPath, path);
        return contextId;

    } catch (const std::exception& e) {
        LOGE("[LLM] Error: %s", e.what());
        env->ReleaseStringUTFChars(modelPath, path);
        return -1;
    }
}

JNIEXPORT jstring JNICALL Java_com_example_flutter_1app_LLMModelKt_llamaInference(
    JNIEnv* env,
    jclass clazz,
    jlong contextId,
    jstring prompt,
    jint maxTokens,
    jfloat temperature,
    jfloat topP,
    jint topK,
    jstring grammar) {

    const char* promptStr = env->GetStringUTFChars(prompt, nullptr);

    LOGI("[LLM] Inferencia iniciada con prompt: %s", promptStr);

    try {
        LlamaContext* context = nullptr;
        {
            std::lock_guard<std::mutex> lock(contexts_mutex);
            auto it = contexts.find(contextId);
            if (it == contexts.end()) {
                LOGE("[LLM] Error: Context ID no encontrado");
                env->ReleaseStringUTFChars(prompt, promptStr);
                return env->NewStringUTF("{\"error\":\"Context not found\"}");
            }
            context = it->second.get();
        }

        std::lock_guard<std::mutex> ctx_lock(context->ctx_mutex);

        const llama_model* model = context->model;
        struct llama_context* ctx = context->ctx;
        const llama_vocab* vocab = llama_model_get_vocab(model);

        // Tokenize input
        std::vector<llama_token> tokens_list;
        tokens_list.resize(8192);

        int n_tokens = llama_tokenize(vocab, promptStr, strlen(promptStr), tokens_list.data(), tokens_list.size(), true, false);
        if (n_tokens < 0) {
            LOGE("[LLM] Error: Tokenization failed");
            env->ReleaseStringUTFChars(prompt, promptStr);
            return env->NewStringUTF("{\"error\":\"Tokenization failed\"}");
        }

        tokens_list.resize(n_tokens);
        LOGI("[LLM] Tokenized to %d tokens", n_tokens);

        // Process prompt tokens
        auto batch = llama_batch_get_one(tokens_list.data(), n_tokens);
        if (llama_decode(ctx, batch)) {
            LOGE("[LLM] Error: Failed to decode prompt");
            env->ReleaseStringUTFChars(prompt, promptStr);
            return env->NewStringUTF("{\"error\":\"Decode failed\"}");
        }

        // Generate response tokens
        std::vector<llama_token> response_tokens;
        int n_generated = 0;
        int32_t n_vocab = llama_vocab_n_tokens(vocab);
        llama_token eos_token = llama_vocab_eos(vocab);

        while (n_generated < maxTokens) {
            // Get logits from last position
            float* logits = llama_get_logits(ctx);
            if (!logits) {
                LOGE("[LLM] Error: Could not get logits");
                break;
            }

            // Find token with highest logit (greedy sampling)
            float max_logit = logits[0];
            llama_token next_token = 0;
            for (int32_t i = 1; i < n_vocab; i++) {
                if (logits[i] > max_logit) {
                    max_logit = logits[i];
                    next_token = i;
                }
            }

            response_tokens.push_back(next_token);

            const char* token_str = llama_vocab_get_text(vocab, next_token);
            if (token_str) {
                LOGI("[LLM] Generated token %d: %s", next_token, token_str);
            }

            // Stop at EOS or if max tokens reached
            if (next_token == eos_token || n_generated >= maxTokens - 1) {
                break;
            }

            // Prepare batch for next iteration
            batch = llama_batch_get_one(&next_token, 1);
            if (llama_decode(ctx, batch)) {
                LOGE("[LLM] Error: Failed to decode token");
                break;
            }

            n_generated++;
        }

        // Detokenize response
        std::string response_text;
        for (auto token : response_tokens) {
            char buffer[128];
            int32_t piece_size = llama_token_to_piece(vocab, token, buffer, sizeof(buffer), 0, true);
            if (piece_size > 0) {
                response_text.append(buffer, piece_size);
            }
        }

        LOGI("[LLM] Respuesta generada: %s", response_text.c_str());

        env->ReleaseStringUTFChars(prompt, promptStr);
        return env->NewStringUTF(response_text.c_str());

    } catch (const std::exception& e) {
        LOGE("[LLM] Error: %s", e.what());
        env->ReleaseStringUTFChars(prompt, promptStr);
        return env->NewStringUTF("{\"error\":\"Inference failed\"}");
    }
}

JNIEXPORT void JNICALL Java_com_example_flutter_1app_LLMModelKt_llamaFree(
    JNIEnv* env,
    jclass clazz,
    jlong contextId) {

    {
        std::lock_guard<std::mutex> lock(contexts_mutex);
        auto it = contexts.find(contextId);
        if (it != contexts.end()) {
            LlamaContext* context = it->second.get();

            if (context->ctx) {
                llama_free(context->ctx);
            }

            if (context->model) {
                llama_model_free(context->model);
            }

            contexts.erase(it);
            LOGI("[LLM] Contexto liberado");
        }

        if (contexts.empty()) {
            llama_backend_free();
        }
    }
}

// --- WHISPER METHODS ---

JNIEXPORT jlong JNICALL Java_com_example_flutter_1app_LLMModelKt_whisperInit(
    JNIEnv* env,
    jclass clazz,
    jstring modelPath) {
#ifdef HAS_WHISPER
    const char* path = env->GetStringUTFChars(modelPath, nullptr);
    LOGI("[Whisper] Cargando modelo: %s", path);

    struct whisper_context_params params = whisper_context_default_params();
    struct whisper_context* ctx = whisper_init_from_file_with_params(path, params);

    env->ReleaseStringUTFChars(modelPath, path);

    if (!ctx) {
        LOGE("[Whisper] Error al cargar modelo");
        return -1;
    }

    long id = nextWhisperId++;
    {
        std::lock_guard<std::mutex> lock(contexts_mutex);
        auto w_ctx = std::make_unique<WhisperContext>();
        w_ctx->ctx = ctx;
        whisper_contexts[id] = std::move(w_ctx);
    }
    return id;
#else
    return -2; // Indicar que no está compilado con Whisper
#endif
}

JNIEXPORT jstring JNICALL Java_com_example_flutter_1app_LLMModelKt_whisperInference(
    JNIEnv* env,
    jclass clazz,
    jlong whisperId,
    jfloatArray samples) {
#ifdef HAS_WHISPER
    jfloat* audio_data = env->GetFloatArrayElements(samples, nullptr);
    jsize len = env->GetArrayLength(samples);

    WhisperContext* w_ctx = nullptr;
    {
        std::lock_guard<std::mutex> lock(contexts_mutex);
        if (whisper_contexts.count(whisperId)) w_ctx = whisper_contexts[whisperId].get();
    }

    if (!w_ctx) return env->NewStringUTF("Error: Contexto Whisper no encontrado");

    std::lock_guard<std::mutex> lock(w_ctx->ctx_mutex);

    whisper_full_params params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    params.language = "es"; // Forzar español para tu presentación
    params.print_progress = false;

    if (whisper_full(w_ctx->ctx, params, audio_data, len) != 0) {
        env->ReleaseFloatArrayElements(samples, audio_data, 0);
        return env->NewStringUTF("Error en transcripción");
    }

    std::string result = "";
    int n_segments = whisper_full_n_segments(w_ctx->ctx);
    for (int i = 0; i < n_segments; ++i) {
        result += whisper_full_get_segment_text(w_ctx->ctx, i);
    }

    env->ReleaseFloatArrayElements(samples, audio_data, 0);
    return env->NewStringUTF(result.c_str());
#else
    return env->NewStringUTF("Whisper no soportado en esta compilación");
#endif
}

} // extern "C"
