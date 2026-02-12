import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/color_schemes.dart';
import '../../../../shared/data/plant_grow_data.dart';
import '../../../../shared/data/care_tips_data.dart';
import '../../domain/entities/plant.dart' show isHarvestable;
import '../../../paywall/presentation/providers/entitlement_providers.dart';
import '../../../journal/presentation/providers/journal_providers.dart';
import '../../../journal/presentation/widgets/journal_entry_card.dart';
import '../../../seasons/presentation/screens/log_harvest_dialog.dart';
import '../../../seasons/presentation/providers/season_providers.dart';
import '../providers/care_reminder_providers.dart';
import '../providers/plant_providers.dart';

/// Plant detail screen — shows full info for a single plant
/// Tapped into from the garden list
class PlantDetailScreen extends ConsumerWidget {
  const PlantDetailScreen({
    super.key,
    required this.plantId,
  });

  final String plantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plantAsync = ref.watch(plantByIdProvider(plantId));
    final dateFormat = DateFormat('MMMM d, yyyy');

    return plantAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (plant) {
        if (plant == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Plant not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(plant.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Plant'),
                      content: Text(
                          'Remove "${plant.name}" from your garden?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            'Delete',
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    ref.read(plantActionsProvider).deletePlant(plant.id);
                    context.pop();
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status banner
              _StatusBanner(status: plant.status, colorScheme: colorScheme, theme: theme),
              const SizedBox(height: 20),

              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Details',
                              style: theme.textTheme.titleMedium),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit details',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                context.push('/edit-plant/${plant.id}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      _InfoRow(
                        icon: Icons.eco,
                        label: 'Name',
                        value: plant.name,
                      ),
                      if (plant.variety != null && plant.variety!.isNotEmpty)
                        _InfoRow(
                          icon: Icons.local_florist,
                          label: 'Variety',
                          value: plant.variety!,
                        ),
                      _InfoRow(
                        icon: Icons.category,
                        label: 'Category',
                        value: plant.category[0].toUpperCase() +
                            plant.category.substring(1),
                      ),
                      _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Planted',
                        value: dateFormat.format(plant.plantedDate),
                      ),
                      if (isHarvestable(plant.category) && plant.expectedHarvestDate != null)
                        _InfoRow(
                          icon: Icons.event_available,
                          label: 'Expected Harvest',
                          value: dateFormat
                              .format(plant.expectedHarvestDate!),
                        ),

                      // Season assignment row
                      Builder(builder: (context) {
                        final allSeasons =
                            ref.watch(seasonsStreamProvider).valueOrNull ?? [];
                        final currentSeason = allSeasons
                            .where((s) => s.id == plant.seasonId)
                            .firstOrNull;

                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showSeasonPicker(
                            context,
                            ref,
                            plant.id,
                            plant.seasonId,
                            allSeasons,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    'Season',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    currentSeason?.name ?? 'None',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      color: currentSeason != null
                                          ? null
                                          : colorScheme.outline,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Editable notes card
              const SizedBox(height: 12),
              _NotesCard(
                plantId: plant.id,
                notes: plant.notes,
              ),

              // Harvest timing card (Pro, harvestable categories only)
              if (ref.watch(isProProvider) &&
                  isHarvestable(plant.category) &&
                  plant.expectedHarvestDate != null) ...[
                const SizedBox(height: 12),
                _HarvestTimingCard(
                  plantedDate: plant.plantedDate,
                  expectedHarvestDate: plant.expectedHarvestDate!,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ],

              // Care tips card (Pro)
              if (ref.watch(isProProvider)) ...[
                const SizedBox(height: 12),
                _CareTipsCard(
                  plantName: plant.name,
                  category: plant.category,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ],

              // Watering reminder toggle (Pro)
              if (ref.watch(isProProvider)) ...[
                const SizedBox(height: 12),
                _WateringReminderCard(
                  plantId: plant.id,
                  plantName: plant.name,
                  category: plant.category,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ],

              const SizedBox(height: 24),

              // Quick action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/add-journal?plantId=${plant.id}');
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Add Journal Entry'),
                    ),
                  ),
                  if (isHarvestable(plant.category)) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (_) => LogHarvestDialog(
                              plantId: plant.id,
                              plantName: plant.name,
                            ),
                          );
                        },
                        icon: const Icon(Icons.agriculture),
                        label: const Text('Log Harvest'),
                      ),
                    ),
                  ],
                ],
              ),

              // Update status section
              const SizedBox(height: 24),
              Text('Update Status', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'planned',
                  'seedling',
                  'growing',
                  'flowering',
                  if (isHarvestable(plant.category)) 'harvesting',
                  'dormant',
                  'removed',
                ]
                    .map((status) => ChoiceChip(
                          label: Text(status[0].toUpperCase() +
                              status.substring(1)),
                          selected: plant.status == status,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(plantActionsProvider)
                                  .updatePlant(
                                    id: plant.id,
                                    status: status,
                                  );
                            }
                          },
                        ))
                    .toList(),
              ),

              // Recent journal entries for this plant
              const SizedBox(height: 24),
              Text('Recent Journal Entries',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _PlantJournalEntries(
                plantId: plant.id,
                plantName: plant.name,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows a bottom sheet for picking a season assignment
void _showSeasonPicker(
  BuildContext context,
  WidgetRef ref,
  String plantId,
  String? currentSeasonId,
  List<Season> allSeasons,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Assign to Season', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          // "No Season" option
          ListTile(
            leading: Icon(Icons.remove_circle_outline,
                color: colorScheme.outline),
            title: const Text('No Season'),
            trailing: currentSeasonId == null
                ? Icon(Icons.check, color: colorScheme.primary)
                : null,
            onTap: () {
              ref.read(plantActionsProvider).updatePlant(
                    id: plantId,
                    clearSeasonId: true,
                  );
              Navigator.of(ctx).pop();
            },
          ),
          const Divider(height: 1),

          // Season options
          ...allSeasons.map((season) {
            final isSelected = season.id == currentSeasonId;
            return ListTile(
              leading: Icon(
                season.isActive
                    ? Icons.calendar_month
                    : Icons.calendar_month_outlined,
                color: season.isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(season.name),
              subtitle: season.isActive
                  ? Text('Active',
                      style: TextStyle(
                          color: colorScheme.primary, fontSize: 12))
                  : null,
              trailing: isSelected
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                ref.read(plantActionsProvider).updatePlant(
                      id: plantId,
                      seasonId: season.id,
                    );
                Navigator.of(ctx).pop();
              },
            );
          }),
        ],
      ),
    ),
  );
}

/// Shows the most recent journal entries for a specific plant
class _PlantJournalEntries extends ConsumerWidget {
  const _PlantJournalEntries({
    required this.plantId,
    required this.plantName,
  });

  final String plantId;
  final String plantName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entriesAsync =
        ref.watch(journalEntriesForPlantProvider(plantId));
    final dateFormat = DateFormat('MMM d, yyyy');

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
      data: (entries) {
        if (entries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No journal entries yet.\nTap "Add Journal Entry" to start.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        // Show last 3 entries
        final recent = entries.take(3).toList();
        return Column(
          children: [
            ...recent.map((entry) => JournalEntryCard(
                  plantName: plantName,
                  date: dateFormat.format(entry.date),
                  note: entry.note,
                  photoPath: entry.photoPath,
                  photoCaption:
                      '$plantName · ${dateFormat.format(entry.date)}',
                )),
            if (entries.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to full journal filtered by this plant
                  },
                  child: Text('View all ${entries.length} entries'),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Status banner at the top of the detail screen
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.status,
    required this.colorScheme,
    required this.theme,
  });

  final String status;
  final ColorScheme colorScheme;
  final ThemeData theme;

  Color get _color {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: theme.textTheme.titleMedium?.copyWith(
              color: _color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Harvest timing card with circular progress indicator
class _HarvestTimingCard extends StatelessWidget {
  const _HarvestTimingCard({
    required this.plantedDate,
    required this.expectedHarvestDate,
    required this.theme,
    required this.colorScheme,
  });

  final DateTime plantedDate;
  final DateTime expectedHarvestDate;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final progress = harvestProgress(plantedDate, expectedHarvestDate);
    final daysLeft = daysUntilHarvest(expectedHarvestDate);
    final isReady = progress >= 1.0;
    final progressColor =
        isReady ? FurrowColors.harvestGold : FurrowColors.seedlingGreen;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, size: 20, color: progressColor),
                const SizedBox(width: 8),
                Text('Harvest Timing', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Circular progress
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          strokeWidth: 8,
                          backgroundColor:
                              progressColor.withValues(alpha: 0.15),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(progressColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        isReady
                            ? '🌾'
                            : '${(progress * 100).toInt()}%',
                        style: isReady
                            ? const TextStyle(fontSize: 24)
                            : theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReady
                            ? 'Ready to harvest!'
                            : '$daysLeft days until harvest',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isReady
                              ? FurrowColors.harvestGold
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expected: ${DateFormat('MMM d, yyyy').format(expectedHarvestDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!isReady) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Based on typical growing times for this plant category.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Care tips card showing watering, sun, and tips for the plant category
class _CareTipsCard extends StatelessWidget {
  const _CareTipsCard({
    required this.plantName,
    required this.category,
    required this.theme,
    required this.colorScheme,
  });

  final String plantName;
  final String category;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final tips = careTipsForPlant(plantName, category);
    if (tips == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Care Tips', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),

            // Watering + Sun row
            Row(
              children: [
                Expanded(
                  child: _CareChip(
                    icon: Icons.water_drop,
                    label: tips.wateringFrequency,
                    color: FurrowColors.frostBlue,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CareChip(
                    icon: Icons.wb_sunny,
                    label: tips.sunNeeds,
                    color: FurrowColors.harvestGold,
                    theme: theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tips list
            ...tips.tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: FurrowColors.seedlingGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tip,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Watering reminder toggle card
class _WateringReminderCard extends ConsumerWidget {
  const _WateringReminderCard({
    required this.plantId,
    required this.plantName,
    required this.category,
    required this.theme,
    required this.colorScheme,
  });

  final String plantId;
  final String plantName;
  final String category;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(wateringRemindersProvider);
    final isEnabled = reminders.contains(plantId);
    final tips = careTipsForPlant(plantName, category);
    final frequency = tips?.wateringFrequency ?? 'Every 2-3 days';

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.notifications_active,
              size: 22,
              color: isEnabled
                  ? FurrowColors.frostBlue
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Water Reminder',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    isEnabled
                        ? 'Daily reminder · $frequency'
                        : 'Get notified when it\'s time to water',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isEnabled,
              onChanged: (_) async {
                await ref.read(wateringRemindersProvider.notifier).toggle(
                      plantId: plantId,
                      plantName: plantName,
                      category: category,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Small chip showing a care attribute (watering or sun)
class _CareChip extends StatelessWidget {
  const _CareChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable notes card with three modes:
/// - Empty + not editing: "Add Note" button
/// - Has content + not editing: Card with note text, edit & clear actions
/// - Editing: TextField with Save & Cancel
class _NotesCard extends ConsumerStatefulWidget {
  const _NotesCard({
    required this.plantId,
    required this.notes,
  });

  final String plantId;
  final String? notes;

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.notes ?? '');
  }

  @override
  void didUpdateWidget(_NotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller if notes changed externally and not currently editing
    if (!_isEditing && oldWidget.notes != widget.notes) {
      _controller.text = widget.notes ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    await ref.read(plantActionsProvider).updatePlant(
          id: widget.plantId,
          notes: text.isNotEmpty ? text : '',
        );
    if (mounted) setState(() => _isEditing = false);
  }

  void _cancel() {
    _controller.text = widget.notes ?? '';
    setState(() => _isEditing = false);
  }

  Future<void> _clear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Note'),
        content: const Text('Remove this note from the plant?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(plantActionsProvider).updatePlant(
            id: widget.plantId,
            notes: '',
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasNotes =
        widget.notes != null && widget.notes!.isNotEmpty;

    // Mode 1: Empty + not editing → subtle "Add Note" button
    if (!hasNotes && !_isEditing) {
      return OutlinedButton.icon(
        onPressed: () => setState(() => _isEditing = true),
        icon: const Icon(Icons.note_add_outlined, size: 18),
        label: const Text('Add Note'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
      );
    }

    // Mode 3: Editing (new or existing)
    if (_isEditing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note,
                      size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Notes', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Jot down care thoughts, observations...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancel,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Mode 2: Has content + not editing → display card with actions
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sticky_note_2_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child:
                      Text('Notes', style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  icon: Icon(Icons.edit,
                      size: 18, color: colorScheme.onSurfaceVariant),
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.close,
                      size: 18, color: colorScheme.outline),
                  onPressed: _clear,
                  tooltip: 'Clear',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.notes!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple info row with icon, label, and value
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
