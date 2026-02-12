import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification service for frost alerts and plant reminders
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification plugin
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Show a frost alert notification
  Future<void> showFrostAlert({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'frost_alerts',
      'Frost Alerts',
      channelDescription: 'Notifications for frost warnings in your area',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Show a plant reminder notification
  Future<void> showPlantReminder({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'plant_reminders',
      'Plant Reminders',
      channelDescription: 'Reminders for watering, harvesting, etc.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// Schedule a repeating watering reminder for a plant.
  ///
  /// Uses [periodicallyShow] with a daily interval. The notification ID
  /// is derived from the plant ID hash so we can cancel it later.
  Future<void> scheduleWateringReminder({
    required String plantId,
    required String plantName,
    required int intervalDays,
  }) async {
    final notifId = _wateringNotifId(plantId);

    const androidDetails = AndroidNotificationDetails(
      'plant_reminders',
      'Plant Reminders',
      channelDescription: 'Reminders for watering, harvesting, etc.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Map interval days to the closest supported RepeatInterval
    final interval = intervalDays <= 1
        ? RepeatInterval.daily
        : RepeatInterval.everyMinute; // see note below

    // flutter_local_notifications only supports fixed intervals:
    // everyMinute, hourly, daily, weekly.
    // For 2-3 day intervals we use daily and note the frequency in the body.
    // A more precise approach would use zonedSchedule + timezone package.
    await _plugin.periodicallyShow(
      notifId,
      '💧 Time to water $plantName',
      'Your $plantName is thirsty! Check the soil and water if dry.',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel watering reminder for a specific plant
  Future<void> cancelWateringReminder(String plantId) async {
    await _plugin.cancel(_wateringNotifId(plantId));
  }

  /// Cancel all watering reminders
  Future<void> cancelAllWateringReminders(List<String> plantIds) async {
    for (final id in plantIds) {
      await _plugin.cancel(_wateringNotifId(id));
    }
  }

  /// Derive a stable notification ID from a plant ID string
  int _wateringNotifId(String plantId) {
    // Use the hashCode but keep it positive and in a reasonable range
    return plantId.hashCode.abs() % 100000;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Handle notification tap - navigate to relevant screen
  }
}
