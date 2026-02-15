import 'package:flutter/material.dart';

/// Empty state for the chat screen — shows a welcome message
/// and suggestion chips to help the user get started.
class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({
    super.key,
    required this.onSuggestionTap,
  });

  final ValueChanged<String> onSuggestionTap;

  static const _suggestions = [
    'What should I plant this month?',
    'Why are my tomato leaves yellowing?',
    'How do I start composting?',
  ];

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
              Icons.auto_awesome,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Garden Advisor',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about your garden.\nI know your plants and the weather!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Text(
              'Try asking:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((suggestion) {
                return ActionChip(
                  label: Text(
                    suggestion,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  avatar: Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  onPressed: () => onSuggestionTap(suggestion),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
