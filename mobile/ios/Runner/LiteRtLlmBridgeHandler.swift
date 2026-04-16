import Flutter
import Foundation
import MediaPipeTasksGenAI
import MediaPipeTasksText

final class LiteRtLlmBridgeHandler {
  private var llmModelPath: String?
  private var embedderModelPath: String?
  private var llmInference: LlmInference?
  private var textEmbedder: TextEmbedder?
  private var lastErrorMessage: String?
  private var lastPrepareDurationMs: Int?

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "prepare":
      prepare(call: call, result: result)
    case "status":
      result(buildStatus())
    case "generate":
      generate(call: call, result: result)
    case "embed":
      embed(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func prepare(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    llmModelPath = arguments?["llmModelPath"] as? String
    embedderModelPath = arguments?["embedderModelPath"] as? String

    let startedAt = Date()
    var errors: [String] = []
    llmInference = initializeLlm(modelPath: llmModelPath, errors: &errors)
    textEmbedder = initializeEmbedder(modelPath: embedderModelPath, errors: &errors)
    lastPrepareDurationMs = Int(Date().timeIntervalSince(startedAt) * 1000)
    lastErrorMessage = errors.first
    result(buildStatus())
  }

  private func generate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let prompt = arguments["prompt"] as? String,
      !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      result(
        FlutterError(code: "invalid_prompt", message: "프롬프트가 비어 있습니다.", details: nil)
      )
      return
    }

    do {
      guard let inference = initializeLlm(modelPath: llmModelPath) else {
        lastErrorMessage = "LLM 모델 경로가 없거나 파일을 찾을 수 없습니다."
        result(
          FlutterError(code: "llm_unavailable", message: "LLM 모델 경로가 준비되지 않았습니다.", details: nil)
        )
        return
      }

      let response = try inference.generateResponse(inputText: prompt)
      lastErrorMessage = nil
      result(response)
    } catch {
      lastErrorMessage = error.localizedDescription
      result(
        FlutterError(code: "generate_failed", message: error.localizedDescription, details: nil)
      )
    }
  }

  private func embed(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let arguments = call.arguments as? [String: Any],
      let text = arguments["text"] as? String,
      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      result(
        FlutterError(code: "invalid_text", message: "임베딩할 텍스트가 비어 있습니다.", details: nil)
      )
      return
    }

    do {
      guard let embedder = initializeEmbedder(modelPath: embedderModelPath) else {
        lastErrorMessage = "임베더 모델 경로가 없거나 파일을 찾을 수 없습니다."
        result(
          FlutterError(
            code: "embedder_unavailable",
            message: "텍스트 임베딩 모델 경로가 준비되지 않았습니다.",
            details: nil
          )
        )
        return
      }

      let embedding = try embedder.embed(text: text)
      let values = embedding.embeddings.first?.floatEmbedding?.map { Double($0) } ?? []
      lastErrorMessage = nil
      result(values)
    } catch {
      lastErrorMessage = error.localizedDescription
      result(
        FlutterError(code: "embed_failed", message: error.localizedDescription, details: nil)
      )
    }
  }

  private func initializeLlm(
    modelPath: String?
  ) -> LlmInference? {
    var ignoredErrors: [String] = []
    return initializeLlm(modelPath: modelPath, errors: &ignoredErrors)
  }

  private func initializeLlm(
    modelPath: String?,
    errors: inout [String]
  ) -> LlmInference? {
    guard
      let modelPath,
      !modelPath.isEmpty
    else {
      return nil
    }
    guard FileManager.default.fileExists(atPath: modelPath) else {
      errors.append("LLM 모델 파일을 찾지 못했습니다.")
      return nil
    }

    if let llmInference {
      return llmInference
    }

    do {
      let options = LlmInferenceOptions()
      options.baseOptions.modelPath = modelPath
      options.maxTokens = 512
      options.topk = 32
      options.temperature = 0.3
      options.randomSeed = 17

      let runtime = try LlmInference(options: options)
      llmInference = runtime
      return runtime
    } catch {
      errors.append(error.localizedDescription)
      return nil
    }
  }

  private func initializeEmbedder(
    modelPath: String?
  ) -> TextEmbedder? {
    var ignoredErrors: [String] = []
    return initializeEmbedder(modelPath: modelPath, errors: &ignoredErrors)
  }

  private func initializeEmbedder(
    modelPath: String?,
    errors: inout [String]
  ) -> TextEmbedder? {
    guard
      let modelPath,
      !modelPath.isEmpty
    else {
      return nil
    }
    guard FileManager.default.fileExists(atPath: modelPath) else {
      errors.append("임베더 모델 파일을 찾지 못했습니다.")
      return nil
    }

    if let textEmbedder {
      return textEmbedder
    }

    do {
      let options = TextEmbedderOptions()
      options.baseOptions.modelAssetPath = modelPath

      let runtime = try TextEmbedder(options: options)
      textEmbedder = runtime
      return runtime
    } catch {
      errors.append(error.localizedDescription)
      return nil
    }
  }

  private func buildStatus() -> [String: Any] {
    let llmConfigured = !(llmModelPath ?? "").isEmpty
    let embedConfigured = !(embedderModelPath ?? "").isEmpty
    let llmAvailable = llmConfigured && FileManager.default.fileExists(atPath: llmModelPath!)
    let embedAvailable = embedConfigured && FileManager.default.fileExists(atPath: embedderModelPath!)
    let llmReady = llmInference != nil && llmAvailable
    let embedderReady = textEmbedder != nil && embedAvailable
    let fallbackActive = !llmReady || !embedderReady
    let runtime: String
    if llmReady && embedderReady {
      runtime = "native-ready"
    } else if lastErrorMessage != nil {
      runtime = "native-error"
    } else if llmReady || embedderReady {
      runtime = "native-partial"
    } else {
      runtime = "template-fallback"
    }

    let message: String
    if llmReady && embedderReady {
      message = "LiteRT LLM 및 텍스트 임베더가 준비되었습니다."
    } else if llmConfigured && !llmAvailable {
      message = "LLM 모델 경로가 설정되었지만 파일을 찾지 못해 템플릿 폴백을 사용합니다."
    } else if embedConfigured && !embedAvailable {
      message = "임베더 모델 경로가 설정되었지만 파일을 찾지 못해 해시 임베딩 폴백을 사용합니다."
    } else if llmReady {
      message = "LLM은 네이티브지만 임베더가 준비되지 않아 검색은 폴백 경로를 사용합니다."
    } else if embedderReady {
      message = "임베더는 네이티브지만 LLM이 준비되지 않아 응답은 템플릿 폴백으로 생성합니다."
    } else if lastErrorMessage != nil {
      message = "네이티브 초기화에 실패해 온디바이스 폴백을 사용합니다."
    } else {
      message = "모델 경로가 없어 Dart 로컬 폴백을 사용합니다."
    }

    return [
      "llmReady": llmReady,
      "embedderReady": embedderReady,
      "runtime": runtime,
      "message": message,
      "platform": "ios",
      "llmModelConfigured": llmConfigured,
      "embedderModelConfigured": embedConfigured,
      "llmModelAvailable": llmAvailable,
      "embedderModelAvailable": embedAvailable,
      "fallbackActive": fallbackActive,
      "lastError": lastErrorMessage as Any,
      "lastPrepareDurationMs": lastPrepareDurationMs as Any,
    ]
  }
}
