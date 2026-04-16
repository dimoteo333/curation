import Flutter
import Foundation
import MediaPipeTasksGenAI
import MediaPipeTasksText

final class LiteRtLlmBridgeHandler {
  private var llmModelPath: String?
  private var embedderModelPath: String?
  private var llmInference: LlmInference?
  private var textEmbedder: TextEmbedder?

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

    do {
      llmInference = try initializeLlm(modelPath: llmModelPath)
      textEmbedder = try initializeEmbedder(modelPath: embedderModelPath)
      result(buildStatus())
    } catch {
      result(
        FlutterError(
          code: "prepare_failed",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
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
      guard let inference = try initializeLlm(modelPath: llmModelPath) else {
        result(
          FlutterError(code: "llm_unavailable", message: "LLM 모델 경로가 준비되지 않았습니다.", details: nil)
        )
        return
      }

      let response = try inference.generateResponse(inputText: prompt)
      result(response)
    } catch {
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
      guard let embedder = try initializeEmbedder(modelPath: embedderModelPath) else {
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
      result(values)
    } catch {
      result(
        FlutterError(code: "embed_failed", message: error.localizedDescription, details: nil)
      )
    }
  }

  private func initializeLlm(modelPath: String?) throws -> LlmInference? {
    guard
      let modelPath,
      !modelPath.isEmpty,
      FileManager.default.fileExists(atPath: modelPath)
    else {
      return nil
    }

    if let llmInference {
      return llmInference
    }

    let options = LlmInferenceOptions()
    options.baseOptions.modelPath = modelPath
    options.maxTokens = 512
    options.topk = 32
    options.temperature = 0.3
    options.randomSeed = 17

    let runtime = try LlmInference(options: options)
    llmInference = runtime
    return runtime
  }

  private func initializeEmbedder(modelPath: String?) throws -> TextEmbedder? {
    guard
      let modelPath,
      !modelPath.isEmpty,
      FileManager.default.fileExists(atPath: modelPath)
    else {
      return nil
    }

    if let textEmbedder {
      return textEmbedder
    }

    let options = TextEmbedderOptions()
    options.baseOptions.modelAssetPath = modelPath

    let runtime = try TextEmbedder(options: options)
    textEmbedder = runtime
    return runtime
  }

  private func buildStatus() -> [String: Any] {
    let llmReady = llmInference != nil
    let embedderReady = textEmbedder != nil

    let message: String
    if llmReady && embedderReady {
      message = "LiteRT LLM 및 텍스트 임베더가 준비되었습니다."
    } else if llmReady {
      message = "LiteRT LLM은 준비되었지만 임베더 모델은 아직 없습니다."
    } else if embedderReady {
      message = "텍스트 임베더는 준비되었지만 LLM 모델은 아직 없습니다."
    } else if llmModelPath != nil || embedderModelPath != nil {
      message = "모델 경로가 전달되었지만 iOS 네이티브 초기화가 완료되지 않았습니다."
    } else {
      message = "모델 경로가 없어 Dart 로컬 폴백을 사용합니다."
    }

    return [
      "llmReady": llmReady,
      "embedderReady": embedderReady,
      "runtime": "ios-native",
      "message": message,
    ]
  }
}
