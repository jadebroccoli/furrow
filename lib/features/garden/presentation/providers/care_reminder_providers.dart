import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../shared/data/care_tips_data.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

/// SharedPreferences key for storing watering reminder plant IDs
const _wateringRemindersKey = 'watering_reminder_plant_ids';

/// Provider that manages which plants have watering reminders enabled.
/// Stores a Set<String> of plant IDs in SharedPreferences.
final wateringRemindersProvider =
    StateNotifierProvider<WateringRemindersNotifier, Set<String>>((ref) {
  final prefsAsync = ref.watch(sharedPrefsProvider);
  final prefs = prefsAsync.valueOrNull;
  return WateringRemindersNotifier(prefs);
});

class WateringRemindersNotifier extends StateNotifier<Set<String>> {
  WateringRemindersNotifier(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences? _prefs;

  static Set<String> _loadInitial(SharedPreferences? prefs) {
    final stored = prefs?.getStringList(_wateringRemindersKey);
    return stored?.toSet() ?? {};
  }

  /// Enable watering reminder for a plant
  Future<void> enable({
    required String plantId,
    required String plantName,
    required String category,
  }) async {
    // 1. Persist state first so toggle always works visually
    state = {...state, plantId};
    _prefs?.setStringList(_wateringRemindersKey, state.toList());

    // 2. Attempt notification scheduling (best-effort)
    try {
      final tips = careTipsForPlant(plantName, category);
      final intervalDays = _parseWateringDays(tips?.wateringFrequency);
      await NotificationService.instance.scheduleWateringReminder(
        plantId: plantId,
        plantName: plantName,
        intervalDays: intervalDays,
      );
    } catch (_) {
      // Notification scheduling may fail on unsupported platforms (e.g. Windows)
      // Toggle state is already persisted — notifications are best-effort
    }
  }

  /// Disable watering reminder for a plant
  Future<void> disable(String plantId) async {
    // 1. Persist state first
    state = {...state}..remove(plantId);
    _prefs?.setStringList(_wateringRemindersKey, state.toList());

    // 2. Cancel notification (best-effort)
    try {
      await NotificationService.instance.cancelWateringReminder(plantId);
    } catch (_) {
      // Cancellation may fail on unsupported platforms
    }
  }

  /// Toggle watering reminder for a plant
  Future<void> toggle({
    required String plantId,
    required String plantName,
    required String category,
  }) async {
    if (state.contains(plantId)) {
      await disable(plantId);
    } else {
      await enable(
          plantId: plantId, plantName: plantName, category: category);
    }
  }

  /// Check if a specific plant has reminders enabled
  bool isEnabled(String plantId) => state.contains(plantId);
}

/// Parse the watering frequency string to get approximate interval in days.
/// e.g. "Every 1-2 days" → 1, "Every 2-3 days" → 2
int _parseWateringDays(String? frequency) {
  if (frequency == null) return 2;

  // Try to extract the first number from the string
  final match = RegExp(r'(\d+)').firstMatch(frequency);
  if (match != null) {
    return int.tryParse(match.group(1)!) ?? 2;
  }
  return 2; // default to every 2 days
}
