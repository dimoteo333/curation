import 'app_config.dart';

class AppSettings {
  const AppSettings({
    required this.runtimeMode,
    required this.onboardingCompleted,
    this.llmModelPath,
    this.embedderModelPath,
  });

  final CurationRuntimeMode runtimeMode;
  final String? llmModelPath;
  final String? embedderModelPath;
  final bool onboardingCompleted;

  AppSettings copyWith({
    CurationRuntimeMode? runtimeMode,
    String? llmModelPath,
    bool clearLlmModelPath = false,
    String? embedderModelPath,
    bool clearEmbedderModelPath = false,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
      runtimeMode: runtimeMode ?? this.runtimeMode,
      llmModelPath: clearLlmModelPath
          ? null
          : llmModelPath ?? this.llmModelPath,
      embedderModelPath: clearEmbedderModelPath
          ? null
          : embedderModelPath ?? this.embedderModelPath,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
