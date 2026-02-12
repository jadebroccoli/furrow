import 'package:freezed_annotation/freezed_annotation.dart';

part 'frost_alert.freezed.dart';
part 'frost_alert.g.dart';

/// Severity level of a frost alert
enum FrostSeverity {
  warning,  // Near freezing (32-36F / 0-2C)
  danger,   // Freezing (28-32F / -2-0C)
  hardFreeze, // Hard freeze (<28F / <-2C)
}

/// A frost alert based on weather forecast
@freezed
class FrostAlert with _$FrostAlert {
  const factory FrostAlert({
    required String id,
    required DateTime forecastDate,
    required double lowTempF,
    required double lowTempC,
    required FrostSeverity severity,
    String? description,
    @Default(false) bool isDismissed,
    required DateTime createdAt,
  }) = _FrostAlert;

  factory FrostAlert.fromJson(Map<String, dynamic> json) =>
      _$FrostAlertFromJson(json);
}
