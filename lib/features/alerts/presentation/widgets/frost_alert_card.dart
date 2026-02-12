import 'package:flutter/material.dart';
import '../../../../shared/theme/color_schemes.dart';
import '../../../../shared/widgets/furrow_card.dart';

/// Card widget displaying a frost alert
class FrostAlertCard extends StatelessWidget {
  const FrostAlertCard({
    super.key,
    required this.date,
    required this.lowTemp,
    required this.severity,
    this.description,
    this.onDismiss,
  });

  final String date;
  final String lowTemp;
  final String severity; // 'warning', 'danger', 'hardFreeze'
  final String? description;
  final VoidCallback? onDismiss;

  Color _severityColor() {
    switch (severity) {
      case 'hardFreeze':
        return FurrowColors.frostBlue;
      case 'danger':
        return FurrowColors.alertRed;
      default:
        return FurrowColors.harvestGold;
    }
  }

  IconData _severityIcon() {
    switch (severity) {
      case 'hardFreeze':
        return Icons.severe_cold;
      case 'danger':
        return Icons.ac_unit;
      default:
        return Icons.thermostat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _severityColor();

    return FurrowCard(
      child: Row(
        children: [
          // Severity icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _severityIcon(),
              color: color,
            ),
          ),
          const SizedBox(width: 16),

          // Alert info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low of $lowTemp',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                  ),
                ),
                Text(
                  date,
                  style: theme.textTheme.bodySmall,
                ),
                if (description != null)
                  Text(
                    description!,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),

          // Dismiss
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
