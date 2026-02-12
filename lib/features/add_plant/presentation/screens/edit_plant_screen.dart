import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart' show Plant;
import '../../../../shared/data/plant_grow_data.dart';
import '../../../../shared/data/plant_species_data.dart';
import '../../../garden/domain/entities/plant.dart'
    show PlantCategory, PlantStatus, isHarvestable;
import '../../../garden/presentation/providers/plant_providers.dart';

/// Edit plant screen — pre-filled form for modifying an existing plant.
/// Navigated to via pencil icon on plant detail screen.
class EditPlantScreen extends ConsumerStatefulWidget {
  const EditPlantScreen({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends ConsumerState<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _varietyController = TextEditingController();
  final _notesController = TextEditingController();

  PlantCategory _category = PlantCategory.vegetable;
  PlantStatus _status = PlantStatus.seedling;
  DateTime _plantedDate = DateTime.now();
  DateTime? _expectedHarvestDate;
  bool _isSaving = false;
  bool _isLoaded = false;

  /// Currently matched species from the autocomplete system
  PlantSpeciesInfo? _matchedSpecies;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _varietyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Pre-fill form fields from the existing plant data.
  /// Called once when the plant data first loads.
  void _prefillFromPlant(Plant plant) {
    if (_isLoaded) return;
    _isLoaded = true;

    _nameController.text = plant.name;
    _varietyController.text = plant.variety ?? '';
    _notesController.text = plant.notes ?? '';

    _category = PlantCategory.values.firstWhere(
      (c) => c.name == plant.category,
      orElse: () => PlantCategory.other,
    );
    _status = PlantStatus.values.firstWhere(
      (s) => s.name == plant.status,
      orElse: () => PlantStatus.seedling,
    );
    _plantedDate = plant.plantedDate;
    _expectedHarvestDate = plant.expectedHarvestDate;

    // Try to re-match species for autocomplete hints
    _matchedSpecies = lookupSpecies(plant.name);
  }

  void _updateExpectedHarvest() {
    setState(() {
      if (_matchedSpecies != null) {
        _expectedHarvestDate = _plantedDate
            .add(Duration(days: _matchedSpecies!.daysToHarvestEstimate));
      } else {
        _expectedHarvestDate =
            estimatedHarvestDate(_category.name, _plantedDate);
      }
    });
  }

  void _onSpeciesSelected(PlantSpeciesInfo species) {
    setState(() {
      _matchedSpecies = species;
      _nameController.text = species.name;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: species.name.length),
      );
      _category = PlantCategory.values.firstWhere(
        (c) => c.name == species.category,
        orElse: () => PlantCategory.other,
      );
    });
    _updateExpectedHarvest();
  }

  Future<void> _updatePlant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final success = await ref.read(plantActionsProvider).updatePlant(
            id: widget.plantId,
            name: _nameController.text.trim(),
            variety: _varietyController.text.trim().isNotEmpty
                ? _varietyController.text.trim()
                : null,
            category: _category.name,
            status: _status.name,
            plantedDate: _plantedDate,
            expectedHarvestDate: _expectedHarvestDate,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_nameController.text.trim()} updated!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to update plant'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');

    final plantAsync = ref.watch(plantByIdProvider(widget.plantId));

    return plantAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Plant')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit Plant')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (plant) {
        if (plant == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit Plant')),
            body: const Center(child: Text('Plant not found')),
          );
        }

        // Pre-fill once
        _prefillFromPlant(plant);

        return Scaffold(
          appBar: AppBar(
            title: Text('Edit Plant', style: theme.textTheme.titleLarge),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _updatePlant,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Plant name with autocomplete
                RawAutocomplete<PlantSpeciesInfo>(
                  textEditingController: _nameController,
                  focusNode: _nameFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.length < 2) {
                      return const Iterable<PlantSpeciesInfo>.empty();
                    }
                    return searchSpecies(textEditingValue.text);
                  },
                  displayStringForOption: (option) => option.name,
                  onSelected: _onSpeciesSelected,
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.surface,
                          surfaceTintColor: colorScheme.surfaceTint,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    _categoryIcon(option.category),
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                  title: Text(
                                    option.name,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    option.daysToHarvestMin > 0
                                        ? '${option.category[0].toUpperCase()}${option.category.substring(1)} · ${option.daysToHarvestMin}-${option.daysToHarvestMax} days'
                                        : '${option.category[0].toUpperCase()}${option.category.substring(1)} · Care-only',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Plant Name',
                        hintText: 'e.g., Tomato, Basil, Carrot...',
                        prefixIcon: const Icon(Icons.eco),
                        suffixIcon: _matchedSpecies != null
                            ? Tooltip(
                                message:
                                    _matchedSpecies!.daysToHarvestMin > 0
                                        ? '${_matchedSpecies!.daysToHarvestMin}-${_matchedSpecies!.daysToHarvestMax} days to harvest'
                                        : 'Care-only plant',
                                child: Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              )
                            : null,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (value) {
                        if (_matchedSpecies != null &&
                            value.trim().toLowerCase() !=
                                _matchedSpecies!.name.toLowerCase()) {
                          setState(() => _matchedSpecies = null);
                          _updateExpectedHarvest();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a plant name';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                ),

                // Species match hint
                if (_matchedSpecies != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      '✓ ${_matchedSpecies!.name} — ${_matchedSpecies!.wateringFrequency}, ${_matchedSpecies!.sunNeeds}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Variety
                TextFormField(
                  controller: _varietyController,
                  decoration: const InputDecoration(
                    labelText: 'Variety (optional)',
                    hintText: 'e.g., Cherokee Purple',
                    prefixIcon: Icon(Icons.local_florist),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<PlantCategory>(
                  key: ValueKey('cat_$_category'),
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: PlantCategory.values
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.name[0].toUpperCase() +
                                cat.name.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                        if (_matchedSpecies != null &&
                            _matchedSpecies!.category != value.name) {
                          _matchedSpecies = null;
                        }
                      });
                      _updateExpectedHarvest();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Status dropdown
                DropdownButtonFormField<PlantStatus>(
                  key: ValueKey('status_$_status'),
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.timeline),
                  ),
                  items: PlantStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name[0].toUpperCase() +
                                s.name.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Planted date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Planted Date'),
                  subtitle: Text(dateFormat.format(_plantedDate)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _plantedDate,
                      firstDate: DateTime(2020),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _plantedDate = date);
                      _updateExpectedHarvest();
                    }
                  },
                ),

                // Expected harvest date (harvestable categories only)
                if (isHarvestable(_category.name) &&
                    _expectedHarvestDate != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.event_available,
                        color: colorScheme.primary),
                    title: const Text('Expected Harvest'),
                    subtitle: Text(
                      dateFormat.format(_expectedHarvestDate!),
                      style: TextStyle(color: colorScheme.primary),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _expectedHarvestDate!,
                        firstDate: _plantedDate,
                        lastDate: _plantedDate
                            .add(const Duration(days: 365 * 5)),
                      );
                      if (date != null) {
                        setState(() => _expectedHarvestDate = date);
                      }
                    },
                  ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Any additional details...',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
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
}
