import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_preference_keys.dart';
import '../providers.dart';

class ExcludedCalendarsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final stored =
        ref
            .watch(sharedPreferencesProvider)
            .getStringList(AppPreferenceKeys.excludedCalendarIds) ??
        const <String>[];
    return Set<String>.unmodifiable(
      stored.map((value) => value.trim()).where((value) => value.isNotEmpty),
    );
  }

  Future<void> setExcluded({
    required String calendarId,
    required bool excluded,
  }) async {
    final normalized = calendarId.trim();
    if (normalized.isEmpty) {
      return;
    }

    final next = {...state};
    if (excluded) {
      next.add(normalized);
    } else {
      next.remove(normalized);
    }

    state = Set<String>.unmodifiable(next);
    await _persist(next);
  }

  Future<void> clear() async {
    state = const <String>{};
    await ref
        .read(sharedPreferencesProvider)
        .remove(AppPreferenceKeys.excludedCalendarIds);
  }

  Future<void> _persist(Set<String> values) {
    if (values.isEmpty) {
      return ref
          .read(sharedPreferencesProvider)
          .remove(AppPreferenceKeys.excludedCalendarIds);
    }

    final sorted = values.toList()..sort();
    return ref
        .read(sharedPreferencesProvider)
        .setStringList(AppPreferenceKeys.excludedCalendarIds, sorted);
  }
}
