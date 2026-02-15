import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/ai_service.dart';
import '../../../garden/presentation/providers/plant_providers.dart';
import '../../../seasons/presentation/providers/season_providers.dart';

const _uuid = Uuid();

/// Stream provider: watches all chat messages from Drift (ASC order)
final chatMessagesProvider = StreamProvider<List<AiChatMessage>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllChatMessages();
});

/// Tracks whether a message is currently being sent
final chatSendingProvider = StateProvider<bool>((ref) => false);

/// Chat actions — handles sending messages and clearing history
final chatActionsProvider = Provider<ChatActions>((ref) {
  final db = ref.watch(databaseProvider);
  final aiService = ref.watch(aiServiceProvider);
  return ChatActions(db, aiService, ref);
});

class ChatActions {
  ChatActions(this._db, this._aiService, this._ref);

  final AppDatabase _db;
  final AiService _aiService;
  final Ref _ref;

  /// Send a message and get an AI response.
  /// Returns null on success, or an error message string on failure.
  Future<String?> sendMessage(String message) async {
    // 1. Insert user message immediately (optimistic)
    final userMessageId = _uuid.v4();
    await _db.insertChatMessage(AiChatMessagesCompanion(
      id: Value(userMessageId),
      role: const Value('user'),
      content: Value(message),
      createdAt: Value(DateTime.now()),
    ));

    // 2. Gather garden context
    final context = await _buildContext();

    // 3. Get recent history for conversation context
    final recentMessages = await _db.getRecentChatMessages(10);
    final history = recentMessages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    // 4. Call AI service
    final response = await _aiService.sendMessage(
      message: message,
      context: context,
      history: history,
    );

    // 5. Check for errors
    if (response.startsWith('Error:')) {
      return response.substring(7).trim();
    }

    // 6. Insert AI response
    await _db.insertChatMessage(AiChatMessagesCompanion(
      id: Value(_uuid.v4()),
      role: const Value('assistant'),
      content: Value(response),
      createdAt: Value(DateTime.now()),
    ));

    return null;
  }

  /// Clear all chat history.
  Future<void> clearHistory() async {
    await _db.clearChatHistory();
  }

  /// Build garden context from current app state.
  Future<Map<String, dynamic>> _buildContext() async {
    final context = <String, dynamic>{};

    // Active season
    final season = _ref.read(activeSeasonProvider).valueOrNull;
    if (season != null) {
      context['season'] = season.name;
    }

    // Current plants
    final plants = _ref.read(plantsStreamProvider).valueOrNull;
    if (plants != null && plants.isNotEmpty) {
      context['plants'] = plants.take(20).map((p) {
        final daysSincePlanted =
            DateTime.now().difference(p.plantedDate).inDays;
        return {
          'name': p.name,
          if (p.variety != null) 'species': p.variety,
          'plantedDate': p.plantedDate.toIso8601String().split('T')[0],
          'status': p.status,
          'daysSincePlanted': daysSincePlanted,
        };
      }).toList();
    }

    return context;
  }
}
