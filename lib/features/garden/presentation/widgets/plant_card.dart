import 'package:flutter/material.dart';
import '../../../../shared/widgets/furrow_card.dart';
import '../../../../shared/theme/color_schemes.dart';
import '../../../../shared/data/plant_grow_data.dart';
import '../../../garden/domain/entities/plant.dart';

/// Card widget displaying a plant summary in the garden list
class PlantCard extends StatelessWidget {
  const PlantCard({
    super.key,
    required this.name,
    this.variety,
    required this.status,
    required this.plantedDate,
    required this.category,
    this.photoUrl,
    this.onTap,
    this.plantedDateRaw,
    this.expectedHarvestDate,
    this.showProgress = false,
  });

  final String name;
  final String? variety;
  final String status;
  final String plantedDate;
  final String category;
  final String? photoUrl;
  final VoidCallback? onTap;
  final DateTime? plantedDateRaw;
  final DateTime? expectedHarvestDate;
  final bool showProgress;

  /// Map status string to a color
  Color _statusColor(ColorScheme colorScheme) {
    switch (status) {
      case 'planned':
        return colorScheme.outline;
      case 'seedling':
        return FurrowColors.seedlingGreen;
      case 'growing':
        return colorScheme.primary;
      case 'flowering':
        return FurrowColors.harvestGold;
      case 'harvesting':
        return const Color(0xFFFF8A00);
      case 'dormant':
        return colorScheme.outlineVariant;
      case 'removed':
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }

  /// Map status to display label
  String _statusLabel() {
    return status[0].toUpperCase() + status.substring(1);
  }

  /// Map category to an icon
  IconData _categoryIcon() {
    switch (category) {
      case 'vegetable':
        return Icons.eco;
      case 'herb':
        return Icons.grass;
      case 'fruit':
        return Icons.apple;
      case 'flower':
        return Icons.local_florist;
      case 'legume':
        return Icons.grain;
      case 'root':
        return Icons.park;
      case 'houseplant':
        return Icons.grass;
      default:
        return Icons.yard;
    }
  }

  /// Build the harvest progress bar + label
  Widget _buildHarvestProgress(ThemeData theme, ColorScheme colorScheme) {
    final progress = harvestProgress(plantedDateRaw!, expectedHarvestDate!);
    final daysLeft = daysUntilHarvest(expectedHarvestDate!);
    final isReady = progress >= 1.0;

    final progressColor =
        isReady ? FurrowColors.harvestGold : FurrowColors.seedlingGreen;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isReady
                ? '🌾 Ready to harvest!'
                : '${(progress * 100).toInt()}% · $daysLeft days left',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isReady ? FurrowColors.harvestGold : colorScheme.onSurfaceVariant,
              fontWeight: isReady ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(colorScheme);

    return FurrowCard(
      onTap: onTap,
      child: Row(
        children: [
          // Plant category icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcon(),
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Plant info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium,
                ),
                if (variety != null && variety!.isNotEmpty)
                  Text(
                    variety!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plantedDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                // Harvest progress indicator (Pro, harvestable categories only)
                if (showProgress && isHarvestable(category) && expectedHarvestDate != null && plantedDateRaw != null)
                  _buildHarvestProgress(theme, colorScheme),
              ],
            ),
          ),

          // Status chip with colored dot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
