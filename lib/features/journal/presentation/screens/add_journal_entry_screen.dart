import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../../garden/presentation/providers/plant_providers.dart';
import '../providers/journal_providers.dart';

/// Screen to add a new journal entry for a plant
/// Can be opened from the Journal tab (pick a plant) or from Plant Detail (pre-selected)
class AddJournalEntryScreen extends ConsumerStatefulWidget {
  const AddJournalEntryScreen({
    super.key,
    this.preselectedPlantId,
  });

  /// If coming from Plant Detail, the plant is pre-selected
  final String? preselectedPlantId;

  @override
  ConsumerState<AddJournalEntryScreen> createState() =>
      _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState
    extends ConsumerState<AddJournalEntryScreen> {
  final _noteController = TextEditingController();

  String? _selectedPlantId;
  String? _photoPath;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPlantId = widget.preselectedPlantId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path =
        await ref.read(journalActionsProvider).pickAndSavePhoto(source: source);
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
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text('Remove Photo',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

  Future<void> _save() async {
    if (_selectedPlantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a plant'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Require at least a note or a photo
    if (_noteController.text.trim().isEmpty && _photoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a note or photo to save'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(journalActionsProvider).addJournalEntry(
            plantId: _selectedPlantId!,
            date: _date,
            note: _noteController.text.trim().isNotEmpty
                ? _noteController.text.trim()
                : null,
            photoPath: _photoPath,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry added!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
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
    final plantsAsync = ref.watch(plantsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Journal Entry', style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plant selector
          plantsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error loading plants: $e'),
            data: (plants) {
              if (plants.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Add a plant first before creating journal entries.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              }

              return DropdownButtonFormField<String>(
                value: _selectedPlantId,
                decoration: const InputDecoration(
                  labelText: 'Select Plant',
                  prefixIcon: Icon(Icons.eco),
                ),
                hint: const Text('Which plant is this for?'),
                items: plants
                    .map((plant) => DropdownMenuItem(
                          value: plant.id,
                          child: Text(
                            plant.variety != null && plant.variety!.isNotEmpty
                                ? '${plant.name} (${plant.variety})'
                                : plant.name,
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedPlantId = value);
                },
              );
            },
          ),
          const SizedBox(height: 16),

          // Date picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(
              '${_date.month}/${_date.day}/${_date.year}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _date = date);
              }
            },
          ),
          const SizedBox(height: 16),

          // Photo section
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Container(
              height: _photoPath != null ? 240 : 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: _photoPath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            File(_photoPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                colorScheme.surface.withValues(alpha: 0.8),
                            child: IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: _showPhotoOptions,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 36,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add a photo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Note
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Observation / Note',
              hintText: 'How does it look? Any changes?',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
