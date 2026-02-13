import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/revenue_cat_service.dart';
import '../services/weather_service.dart';

/// Database provider - singleton instance
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Weather service provider
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// Location service provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// RevenueCat service provider
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService.instance;
});
