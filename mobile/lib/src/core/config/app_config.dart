class AppConfig {
  const AppConfig();

  static const String _defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  String get apiBaseUrl => _defaultApiBaseUrl.endsWith('/')
      ? _defaultApiBaseUrl.substring(0, _defaultApiBaseUrl.length - 1)
      : _defaultApiBaseUrl;
}
