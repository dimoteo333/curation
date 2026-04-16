enum CurationRuntimeMode {
  onDevice('on_device'),
  remote('remote');

  const CurationRuntimeMode(this.value);

  final String value;

  static CurationRuntimeMode fromEnvironment(String rawValue) {
    return values.firstWhere(
      (mode) => mode.value == rawValue,
      orElse: () => CurationRuntimeMode.onDevice,
    );
  }
}

class AppConfig {
  const AppConfig();

  static const String _defaultRuntimeMode = String.fromEnvironment(
    'CURATION_MODE',
    defaultValue: 'on_device',
  );
  static const String _defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String _defaultLlmModelPath = String.fromEnvironment(
    'LLM_MODEL_PATH',
    defaultValue: '',
  );
  static const String _defaultEmbedderModelPath = String.fromEnvironment(
    'EMBEDDER_MODEL_PATH',
    defaultValue: '',
  );
  static const String _defaultVectorDbName = String.fromEnvironment(
    'VECTOR_DB_NAME',
    defaultValue: 'curator_ondevice.db',
  );

  CurationRuntimeMode get curationMode =>
      CurationRuntimeMode.fromEnvironment(_defaultRuntimeMode);

  String get apiBaseUrl => _defaultApiBaseUrl.endsWith('/')
      ? _defaultApiBaseUrl.substring(0, _defaultApiBaseUrl.length - 1)
      : _defaultApiBaseUrl;

  String? get llmModelPath => _normalizePath(_defaultLlmModelPath);

  String? get embedderModelPath => _normalizePath(_defaultEmbedderModelPath);

  String get vectorDbName => _defaultVectorDbName;

  String? _normalizePath(String rawValue) {
    final trimmed = rawValue.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
