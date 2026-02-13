/// App-wide constants for Furrow
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Furrow';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Track your garden from seed to harvest.';

  // Weather API (Open-Meteo - free, no key required)
  static const String weatherBaseUrl = 'https://api.open-meteo.com/v1';
  static const String weatherForecastEndpoint = '/forecast';

  // Frost alert thresholds (Fahrenheit)
  static const double frostWarningTempF = 36.0;
  static const double frostDangerTempF = 32.0;
  static const double hardFreezeTempF = 28.0;

  // Frost alert thresholds (Celsius)
  static const double frostWarningTempC = 2.2;
  static const double frostDangerTempC = 0.0;
  static const double hardFreezeTempC = -2.2;

  // Database
  static const String databaseName = 'furrow.db';
  static const int databaseVersion = 2;

  // Photo
  static const double maxPhotoWidth = 1024;
  static const double maxPhotoHeight = 1024;
  static const int photoQuality = 85;

  // UI
  static const double cardBorderRadius = 16.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Free tier limits
  static const int freePlantLimit = 5;
  static const int freeSeasonLimit = 1;

  // Pro tier pricing (display fallbacks — actual prices from RevenueCat)
  static const String proMonthlyPrice = '\$2.99/mo';
  static const String proYearlyPrice = '\$19.99/yr';
  static const String proLifetimePrice = '\$49.99';

  // Onboarding
  static const String onboardingCompleteKey = 'onboarding_complete';
}
