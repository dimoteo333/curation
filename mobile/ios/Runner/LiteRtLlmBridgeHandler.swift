import Flutter
import Foundation
import MediaPipeTasksGenAI
// MediaPipeTasksText temporarily disabled - MediaPipeTasksTextC not available as CocoaPod
// Embedding falls back to Dart-side SemanticEmbeddingService

final class LiteRtLlmBridgeHandler {
  private var llmModelPath: String?
  private var llmInference: LlmInference?
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
      // Embedding not available on native side yet
      result(
        FlutterError(
          code: "embedder_unavailable",
          message: "네이티브 텍스트 임베딩 모델이 준비되지 않았습니다. Dart 폴백을 사용합니다.",
          details: nil
        )
      )
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func prepare(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    llmModelPath = arguments?["llmModelPath"] as? String

    let startedAt = Date()
    var errors: [String] = []
    llmInference = initializeLlm(modelPath: llmModelPath, errors: &errors)
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

  private func initializeLlm(modelPath: String?) -> LlmInference? {
    var ignoredErrors: [String] = []
    return initializeLlm(modelPath: modelPath, errors: &ignoredErrors)
  }

  private func initializeLlm(modelPath: String?, errors: inout [String]) -> LlmInference? {
    guard let modelPath, !modelPath.isEmpty else { return nil }
    guard FileManager.default.fileExists(atPath: modelPath) else {
      errors.append("LLM 모델 파일을 찾지 못했습니다.")
      return nil
    }
    if let llmInference { return llmInference }

    do {
      let options = LlmInference.Options(modelPath: modelPath)
      options.maxTokens = 512
      let runtime = try LlmInference(options: options)
      llmInference = runtime
      return runtime
    } catch {
      errors.append(error.localizedDescription)
      return nil
    }
  }

  private func buildStatus() -> [String: Any] {
    let llmConfigured = !(llmModelPath ?? "").isEmpty
    let llmAvailable = llmConfigured && FileManager.default.fileExists(atPath: llmModelPath!)
    let llmReady = llmInference != nil && llmAvailable
    let fallbackActive = !llmReady

    let runtime: String
    if llmReady {
      runtime = "native-ready"
    } else if lastErrorMessage != nil {
      runtime = "native-error"
    } else {
      runtime = "template-fallback"
    }

    let message: String
    if llmReady {
      message = "LiteRT LLM이 준비되었습니다. 임베딩은 Dart 폴백을 사용합니다."
    } else if llmConfigured && !llmAvailable {
      message = "LLM 모델 경로가 설정되었지만 파일을 찾지 못해 템플릿 폴백을 사용합니다."
    } else if let lastErrorMessage {
      message = "네이티브 초기화에 실패해 온디바이스 폴백을 사용합니다: \(lastErrorMessage)"
    } else {
      message = "모델 경로가 없어 Dart 로컬 폴백을 사용합니다."
    }

    return [
      "llmReady": llmReady,
      "embedderReady": false,
      "runtime": runtime,
      "message": message,
      "platform": "ios",
      "llmModelConfigured": llmConfigured,
      "embedderModelConfigured": false,
      "llmModelAvailable": llmAvailable,
      "embedderModelAvailable": false,
      "fallbackActive": fallbackActive,
      "lastError": lastErrorMessage as Any,
      "lastPrepareDurationMs": lastPrepareDurationMs as Any,
    ]
  }
}
