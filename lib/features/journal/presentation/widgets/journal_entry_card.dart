import 'dart:io';

import 'package:flutter/material.dart';
import '../../../../shared/widgets/furrow_card.dart';
import 'fullscreen_photo_viewer.dart';

/// Card widget displaying a journal entry in the timeline
class JournalEntryCard extends StatelessWidget {
  const JournalEntryCard({
    super.key,
    required this.plantName,
    required this.date,
    this.note,
    this.photoPath,
    this.photoCaption,
    this.weatherTemp,
    this.weatherCondition,
    this.onTap,
    this.onDelete,
  });

  final String plantName;
  final String date;
  final String? note;
  final String? photoPath;
  final String? photoCaption;
  final String? weatherTemp;
  final String? weatherCondition;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FurrowCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: plant name + date + delete
          Row(
            children: [
              Expanded(
                child: Text(
                  plantName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                date,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),

          // Photo (actual image from file — tap to fullscreen)
          if (photoPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildPhoto(context, colorScheme),
            ),
          ],

          // Note
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              note!,
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Weather info
          if (weatherTemp != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.thermostat,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '$weatherTemp${weatherCondition != null ? ' · $weatherCondition' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoto(BuildContext context, ColorScheme colorScheme) {
    final file = File(photoPath!);
    if (!file.existsSync()) {
      return _photoPlaceholder(colorScheme);
    }

    final heroTag = 'photo_$photoPath';

    return GestureDetector(
      onTap: () => openPhotoViewer(
        context,
        photoPath: photoPath!,
        heroTag: heroTag,
        caption: photoCaption,
      ),
      child: Stack(
        children: [
          Hero(
            tag: heroTag,
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    _photoPlaceholder(colorScheme),
              ),
            ),
          ),
          // Expand hint icon
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.fullscreen,
                size: 18,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(ColorScheme colorScheme) {
    return Container(
      height: 200,
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image,
        size: 48,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
