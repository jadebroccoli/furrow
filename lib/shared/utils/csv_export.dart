import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/database/app_database.dart';
import '../../features/garden/presentation/providers/plant_providers.dart';
import '../../features/seasons/presentation/providers/season_providers.dart';

/// Exports all plants and harvests as a CSV file and opens the share sheet.
Future<void> exportCsv(WidgetRef ref) async {
  final dateFormat = DateFormat('yyyy-MM-dd');

  // ── Plants CSV ──────────────────────────────────────────
  final plants = ref.read(plantsStreamProvider).value ?? <Plant>[];

  final plantCsv = StringBuffer();
  plantCsv.writeln(
      'id,name,variety,category,planted_date,expected_harvest,status,notes');

  for (final p in plants) {
    plantCsv.writeln([
      _esc(p.id),
      _esc(p.name),
      _esc(p.variety ?? ''),
      _esc(p.category),
      dateFormat.format(p.plantedDate),
      p.expectedHarvestDate != null
          ? dateFormat.format(p.expectedHarvestDate!)
          : '',
      _esc(p.status),
      _esc(p.notes ?? ''),
    ].join(','));
  }

  // ── Harvests CSV ────────────────────────────────────────
  final harvests = ref.read(allHarvestsProvider).value ?? <Harvest>[];

  final harvestCsv = StringBuffer();
  harvestCsv.writeln(
      'id,plant_id,plant_name,season_id,date,quantity,unit,quality,notes');

  // Build a plant name lookup for convenience column
  final plantNames = <String, String>{};
  for (final p in plants) {
    plantNames[p.id] = p.name;
  }

  for (final h in harvests) {
    final name = h.plantName ?? plantNames[h.plantId] ?? 'Unknown';
    harvestCsv.writeln([
      _esc(h.id),
      _esc(h.plantId),
      _esc(name),
      _esc(h.seasonId),
      dateFormat.format(h.date),
      h.quantity.toStringAsFixed(2),
      _esc(h.unit),
      h.quality.toString(),
      _esc(h.notes ?? ''),
    ].join(','));
  }

  // ── Write to temp files and share ──────────────────────
  final dir = await getTemporaryDirectory();
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  final plantsFile =
      File('${dir.path}/furrow_plants_$timestamp.csv');
  final harvestsFile =
      File('${dir.path}/furrow_harvests_$timestamp.csv');

  await plantsFile.writeAsString(plantCsv.toString());
  await harvestsFile.writeAsString(harvestCsv.toString());

  await Share.shareXFiles(
    [
      XFile(plantsFile.path, mimeType: 'text/csv'),
      XFile(harvestsFile.path, mimeType: 'text/csv'),
    ],
    subject: 'Furrow Export — $timestamp',
  );
}

/// Escape a CSV field (wrap in quotes if it contains comma, quote, or newline)
String _esc(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
