import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/weather_service.dart';

/// Holds the user's location state
final userLocationProvider =
    AsyncNotifierProvider<UserLocationNotifier, Position?>(
        UserLocationNotifier.new);

class UserLocationNotifier extends AsyncNotifier<Position?> {
  @override
  Future<Position?> build() async {
    // Don't auto-fetch — wait for user to grant permission
    return null;
  }

  /// Request location permission and fetch position
  Future<void> requestAndFetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final locationService = ref.read(locationServiceProvider);
      final hasPermission = await locationService.checkPermissions();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }
      final position = await locationService.getCurrentPosition();
      if (position == null) {
        throw Exception('Could not get location');
      }
      return position;
    });
  }
}

/// Fetches the 7-day forecast once we have a location
final forecastProvider =
    FutureProvider<List<DailyForecast>>((ref) async {
  final locationAsync = ref.watch(userLocationProvider);

  return locationAsync.when(
    loading: () => <DailyForecast>[],
    error: (_, __) => <DailyForecast>[],
    data: (position) async {
      if (position == null) return <DailyForecast>[];

      final weatherService = ref.read(weatherServiceProvider);
      return weatherService.getFrostForecast(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    },
  );
});

/// Filtered view: only days with frost risk
final frostAlertDaysProvider = Provider<List<DailyForecast>>((ref) {
  final forecastAsync = ref.watch(forecastProvider);
  return forecastAsync.when(
    loading: () => [],
    error: (_, __) => [],
    data: (forecast) =>
        forecast.where((day) => day.frostSeverity != null).toList(),
  );
});
