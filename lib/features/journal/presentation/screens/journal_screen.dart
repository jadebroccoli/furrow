import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../garden/presentation/providers/plant_providers.dart';
import '../providers/journal_providers.dart';
import '../widgets/journal_entry_card.dart';

/// Photo journal screen - Tab 2
/// Shows timeline of journal entries with photos and observations
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(journalEntriesStreamProvider);
    final plantsAsync = ref.watch(plantsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Journal',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => context.push('/add-journal'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile & Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading entries: $error'),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.photo_library_outlined,
              title: 'No journal entries',
              subtitle:
                  'Document your garden\'s progress with photos and observations.',
              actionLabel: 'Add Entry',
              onAction: () => context.push('/add-journal'),
            );
          }

          // Build a plant name lookup map
          final plantNames = <String, String>{};
          plantsAsync.whenData((plants) {
            for (final plant in plants) {
              plantNames[plant.id] = plant.variety != null &&
                      plant.variety!.isNotEmpty
                  ? '${plant.name} (${plant.variety})'
                  : plant.name;
            }
          });

          final dateFormat = DateFormat('MMM d, yyyy');

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final plantName =
                  plantNames[entry.plantId] ?? 'Unknown Plant';

              return JournalEntryCard(
                plantName: plantName,
                date: dateFormat.format(entry.date),
                note: entry.note,
                photoPath: entry.photoPath,
                photoCaption: '$plantName · ${dateFormat.format(entry.date)}',
                weatherTemp: entry.weatherTemp != null
                    ? '${entry.weatherTemp!.toStringAsFixed(0)}°'
                    : null,
                weatherCondition: entry.weatherCondition,
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Entry'),
                      content: const Text(
                          'Remove this journal entry? This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                                color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    ref.read(journalActionsProvider).deleteJournalEntry(
                          entry.id,
                          photoPath: entry.photoPath,
                        );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
