import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_preference_keys.dart';
import '../core/config/app_config.dart';
import '../core/config/app_settings.dart';
import '../providers.dart';

class AppSettingsController extends Notifier<AppSettings> {
  SharedPreferences get _preferences => ref.read(sharedPreferencesProvider);
  AppConfig get _config => ref.read(appConfigProvider);
  String get _currentVersion => ref.read(appBuildInfoProvider).versionLabel;

  @override
  AppSettings build() {
    return AppSettings(
      runtimeMode: _runtimeMode(),
      currentVersion: _currentVersion,
      firstRunVersion: _preferences.getString(
        AppPreferenceKeys.firstRunVersion,
      ),
      llmModelPath:
          _storedPath(AppPreferenceKeys.llmModelPath) ?? _config.llmModelPath,
      embedderModelPath:
          _storedPath(AppPreferenceKeys.embedderModelPath) ??
          _config.embedderModelPath,
      onboardingCompleted:
          _preferences.getBool(AppPreferenceKeys.onboardingCompleted) ?? false,
      calendarSyncEnabled:
          _preferences.getBool(AppPreferenceKeys.calendarSyncEnabled) ?? false,
    );
  }

  Future<void> setRuntimeMode(CurationRuntimeMode mode) async {
    await _preferences.setString(AppPreferenceKeys.runtimeMode, mode.value);
    state = state.copyWith(runtimeMode: mode);
  }

  Future<void> saveModelPaths({
    String? llmModelPath,
    String? embedderModelPath,
  }) async {
    final normalizedLlmPath = _normalizePath(llmModelPath);
    final normalizedEmbedderPath = _normalizePath(embedderModelPath);

    if (normalizedLlmPath == null) {
      await _preferences.remove(AppPreferenceKeys.llmModelPath);
    } else {
      await _preferences.setString(
        AppPreferenceKeys.llmModelPath,
        normalizedLlmPath,
      );
    }

    if (normalizedEmbedderPath == null) {
      await _preferences.remove(AppPreferenceKeys.embedderModelPath);
    } else {
      await _preferences.setString(
        AppPreferenceKeys.embedderModelPath,
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

  Future<void> ensureFirstRunVersion() async {
    final existing = _preferences.getString(AppPreferenceKeys.firstRunVersion);
    if (existing != null && existing.isNotEmpty) {
      state = state.copyWith(
        currentVersion: _currentVersion,
        firstRunVersion: existing,
      );
      return;
    }

    await _preferences.setString(
      AppPreferenceKeys.firstRunVersion,
      _currentVersion,
    );
    state = state.copyWith(
      currentVersion: _currentVersion,
      firstRunVersion: _currentVersion,
    );
  }

  Future<void> completeOnboarding() async {
    await ensureFirstRunVersion();
    await _preferences.setBool(AppPreferenceKeys.onboardingCompleted, true);
    state = state.copyWith(
      currentVersion: _currentVersion,
      firstRunVersion: state.firstRunVersion ?? _currentVersion,
      onboardingCompleted: true,
    );
  }

  Future<void> setCalendarSyncEnabled(bool enabled) async {
    await _preferences.setBool(AppPreferenceKeys.calendarSyncEnabled, enabled);
    state = state.copyWith(calendarSyncEnabled: enabled);
  }

  CurationRuntimeMode _runtimeMode() {
    final storedValue = _preferences.getString(AppPreferenceKeys.runtimeMode);
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
