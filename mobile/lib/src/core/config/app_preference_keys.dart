class AppPreferenceKeys {
  const AppPreferenceKeys._();

  static const String runtimeMode = 'app.runtime_mode';
  static const String llmModelPath = 'app.llm_model_path';
  static const String embedderModelPath = 'app.embedder_model_path';
  static const String onboardingCompleted = 'app.onboarding_completed';
  static const String firstRunVersion = 'app.first_run_version';
  static const String calendarSyncEnabled = 'app.calendar_sync_enabled';
  static const String excludedRecordIds = 'app.excluded_record_ids';
  static const String excludedCalendarIds = 'app.excluded_calendar_ids';
  static const String recentConversations = 'app.recent_conversations';

  static const String importHistoryEntries = 'import_history.entries';
  static const String importHistorySourceIndex = 'import_history.source_index';
  static const String importHistoryFileIndex = 'import_history.file_index';
  static const String importHistoryCalendarLastSync =
      'import_history.calendar.last_sync';

  static const Set<String> dataKeysDeletedOnReset = <String>{
    excludedRecordIds,
    recentConversations,
    importHistoryEntries,
    importHistorySourceIndex,
    importHistoryFileIndex,
    importHistoryCalendarLastSync,
  };
}
