package com.curator.curator_mobile

import android.content.Context
import android.os.SystemClock
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.text.textembedder.TextEmbedder
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class LiteRtLlmBridgeHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private var llmModelPath: String? = null
    private var embedderModelPath: String? = null
    private var llmInference: LlmInference? = null
    private var textEmbedder: TextEmbedder? = null
    private var lastErrorMessage: String? = null
    private var lastPrepareDurationMs: Long? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> {
                llmModelPath = call.argument<String>("llmModelPath")
                embedderModelPath = call.argument<String>("embedderModelPath")
                prepareRuntime(result)
            }
            "status" -> result.success(buildStatus())
            "generate" -> handleGenerate(call, result)
            "embed" -> handleEmbed(call, result)
            else -> result.notImplemented()
        }
    }

    private fun prepareRuntime(result: MethodChannel.Result) {
        val startedAt = SystemClock.elapsedRealtime()
        val errors = mutableListOf<String>()

        llmInference = initializeLlm(llmModelPath, errors)
        textEmbedder = initializeEmbedder(embedderModelPath, errors)

        lastPrepareDurationMs = SystemClock.elapsedRealtime() - startedAt
        lastErrorMessage = errors.firstOrNull()
        result.success(buildStatus())
    }

    private fun handleGenerate(call: MethodCall, result: MethodChannel.Result) {
        val prompt = call.argument<String>("prompt")
        if (prompt.isNullOrBlank()) {
            result.error("invalid_prompt", "프롬프트가 비어 있습니다.", null)
            return
        }

        try {
            val inference = llmInference ?: initializeLlm(llmModelPath)
            if (inference == null) {
                lastErrorMessage = "LLM 모델 경로가 없거나 파일을 찾을 수 없습니다."
                result.error("llm_unavailable", "LiteRT LLM 모델 경로가 준비되지 않았습니다.", null)
                return
            }

            val response = inference.generateResponse(prompt)
            lastErrorMessage = null
            result.success(response)
        } catch (error: Exception) {
            lastErrorMessage = error.message
            result.error("generate_failed", error.message, null)
        }
    }

    private fun handleEmbed(call: MethodCall, result: MethodChannel.Result) {
        val text = call.argument<String>("text")
        if (text.isNullOrBlank()) {
            result.error("invalid_text", "임베딩할 텍스트가 비어 있습니다.", null)
            return
        }

        try {
            val embedder = textEmbedder ?: initializeEmbedder(embedderModelPath)
            if (embedder == null) {
                lastErrorMessage = "임베더 모델 경로가 없거나 파일을 찾을 수 없습니다."
                result.error("embedder_unavailable", "텍스트 임베딩 모델 경로가 준비되지 않았습니다.", null)
                return
            }

            val embedding = embedder.embed(text)
                .embeddings()
                .firstOrNull()
                ?.floatEmbedding()
                ?.map { value -> value.toDouble() }
                ?: emptyList()

            lastErrorMessage = null
            result.success(embedding)
        } catch (error: Exception) {
            lastErrorMessage = error.message
            result.error("embed_failed", error.message, null)
        }
    }

    private fun initializeLlm(
        modelPath: String?,
        errors: MutableList<String> = mutableListOf(),
    ): LlmInference? {
        if (modelPath.isNullOrBlank()) {
            return null
        }
        if (!File(modelPath).exists()) {
            errors.add("LLM 모델 파일을 찾지 못했습니다.")
            return null
        }

        return llmInference ?: run {
            try {
                val options = LlmInference.LlmInferenceOptions.builder()
                    .setModelPath(modelPath)
                    .setMaxTokens(512)
                    .setTopK(32)
                    .setTemperature(0.3f)
                    .setRandomSeed(17)
                    .build()
                LlmInference.createFromOptions(context, options)
            } catch (error: Exception) {
                errors.add(error.message ?: "LLM 초기화에 실패했습니다.")
                null
            }
        }
    }

    private fun initializeEmbedder(
        modelPath: String?,
        errors: MutableList<String> = mutableListOf(),
    ): TextEmbedder? {
        if (modelPath.isNullOrBlank()) {
            return null
        }
        if (!File(modelPath).exists()) {
            errors.add("임베더 모델 파일을 찾지 못했습니다.")
            return null
        }

        return textEmbedder ?: run {
            try {
                val baseOptions = BaseOptions.builder()
                    .setModelAssetPath(modelPath)
                    .build()
                val options = TextEmbedder.TextEmbedderOptions.builder()
                    .setBaseOptions(baseOptions)
                    .build()
                TextEmbedder.createFromOptions(context, options)
            } catch (error: Exception) {
                errors.add(error.message ?: "임베더 초기화에 실패했습니다.")
                null
            }
        }
    }

    private fun buildStatus(): Map<String, Any> {
        val llmPath = llmModelPath
        val embedPath = embedderModelPath
        val llmConfigured = !llmPath.isNullOrBlank()
        val embedConfigured = !embedPath.isNullOrBlank()
        val llmAvailable = llmConfigured && File(llmPath!!).exists()
        val embedAvailable = embedConfigured && File(embedPath!!).exists()
        val llmReady = llmInference != null && llmAvailable
        val embedderReady = textEmbedder != null && embedAvailable
        val fallbackActive = !llmReady || !embedderReady
        val runtime = when {
            llmReady && embedderReady -> "native-ready"
            lastErrorMessage != null -> "native-error"
            llmReady || embedderReady -> "native-partial"
            else -> "template-fallback"
        }

        val message = when {
            llmReady && embedderReady -> "LiteRT LLM 및 텍스트 임베더가 준비되었습니다."
            llmConfigured && !llmAvailable -> "LLM 모델 경로가 설정되었지만 파일을 찾지 못해 템플릿 폴백을 사용합니다."
            embedConfigured && !embedAvailable -> "임베더 모델 경로가 설정되었지만 파일을 찾지 못해 해시 임베딩 폴백을 사용합니다."
            llmReady -> "LLM은 네이티브지만 임베더가 준비되지 않아 검색은 폴백 경로를 사용합니다."
            embedderReady -> "임베더는 네이티브지만 LLM이 준비되지 않아 응답은 템플릿 폴백으로 생성합니다."
            lastErrorMessage != null -> "네이티브 초기화에 실패해 온디바이스 폴백을 사용합니다."
            else -> "모델 경로가 없어 Dart 로컬 폴백을 사용합니다."
        }

        return mapOf(
            "llmReady" to llmReady,
            "embedderReady" to embedderReady,
            "runtime" to runtime,
            "message" to message,
            "platform" to "android",
            "llmModelConfigured" to llmConfigured,
            "embedderModelConfigured" to embedConfigured,
            "llmModelAvailable" to llmAvailable,
            "embedderModelAvailable" to embedAvailable,
            "fallbackActive" to fallbackActive,
            "lastError" to lastErrorMessage,
            "lastPrepareDurationMs" to lastPrepareDurationMs,
        )
    }
}
