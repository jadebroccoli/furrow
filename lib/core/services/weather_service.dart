import 'package:dio/dio.dart';
import '../../shared/constants/app_constants.dart';

/// Weather service using Open-Meteo API (free, no API key required)
/// Provides frost alert data based on user's location
class WeatherService {
  WeatherService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Fetch minimum temperature forecast for the next 7 days
  Future<List<DailyForecast>> getFrostForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get(
        '${AppConstants.weatherBaseUrl}${AppConstants.weatherForecastEndpoint}',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'daily': 'temperature_2m_min,temperature_2m_max,weathercode',
          'temperature_unit': 'fahrenheit',
          'forecast_days': 7,
          'timezone': 'auto',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;

      final dates = (daily['time'] as List).cast<String>();
      final minTemps = (daily['temperature_2m_min'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      final maxTemps = (daily['temperature_2m_max'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
      final weatherCodes = (daily['weathercode'] as List)
          .map((e) => (e as num).toInt())
          .toList();

      final forecasts = <DailyForecast>[];
      for (int i = 0; i < dates.length; i++) {
        forecasts.add(DailyForecast(
          date: DateTime.parse(dates[i]),
          minTempF: minTemps[i],
          maxTempF: maxTemps[i],
          weatherCode: weatherCodes[i],
        ));
      }

      return forecasts;
    } catch (e) {
      return [];
    }
  }

  /// Check if any upcoming day has frost risk
  Future<bool> hasFrostRisk({
    required double latitude,
    required double longitude,
  }) async {
    final forecast = await getFrostForecast(
      latitude: latitude,
      longitude: longitude,
    );
    return forecast.any((day) => day.hasFrostWarning);
  }
}

/// Daily forecast data from Open-Meteo
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.minTempF,
    required this.maxTempF,
    this.weatherCode = 0,
  });

  final DateTime date;
  final double minTempF;
  final double maxTempF;
  final int weatherCode;

  double get minTempC => (minTempF - 32) * 5 / 9;
  double get maxTempC => (maxTempF - 32) * 5 / 9;

  bool get hasFrostWarning => minTempF <= AppConstants.frostWarningTempF;
  bool get hasFrostDanger => minTempF <= AppConstants.frostDangerTempF;
  bool get hasHardFreeze => minTempF <= AppConstants.hardFreezeTempF;

  /// Get frost severity level (null = no frost)
  String? get frostSeverity {
    if (hasHardFreeze) return 'hardFreeze';
    if (hasFrostDanger) return 'danger';
    if (hasFrostWarning) return 'warning';
    return null;
  }

  /// Human-readable weather description from WMO code
  String get weatherDescription {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  /// Weather icon based on WMO code
  String get weatherIcon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 55) return '🌦️';
    if (weatherCode <= 65) return '🌧️';
    if (weatherCode <= 67) return '🧊';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '🌧️';
    if (weatherCode <= 86) return '🌨️';
    return '⛈️';
  }
}
