import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/data/plant_grow_data.dart';
import '../../../../shared/data/plant_species_data.dart';
import '../../../garden/domain/entities/plant.dart' show PlantCategory, PlantStatus, isHarvestable;
import '../../../garden/presentation/providers/plant_providers.dart';
import '../../../journal/presentation/providers/journal_providers.dart';
import '../../../paywall/presentation/providers/entitlement_providers.dart';
import '../../../seasons/presentation/providers/season_providers.dart';

/// Add/Edit plant screen
/// Accessible via FAB from any tab
class AddPlantScreen extends ConsumerStatefulWidget {
  const AddPlantScreen({super.key});

  @override
  ConsumerState<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends ConsumerState<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _varietyController = TextEditingController();
  final _notesController = TextEditingController();

  PlantCategory _category = PlantCategory.vegetable;
  PlantStatus _status = PlantStatus.seedling;
  DateTime _plantedDate = DateTime.now();
  DateTime? _expectedHarvestDate;
  String? _photoPath;
  bool _isSaving = false;
  bool _assignToActiveSeason = true;

  /// Currently matched species from the autocomplete system
  PlantSpeciesInfo? _matchedSpecies;

  @override
  void initState() {
    super.initState();
    // Auto-populate expected harvest date from default category
    _expectedHarvestDate =
        estimatedHarvestDate(_category.name, _plantedDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _varietyController.dispose();
    _notesController.dispose();
    super.dispose();
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

  /// Called when user selects a species from autocomplete
  void _onSpeciesSelected(PlantSpeciesInfo species) {
    setState(() {
      _matchedSpecies = species;
      _nameController.text = species.name;
      _nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: species.name.length),
      );
      // Auto-fill category
      _category = PlantCategory.values.firstWhere(
        (c) => c.name == species.category,
        orElse: () => PlantCategory.other,
      );
    });
    _updateExpectedHarvest();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await ref
        .read(journalActionsProvider)
        .pickAndSavePhoto(source: source);
    if (path != null) {
      setState(() => _photoPath = path);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    // ─── Free tier plant limit check ─────────────────────
    final isPro = ref.read(isProProvider);
    final plants = ref.read(plantsStreamProvider).value ?? [];
    if (!isPro && plants.length >= AppConstants.freePlantLimit) {
      if (mounted) {
        context.push('/paywall?feature=Unlock%20unlimited%20plants');
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Resolve active season at save time
      final activeSeason = ref.read(activeSeasonProvider).valueOrNull;
      final seasonId =
          (_assignToActiveSeason && activeSeason != null) ? activeSeason.id : null;

      final plantId = await ref.read(plantActionsProvider).addPlant(
            name: _nameController.text.trim(),
            variety: _varietyController.text.trim().isNotEmpty
                ? _varietyController.text.trim()
                : null,
            category: _category.name,
            plantedDate: _plantedDate,
            expectedHarvestDate: _expectedHarvestDate,
            status: _status.name,
            seasonId: seasonId,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            photoUrl: _photoPath,
          );

      // Create initial journal entry with photo so thumbnail shows immediately
      if (_photoPath != null) {
        await ref.read(journalActionsProvider).addJournalEntry(
              plantId: plantId,
              date: _plantedDate,
              photoPath: _photoPath,
              note: 'Added to garden',
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text.trim()} added to garden!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plant: $e'),
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

    // Show a soft warning banner if at the limit
    final isPro = ref.watch(isProProvider);
    final plantsAsync = ref.watch(plantsStreamProvider);
    final plantCount = plantsAsync.value?.length ?? 0;
    final atLimit =
        !isPro && plantCount >= AppConstants.freePlantLimit;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Plant',
          style: theme.textTheme.titleLarge,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePlant,
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
            // Free tier limit warning
            if (atLimit) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: colorScheme.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You\'ve reached the free limit of ${AppConstants.freePlantLimit} plants. Upgrade to Pro for unlimited.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                option.daysToHarvestMin > 0
                                    ? '${option.category[0].toUpperCase()}${option.category.substring(1)} · ${option.daysToHarvestMin}-${option.daysToHarvestMax} days'
                                    : '${option.category[0].toUpperCase()}${option.category.substring(1)} · Care-only',
                                style: theme.textTheme.bodySmall?.copyWith(
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
                            message: _matchedSpecies!.daysToHarvestMin > 0
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
                    // Clear matched species if user edits away from it
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
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              items: PlantCategory.values
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(
                            cat.name[0].toUpperCase() + cat.name.substring(1)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _category = value;
                    // If user manually changes category, clear species match
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
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.timeline),
              ),
              items: PlantStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                            s.name[0].toUpperCase() + s.name.substring(1)),
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
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _plantedDate = date);
                  _updateExpectedHarvest();
                }
              },
            ),

            // Expected harvest date (auto-populated from grow data, harvestable only)
            if (isHarvestable(_category.name) && _expectedHarvestDate != null)
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
                    lastDate:
                        _plantedDate.add(const Duration(days: 365 * 5)),
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
            const SizedBox(height: 16),

            // Season assignment toggle
            Builder(
              builder: (context) {
                final activeSeason =
                    ref.watch(activeSeasonProvider).valueOrNull;
                if (activeSeason != null) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(Icons.calendar_month,
                        color: colorScheme.primary),
                    title: const Text('Assign to season'),
                    subtitle: Text(
                      activeSeason.name,
                      style: TextStyle(color: colorScheme.primary),
                    ),
                    value: _assignToActiveSeason,
                    onChanged: (v) =>
                        setState(() => _assignToActiveSeason = v),
                  );
                } else {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.calendar_month,
                        color: colorScheme.outline),
                    title: Text(
                      'No active season',
                      style: TextStyle(color: colorScheme.outline),
                    ),
                    subtitle: Text(
                      'Create one in the Seasons tab',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // Photo picker
            if (_photoPath != null)
              GestureDetector(
                onTap: _showPhotoOptions,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: Image.file(
                          File(_photoPath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Add Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Map category string to an icon for the autocomplete dropdown
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
