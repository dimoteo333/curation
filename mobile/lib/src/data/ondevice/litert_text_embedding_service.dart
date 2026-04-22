import '../../domain/services/text_embedding_service.dart';
import 'litert_method_channel_bridge.dart';

/// Embedding service that uses native LiteRT when ready and Dart fallback otherwise.
class LiteRtTextEmbeddingService implements TextEmbeddingService {
  const LiteRtTextEmbeddingService({
    required this.bridge,
    required this.fallback,
    this.llmModelPath,
    this.embedderModelPath,
  });

  final OnDeviceLlmBridge bridge;
  final TextEmbeddingService fallback;
  final String? llmModelPath;
  final String? embedderModelPath;

  @override
  Future<List<double>> embed(String text) async {
    final status = await bridge.prepare(
      llmModelPath: llmModelPath,
      embedderModelPath: embedderModelPath,
    );
    if (!status.embedderReady) {
      return fallback.embed(text);
    }

    try {
      return await bridge.embed(text);
    } on OnDeviceRuntimeException {
      return fallback.embed(text);
    }
  }
}
