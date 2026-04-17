import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/config/app_settings.dart';
import '../providers.dart';

class AppSettingsController extends Notifier<AppSettings> {
  static const String _runtimeModeKey = 'app.runtime_mode';
  static const String _llmModelPathKey = 'app.llm_model_path';
  static const String _embedderModelPathKey = 'app.embedder_model_path';
  static const String _onboardingCompletedKey = 'app.onboarding_completed';
  static const String _calendarSyncEnabledKey = 'app.calendar_sync_enabled';

  SharedPreferences get _preferences => ref.read(sharedPreferencesProvider);
  AppConfig get _config => ref.read(appConfigProvider);

  @override
  AppSettings build() {
    return AppSettings(
      runtimeMode: _runtimeMode(),
      llmModelPath: _storedPath(_llmModelPathKey) ?? _config.llmModelPath,
      embedderModelPath:
          _storedPath(_embedderModelPathKey) ?? _config.embedderModelPath,
      onboardingCompleted:
          _preferences.getBool(_onboardingCompletedKey) ?? false,
      calendarSyncEnabled: _preferences.getBool(_calendarSyncEnabledKey) ?? false,
    );
  }

  Future<void> setRuntimeMode(CurationRuntimeMode mode) async {
    await _preferences.setString(_runtimeModeKey, mode.value);
    state = state.copyWith(runtimeMode: mode);
  }

  Future<void> saveModelPaths({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    final normalizedLlmPath = _normalizePath(llmModelPath);
    final normalizedEmbedderPath = _normalizePath(embedderModelPath);

    if (normalizedLlmPath == null) {
      await _preferences.remove(_llmModelPathKey);
    } else {
      await _preferences.setString(_llmModelPathKey, normalizedLlmPath);
    }

    if (normalizedEmbedderPath == null) {
      await _preferences.remove(_embedderModelPathKey);
    } else {
      await _preferences.setString(
        _embedderModelPathKey,
        normalizedEmbedderPath,
      );
    }

    state = state.copyWith(
      llmModelPath: normalizedLlmPath,
      clearLlmModelPath: normalizedLlmPath == null,
      embedderModelPath: normalizedEmbedderPath,
      clearEmbedderModelPath: normalizedEmbedderPath == null,
    );
  }

  Future<void> completeOnboarding() async {
    await _preferences.setBool(_onboardingCompletedKey, true);
    state = state.copyWith(onboardingCompleted: true);
  }

  Future<void> setCalendarSyncEnabled(bool enabled) async {
    await _preferences.setBool(_calendarSyncEnabledKey, enabled);
    state = state.copyWith(calendarSyncEnabled: enabled);
  }

  CurationRuntimeMode _runtimeMode() {
    final storedValue = _preferences.getString(_runtimeModeKey);
    if (storedValue == null) {
      return _config.curationMode;
    }
    return CurationRuntimeMode.fromEnvironment(storedValue);
  }

  String? _storedPath(String key) {
    return _normalizePath(_preferences.getString(key));
  }

  String? _normalizePath(String? rawValue) {
    final trimmed = rawValue?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
