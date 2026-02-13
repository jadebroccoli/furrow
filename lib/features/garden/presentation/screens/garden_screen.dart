import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../paywall/presentation/providers/entitlement_providers.dart';
import '../providers/garden_filter_providers.dart';
import '../providers/plant_providers.dart';
import '../widgets/plant_card.dart';

/// Garden overview screen - Tab 1
/// Shows list of all plants with search, filter, and sort
class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
        ref.read(gardenSearchProvider.notifier).state = '';
      } else {
        // Focus the search field after the frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FilterSortSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredPlantsAsync = ref.watch(filteredPlantsProvider);
    final hasFilters = ref.watch(hasActiveFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? _SearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (value) {
                  ref.read(gardenSearchProvider.notifier).state = value;
                },
              )
            : Text('My Garden', style: theme.textTheme.titleLarge),
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search plants',
            onPressed: _toggleSearch,
          ),

          // Filter button with active badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filter & Sort',
                onPressed: _showFilterSheet,
              ),
              if (hasFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile & Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: filteredPlantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading plants: $error'),
        ),
        data: (plants) {
          // Check if we have ANY plants at all (unfiltered)
          final allPlantsAsync = ref.watch(plantsStreamProvider);
          final totalPlants = allPlantsAsync.value?.length ?? 0;

          if (totalPlants == 0) {
            return EmptyState(
              icon: Icons.yard_outlined,
              title: 'No plants yet',
              subtitle:
                  'Start tracking your garden by adding your first plant.',
              actionLabel: 'Add Plant',
              onAction: () => context.push('/add-plant'),
            );
          }

          // Active filter chips
          final activeCategories = ref.watch(gardenCategoryFilterProvider);
          final activeStatuses = ref.watch(gardenStatusFilterProvider);
          final sortMode = ref.watch(gardenSortProvider);
          final showChips = activeCategories.isNotEmpty ||
              activeStatuses.isNotEmpty ||
              sortMode != GardenSortMode.newestFirst;

          return Column(
            children: [
              // Active filter chips bar
              if (showChips)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Sort chip
                      if (sortMode != GardenSortMode.newestFirst)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            avatar: Icon(Icons.sort,
                                size: 16, color: colorScheme.primary),
                            label: Text(sortMode.label),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              ref.read(gardenSortProvider.notifier).state =
                                  GardenSortMode.newestFirst;
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),

                      // Category chips
                      for (final cat in activeCategories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              cat[0].toUpperCase() + cat.substring(1),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              ref
                                  .read(gardenCategoryFilterProvider.notifier)
                                  .state = {...activeCategories}..remove(cat);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),

                      // Status chips
                      for (final st in activeStatuses)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Chip(
                            label: Text(
                              st[0].toUpperCase() + st.substring(1),
                            ),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              ref
                                  .read(gardenStatusFilterProvider.notifier)
                                  .state = {...activeStatuses}..remove(st);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),

                      // Clear all
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(Icons.clear_all,
                              size: 16, color: colorScheme.error),
                          label: Text(
                            'Clear all',
                            style: TextStyle(color: colorScheme.error),
                          ),
                          onPressed: () {
                            ref.read(gardenSortProvider.notifier).state =
                                GardenSortMode.newestFirst;
                            ref
                                .read(gardenCategoryFilterProvider.notifier)
                                .state = {};
                            ref
                                .read(gardenStatusFilterProvider.notifier)
                                .state = {};
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),

              // Result count
              if (hasFilters)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${plants.length} of $totalPlants plants',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

              // Plant list
              Expanded(
                child: plants.isEmpty
                    ? _NoMatchState(
                        onClear: () {
                          _searchController.clear();
                          ref.read(gardenSearchProvider.notifier).state = '';
                          ref.read(gardenCategoryFilterProvider.notifier).state =
                              {};
                          ref.read(gardenStatusFilterProvider.notifier).state =
                              {};
                          ref.read(gardenSortProvider.notifier).state =
                              GardenSortMode.newestFirst;
                          setState(() => _showSearch = false);
                        },
                      )
                    : _PlantListView(plants: plants),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Search field ─────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search plants...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
      ),
    );
  }
}

// ─── No matching results ─────────────────────────────────

class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No matching plants',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search term.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plant list view ─────────────────────────────────────

class _PlantListView extends ConsumerWidget {
  const _PlantListView({required this.plants});

  final List<dynamic> plants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPro = ref.watch(isProProvider);
    final photoMap = ref.watch(latestPlantPhotosProvider).valueOrNull ?? {};
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];

        return Dismissible(
          key: Key(plant.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onError,
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Plant'),
                content: Text('Remove "${plant.name}" from your garden?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Delete',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            ref.read(plantActionsProvider).deletePlant(plant.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${plant.name} removed'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: PlantCard(
            name: plant.name,
            variety: plant.variety,
            status: plant.status,
            plantedDate: dateFormat.format(plant.plantedDate),
            category: plant.category,
            photoUrl: photoMap[plant.id],
            plantedDateRaw: plant.plantedDate,
            expectedHarvestDate: plant.expectedHarvestDate,
            showProgress: isPro,
            onTap: () {
              context.push('/plant/${plant.id}');
            },
          ),
        );
      },
    );
  }
}

// ─── Filter & Sort bottom sheet ──────────────────────────

class _FilterSortSheet extends StatelessWidget {
  const _FilterSortSheet({required this.ref});

  final WidgetRef ref;

  static const _categories = [
    'vegetable',
    'herb',
    'fruit',
    'flower',
    'legume',
    'root',
    'houseplant',
    'other',
  ];

  static const _statuses = [
    'planned',
    'seedling',
    'growing',
    'flowering',
    'harvesting',
    'dormant',
    'removed',
  ];

  static const _categoryIcons = <String, IconData>{
    'vegetable': Icons.eco,
    'herb': Icons.grass,
    'fruit': Icons.apple,
    'flower': Icons.local_florist,
    'legume': Icons.grain,
    'root': Icons.park,
    'houseplant': Icons.grass,
    'other': Icons.yard,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer(builder: (context, ref, _) {
      final selectedCategories = ref.watch(gardenCategoryFilterProvider);
      final selectedStatuses = ref.watch(gardenStatusFilterProvider);
      final sortMode = ref.watch(gardenSortProvider);

      return DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          final bottomInset = MediaQuery.of(context).padding.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
            child: ListView(
              controller: scrollController,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter & Sort',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(gardenSortProvider.notifier).state =
                            GardenSortMode.newestFirst;
                        ref.read(gardenCategoryFilterProvider.notifier).state =
                            {};
                        ref.read(gardenStatusFilterProvider.notifier).state = {};
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Sort ──
                Text(
                  'Sort By',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: GardenSortMode.values.map((mode) {
                    final isSelected = sortMode == mode;
                    return ChoiceChip(
                      label: Text(
                        mode.label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest,
                      checkmarkColor: colorScheme.onPrimary,
                      onSelected: (_) {
                        ref.read(gardenSortProvider.notifier).state = mode;
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Category ──
                Text(
                  'Category',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _categories.map((cat) {
                    final isSelected = selectedCategories.contains(cat);
                    return FilterChip(
                      avatar: Icon(
                        _categoryIcons[cat] ?? Icons.yard,
                        size: 18,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      label: Text(
                        cat[0].toUpperCase() + cat.substring(1),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest,
                      checkmarkColor: colorScheme.onPrimary,
                      showCheckmark: false,
                      onSelected: (selected) {
                        final updated = {...selectedCategories};
                        if (selected) {
                          updated.add(cat);
                        } else {
                          updated.remove(cat);
                        }
                        ref
                            .read(gardenCategoryFilterProvider.notifier)
                            .state = updated;
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // ── Status ──
                Text(
                  'Status',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _statuses.map((st) {
                    final isSelected = selectedStatuses.contains(st);
                    return FilterChip(
                      label: Text(
                        st[0].toUpperCase() + st.substring(1),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest,
                      checkmarkColor: colorScheme.onPrimary,
                      onSelected: (selected) {
                        final updated = {...selectedStatuses};
                        if (selected) {
                          updated.add(st);
                        } else {
                          updated.remove(st);
                        }
                        ref
                            .read(gardenStatusFilterProvider.notifier)
                            .state = updated;
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}
