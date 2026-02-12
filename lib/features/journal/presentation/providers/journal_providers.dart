import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/database/app_database.dart';

const _uuid = Uuid();

/// Stream provider: watches all journal entries (newest first)
final journalEntriesStreamProvider =
    StreamProvider<List<JournalEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllJournalEntries();
});

/// Stream provider: watches journal entries for a specific plant
final journalEntriesForPlantProvider =
    StreamProvider.family<List<JournalEntry>, String>((ref, plantId) {
  final db = ref.watch(databaseProvider);
  return db.watchJournalEntriesForPlant(plantId);
});

/// Notifier that handles journal write operations
final journalActionsProvider = Provider<JournalActions>((ref) {
  final db = ref.watch(databaseProvider);
  return JournalActions(db);
});

class JournalActions {
  JournalActions(this._db);
  final AppDatabase _db;

  final ImagePicker _picker = ImagePicker();

  /// Pick an image from camera or gallery, save to app directory
  /// Returns the saved file path, or null if cancelled
  Future<String?> pickAndSavePhoto({
    required ImageSource source,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Save to app's documents directory for persistence
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final ext = p.extension(pickedFile.path);
      final fileName = '${_uuid.v4()}$ext';
      final savedPath = p.join(photosDir.path, fileName);

      await File(pickedFile.path).copy(savedPath);
      return savedPath;
    } catch (e) {
      return null;
    }
  }

  /// Add a new journal entry
  Future<void> addJournalEntry({
    required String plantId,
    required DateTime date,
    String? note,
    String? photoPath,
    double? weatherTemp,
    String? weatherCondition,
  }) async {
    final now = DateTime.now();
    final companion = JournalEntriesCompanion(
      id: Value(_uuid.v4()),
      plantId: Value(plantId),
      date: Value(date),
      note: Value(note),
      photoPath: Value(photoPath),
      weatherTemp: Value(weatherTemp),
      weatherCondition: Value(weatherCondition),
      createdAt: Value(now),
    );
    await _db.insertJournalEntry(companion);
  }

  /// Delete a journal entry and its photo file
  Future<void> deleteJournalEntry(String entryId, {String? photoPath}) async {
    // Delete the photo file if it exists
    if (photoPath != null) {
      try {
        final file = File(photoPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    await _db.deleteJournalEntry(entryId);
  }
}
