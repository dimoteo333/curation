import 'app_config.dart';

class AppSettings {
  const AppSettings({
    required this.runtimeMode,
    required this.currentVersion,
    required this.onboardingCompleted,
    required this.calendarSyncEnabled,
    this.firstRunVersion,
    this.llmModelPath,
    this.embedderModelPath,
  });

  final CurationRuntimeMode runtimeMode;
  final String currentVersion;
  final String? firstRunVersion;
  final String? llmModelPath;
  final String? embedderModelPath;
  final bool onboardingCompleted;
  final bool calendarSyncEnabled;

  bool get isFirstRun => firstRunVersion == null;

  AppSettings copyWith({
    CurationRuntimeMode? runtimeMode,
    String? currentVersion,
    String? firstRunVersion,
    bool clearFirstRunVersion = false,
    String? llmModelPath,
    bool clearLlmModelPath = false,
    String? embedderModelPath,
    bool clearEmbedderModelPath = false,
    bool? onboardingCompleted,
    bool? calendarSyncEnabled,
  }) {
    return AppSettings(
      runtimeMode: runtimeMode ?? this.runtimeMode,
      currentVersion: currentVersion ?? this.currentVersion,
      firstRunVersion: clearFirstRunVersion
          ? null
          : firstRunVersion ?? this.firstRunVersion,
      llmModelPath: clearLlmModelPath
          ? null
          : llmModelPath ?? this.llmModelPath,
      embedderModelPath: clearEmbedderModelPath
          ? null
          : embedderModelPath ?? this.embedderModelPath,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      calendarSyncEnabled: calendarSyncEnabled ?? this.calendarSyncEnabled,
    );
  }
}
