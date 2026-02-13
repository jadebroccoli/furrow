import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/season_providers.dart';

/// Bottom sheet dialog for logging a harvest
class LogHarvestDialog extends ConsumerStatefulWidget {
  const LogHarvestDialog({
    super.key,
    required this.plantId,
    required this.plantName,
    this.plantSeasonId,
  });

  final String plantId;
  final String plantName;

  /// Season the plant is assigned to. Used first; falls back to active season.
  final String? plantSeasonId;

  @override
  ConsumerState<LogHarvestDialog> createState() => _LogHarvestDialogState();
}

class _LogHarvestDialogState extends ConsumerState<LogHarvestDialog> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  String _unit = 'lbs';
  int _quality = 3;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a quantity'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid quantity'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Use the plant's assigned season first, then fall back to active season
    final String? seasonId = widget.plantSeasonId ??
        ref.read(activeSeasonProvider).value?.id;

    if (seasonId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Create a season first in the Seasons tab'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(seasonActionsProvider).logHarvest(
            plantId: widget.plantId,
            plantName: widget.plantName,
            seasonId: seasonId,
            date: _date,
            quantity: quantity,
            unit: _unit,
            quality: _quality,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Harvest logged for ${widget.plantName}!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
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

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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
          const SizedBox(height: 16),

          Text(
            'Log Harvest — ${widget.plantName}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Quantity + unit row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: '0.0',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: ['lbs', 'kg', 'oz', 'grams', 'count', 'bunches']
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _unit = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quality rating
          Text('Quality', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              final rating = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _quality = rating),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    rating <= _quality ? Icons.star : Icons.star_border,
                    color: rating <= _quality
                        ? const Color(0xFFFF8A00)
                        : colorScheme.outline,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Taste, size, condition...',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log Harvest'),
            ),
          ),
        ],
      ),
    );
  }
}
