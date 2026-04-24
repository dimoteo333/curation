import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_preference_keys.dart';
import '../providers.dart';

class ExcludedRecordsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final stored =
        ref
            .watch(sharedPreferencesProvider)
            .getStringList(AppPreferenceKeys.excludedRecordIds) ??
        const <String>[];
    return Set<String>.unmodifiable(
      stored.map((value) => value.trim()).where((value) => value.isNotEmpty),
    );
  }

  Future<bool> excludeRecord(String recordId) async {
    final normalized = recordId.trim();
    if (normalized.isEmpty || state.contains(normalized)) {
      return false;
    }

    final next = {...state, normalized};
    state = Set<String>.unmodifiable(next);
    await _persist(next);
    return true;
  }

  Future<void> restoreRecord(String recordId) async {
    final normalized = recordId.trim();
    if (normalized.isEmpty || !state.contains(normalized)) {
      return;
    }

    final next = {...state}..remove(normalized);
    state = Set<String>.unmodifiable(next);
    await _persist(next);
  }

  Future<void> clear() async {
    state = const <String>{};
    await ref
        .read(sharedPreferencesProvider)
        .remove(AppPreferenceKeys.excludedRecordIds);
  }

  Future<void> _persist(Set<String> values) {
    final sorted = values.toList()..sort();
    return ref
        .read(sharedPreferencesProvider)
        .setStringList(AppPreferenceKeys.excludedRecordIds, sorted);
  }
}
