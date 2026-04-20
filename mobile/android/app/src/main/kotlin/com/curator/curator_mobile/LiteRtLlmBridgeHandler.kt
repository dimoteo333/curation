package com.curator.curator_mobile

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.google.ai.edge.litertlm.Backend
import com.google.ai.edge.litertlm.ConversationConfig
import com.google.ai.edge.litertlm.Engine
import com.google.ai.edge.litertlm.EngineConfig
import com.google.ai.edge.litertlm.SamplerConfig
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class LiteRtLlmBridgeHandler(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    private data class EngineInitializationResult(
        val engine: Engine,
        val backendLabel: String,
    )

    private val backgroundExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var llmModelPath: String? = null

    @Volatile
    private var embedderModelPath: String? = null

    @Volatile
    private var engine: Engine? = null

    @Volatile
    private var initializedModelPath: String? = null

    @Volatile
    private var activeBackendLabel: String? = null

    @Volatile
    private var lastErrorMessage: String? = null

    @Volatile
    private var lastPrepareDurationMs: Long? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> {
                llmModelPath = call.argument<String>("llmModelPath")
                embedderModelPath = call.argument<String>("embedderModelPath")
                backgroundExecutor.execute { prepareRuntime(result) }
            }
            "status" -> result.success(buildStatus())
            "generate" -> {
                val prompt = call.argument<String>("prompt")
                val temperature = call.argument<Double>("temperature") ?: 0.3
                val topK = call.argument<Int>("topK") ?: 32
                val randomSeed = call.argument<Int>("randomSeed") ?: 17
                handleGenerate(
                    prompt = prompt,
                    temperature = temperature,
                    topK = topK,
                    randomSeed = randomSeed,
                    result = result,
                )
            }
            "embed" -> handleEmbed(call, result)
            else -> result.notImplemented()
        }
    }

    private fun prepareRuntime(result: MethodChannel.Result) {
        val startedAt = SystemClock.elapsedRealtime()
        val errors = mutableListOf<String>()
        val runtime = ensureEngine(errors)
        lastPrepareDurationMs = SystemClock.elapsedRealtime() - startedAt
        lastErrorMessage = if (runtime == null) errors.firstOrNull() else null
        dispatchSuccess(result, buildStatus())
    }

    private fun handleGenerate(
        prompt: String?,
        temperature: Double,
        topK: Int,
        randomSeed: Int,
        result: MethodChannel.Result,
    ) {
        if (prompt.isNullOrBlank()) {
            result.error("invalid_prompt", "프롬프트가 비어 있습니다.", null)
            return
        }

        backgroundExecutor.execute {
            try {
                val errors = mutableListOf<String>()
                val runtime = ensureEngine(errors)
                if (runtime == null) {
                    lastErrorMessage =
                        errors.firstOrNull() ?: "LLM 모델 경로가 없거나 파일을 찾을 수 없습니다."
                    dispatchError(
                        result = result,
                        code = "llm_unavailable",
                        message = "LLM 모델 경로가 준비되지 않았습니다.",
                    )
                    return@execute
                }

                val response =
                    runtime.engine.createConversation(
                        ConversationConfig(
                            samplerConfig =
                                SamplerConfig(
                                    topK = topK.coerceAtLeast(1),
                                    topP = 0.95,
                                    temperature = temperature.coerceAtLeast(0.0),
                                    seed = randomSeed,
                                ),
                        ),
                    ).use { conversation ->
                        conversation.sendMessage(prompt).toString().trim()
                    }
                if (response.isBlank()) {
                    throw IllegalStateException("온디바이스 생성 결과가 비어 있습니다.")
                }

                lastErrorMessage = null
                dispatchSuccess(result, response)
            } catch (error: Exception) {
                lastErrorMessage = error.message
                dispatchError(
                    result = result,
                    code = "generate_failed",
                    message = error.message ?: "LiteRT-LM 생성에 실패했습니다.",
                )
            }
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

    private fun ensureEngine(
        errors: MutableList<String> = mutableListOf(),
    ): EngineInitializationResult? {
        val modelPath = llmModelPath?.trim()
        if (modelPath.isNullOrBlank()) {
            releaseEngine()
            return null
        }
        if (!File(modelPath).exists()) {
            releaseEngine()
            errors.add("LLM 모델 파일을 찾지 못했습니다.")
            return null
        }

        val existingEngine = engine
        if (existingEngine != null && initializedModelPath == modelPath) {
            return EngineInitializationResult(
                engine = existingEngine,
                backendLabel = activeBackendLabel ?: "cpu",
            )
        }

        releaseEngine()
        val candidateBackends =
            listOf(
                "gpu" to Backend.GPU(),
                "cpu" to Backend.CPU(),
            )
        for ((backendLabel, backend) in candidateBackends) {
            try {
                val runtime =
                    Engine(
                        EngineConfig(
                            modelPath = modelPath,
                            backend = backend,
                            cacheDir = context.cacheDir.absolutePath,
                        ),
                    )
                runtime.initialize()
                engine = runtime
                initializedModelPath = modelPath
                activeBackendLabel = backendLabel
                return EngineInitializationResult(runtime, backendLabel)
            } catch (error: Exception) {
                errors.add(
                    "${backendLabel.uppercase()}: ${error.message ?: "LiteRT-LM 초기화에 실패했습니다."}",
                )
            }
        }

        initializedModelPath = null
        activeBackendLabel = null
        return null
    }

    private fun releaseEngine() {
        val runtime = engine ?: return
        engine = null
        initializedModelPath = null
        activeBackendLabel = null
        try {
            runtime.close()
        } catch (_: Exception) {
        }
    }

    private fun buildStatus(): Map<String, Any?> {
        val llmPath = llmModelPath
        val embedPath = embedderModelPath
        val llmConfigured = !llmPath.isNullOrBlank()
        val embedConfigured = !embedPath.isNullOrBlank()
        val llmAvailable = llmConfigured && File(llmPath!!).exists()
        val embedAvailable = embedConfigured && File(embedPath!!).exists()
        val llmReady = engine != null && initializedModelPath == llmPath && llmAvailable
        val embedderReady = false
        val fallbackActive = !llmReady || !embedderReady
        val backendLabel = activeBackendLabel?.uppercase()
        val runtime = when {
            llmReady -> "native-partial"
            lastErrorMessage != null -> "native-error"
            else -> "template-fallback"
        }

        val message = when {
            llmReady ->
                "LiteRT-LM LLM이 ${backendLabel ?: "CPU"} 백엔드로 준비되었지만 텍스트 임베딩은 Dart 폴백을 사용합니다."
            llmConfigured && !llmAvailable -> "LLM 모델 경로가 설정되었지만 파일을 찾지 못해 Dart 로컬 폴백을 사용합니다."
            lastErrorMessage != null -> "LiteRT-LM 초기화에 실패해 온디바이스 폴백을 사용합니다."
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
            "llmBackend" to activeBackendLabel,
        )
    }

    private fun dispatchSuccess(result: MethodChannel.Result, payload: Any?) {
        mainHandler.post { result.success(payload) }
    }

    private fun dispatchError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        mainHandler.post { result.error(code, message, null) }
    }
}
