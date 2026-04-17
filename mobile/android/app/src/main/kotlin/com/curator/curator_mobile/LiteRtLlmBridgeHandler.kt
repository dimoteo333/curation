package com.curator.curator_mobile

import android.content.Context
import android.os.SystemClock
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class LiteRtLlmBridgeHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private var llmModelPath: String? = null
    private var embedderModelPath: String? = null
    private var llmInference: LlmInference? = null
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
                result.error("llm_unavailable", "LLM 모델 경로가 준비되지 않았습니다.", null)
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

        result.error(
            "embedder_unavailable",
            "네이티브 텍스트 임베딩 모델이 준비되지 않았습니다. Dart 폴백을 사용합니다.",
            null,
        )
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
                    .setMaxTopK(32)
                    .build()
                LlmInference.createFromOptions(context, options)
            } catch (error: Exception) {
                errors.add(error.message ?: "LLM 초기화에 실패했습니다.")
                null
            }
        }
    }

    private fun buildStatus(): Map<String, Any?> {
        val llmPath = llmModelPath
        val embedPath = embedderModelPath
        val llmConfigured = !llmPath.isNullOrBlank()
        val embedConfigured = !embedPath.isNullOrBlank()
        val llmAvailable = llmConfigured && File(llmPath!!).exists()
        val embedAvailable = embedConfigured && File(embedPath!!).exists()
        val llmReady = llmInference != null && llmAvailable
        val embedderReady = false
        val fallbackActive = !llmReady || !embedderReady
        val runtime = when {
            llmReady && embedderReady -> "native-ready"
            llmReady || embedderReady -> "native-partial"
            lastErrorMessage != null -> "native-error"
            else -> "template-fallback"
        }

        val message = when {
            llmReady && embedderReady -> "LiteRT LLM 및 텍스트 임베더가 준비되었습니다."
            llmReady -> "LiteRT LLM은 준비되었지만 텍스트 임베딩은 Dart 폴백을 사용합니다."
            llmConfigured && !llmAvailable -> "LLM 모델 경로가 설정되었지만 파일을 찾지 못해 Dart 로컬 폴백을 사용합니다."
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
