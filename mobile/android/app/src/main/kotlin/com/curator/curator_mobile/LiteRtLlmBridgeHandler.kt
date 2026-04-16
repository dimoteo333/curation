package com.curator.curator_mobile

import android.content.Context
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
        try {
            llmInference = initializeLlm(llmModelPath)
            textEmbedder = initializeEmbedder(embedderModelPath)
            result.success(buildStatus())
        } catch (error: Exception) {
            result.error("prepare_failed", error.message, null)
        }
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
                result.error("llm_unavailable", "LiteRT LLM 모델 경로가 준비되지 않았습니다.", null)
                return
            }

            val response = inference.generateResponse(prompt)
            result.success(response)
        } catch (error: Exception) {
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
                result.error("embedder_unavailable", "텍스트 임베딩 모델 경로가 준비되지 않았습니다.", null)
                return
            }

            val embedding = embedder.embed(text)
                .embeddings()
                .firstOrNull()
                ?.floatEmbedding()
                ?.map { value -> value.toDouble() }
                ?: emptyList()

            result.success(embedding)
        } catch (error: Exception) {
            result.error("embed_failed", error.message, null)
        }
    }

    private fun initializeLlm(modelPath: String?): LlmInference? {
        if (modelPath.isNullOrBlank() || !File(modelPath).exists()) {
            return null
        }

        return llmInference ?: run {
            val options = LlmInference.LlmInferenceOptions.builder()
                .setModelPath(modelPath)
                .setMaxTokens(512)
                .setTopK(32)
                .setTemperature(0.3f)
                .setRandomSeed(17)
                .build()
            LlmInference.createFromOptions(context, options)
        }
    }

    private fun initializeEmbedder(modelPath: String?): TextEmbedder? {
        if (modelPath.isNullOrBlank() || !File(modelPath).exists()) {
            return null
        }

        return textEmbedder ?: run {
            val baseOptions = BaseOptions.builder()
                .setModelAssetPath(modelPath)
                .build()
            val options = TextEmbedder.TextEmbedderOptions.builder()
                .setBaseOptions(baseOptions)
                .build()
            TextEmbedder.createFromOptions(context, options)
        }
    }

    private fun buildStatus(): Map<String, Any> {
        val llmPath = llmModelPath
        val embedPath = embedderModelPath
        val llmReady = llmInference != null && !llmPath.isNullOrBlank()
        val embedderReady = textEmbedder != null && !embedPath.isNullOrBlank()

        val message = when {
            llmReady && embedderReady -> "LiteRT LLM 및 텍스트 임베더가 준비되었습니다."
            llmReady -> "LiteRT LLM은 준비되었지만 임베더 모델은 아직 없습니다."
            embedderReady -> "텍스트 임베더는 준비되었지만 LLM 모델은 아직 없습니다."
            !llmPath.isNullOrBlank() || !embedPath.isNullOrBlank() ->
                "모델 경로가 전달되었지만 네이티브 런타임 초기화가 완료되지 않았습니다."
            else -> "모델 경로가 없어 Dart 로컬 폴백을 사용합니다."
        }

        return mapOf(
            "llmReady" to llmReady,
            "embedderReady" to embedderReady,
            "runtime" to "android-native",
            "message" to message,
        )
    }
}
