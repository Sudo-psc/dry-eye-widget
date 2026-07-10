import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/break_stats_data.dart';
import '../models/dvrs_assessment.dart';
import '../utils/constants.dart';
import 'activity_stats_service.dart';
import 'dvrs_storage_service.dart';
import 'screen_time_service.dart';
import 'storage_service.dart';

/// Exportação e exclusão unificada de dados de saúde locais (LGPD / “Meus dados”).
///
/// Não envia nada pela rede. O JSON exportado fica no diretório de documentos
/// do usuário (ou temporário se o de documentos falhar).
class HealthDataService {
  HealthDataService({
    required this.storage,
    required this.dvrs,
    required this.screenTime,
    required this.activity,
  });

  final StorageService storage;
  final DvrsStorageService dvrs;
  final ScreenTimeService screenTime;
  final ActivityStatsService activity;

  /// Snapshot serializável de todos os dados de saúde (sem preferências de UI).
  Map<String, dynamic> buildExportMap({DateTime? now}) {
    final at = now ?? DateTime.now();
    final history = dvrs.getDvrsHistory();
    return <String, dynamic>{
      'schemaVersion': '1.0',
      'format': 'dry-eye-widget-health-export',
      'exportedAt': at.toIso8601String(),
      'appVersion': AppInfo.version,
      'instrument': {
        'id': 'DVRS',
        'version': DvrsResult.dvrsVersion,
        'role': 'educational_screening',
        'isDiagnostic': false,
      },
      'privacy': {
        'localOnly': true,
        'telemetry': false,
      },
      'dvrs': history.map((r) => r.toMap()).toList(),
      'dvrsDraft': dvrs.loadDraft(),
      'breakStats': jsonDecode(storage.loadBreakStats().toJson()),
      'screenTime': jsonDecode(screenTime.data.toJson()),
      'activityStats': jsonDecode(storage.loadActivityStats().toJson()),
      'environmentChecklist': storage.loadEnvironmentChecklist()?.toMap(),
      // Envelope OVPP-ready: métricas agregadas versionadas, opt-in no uso.
      'ovppReadyMetrics': _ovppMetrics(history, storage.loadBreakStats(), at),
    };
  }

  List<Map<String, dynamic>> _ovppMetrics(
    List<DvrsResult> history,
    BreakStatsData breaks,
    DateTime at,
  ) {
    final metrics = <Map<String, dynamic>>[];
    if (history.isNotEmpty) {
      final latest = history.last;
      metrics.add({
        'metricId': 'dvrs.total_score',
        'value': latest.totalScore,
        'unit': 'score_0_100',
        'observedAt': latest.createdAt.toIso8601String(),
        'instrumentVersion': latest.version,
      });
      for (final d in DvrsDomain.values) {
        metrics.add({
          'metricId': 'dvrs.domain.${d.id}',
          'value': latest.domainScores.valueFor(d),
          'unit': 'score_0_100',
          'observedAt': latest.createdAt.toIso8601String(),
          'instrumentVersion': latest.version,
        });
      }
    }
    final today = breaks.forDay(at);
    metrics.add({
      'metricId': 'breaks.completed_today',
      'value': today.completed,
      'unit': 'count',
      'observedAt': at.toIso8601String(),
    });
    final start7 = at.subtract(const Duration(days: 6));
    metrics.add({
      'metricId': 'breaks.adherence_7d',
      'value': breaks.adherenceForRange(start7, at),
      'unit': 'ratio_0_1',
      'observedAt': at.toIso8601String(),
    });
    return metrics;
  }

  /// Grava o JSON em arquivo local e devolve o caminho absoluto.
  Future<String> exportToFile({DateTime? now}) async {
    final map = buildExportMap(now: now);
    final pretty = const JsonEncoder.withIndent('  ').convert(map);
    final stamp = (now ?? DateTime.now())
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final dir = await _exportDir();
    final file = File('${dir.path}/dry-eye-health-export-$stamp.json');
    await file.writeAsString(pretty);
    return file.path;
  }

  Future<Directory> _exportDir() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  /// Apaga histórico de saúde; mantém preferências do widget e posição.
  Future<void> clearHealthHistory() async {
    await dvrs.clearAll();
    await dvrs.clearDraft();
    await storage.clearBreakStats();
    await screenTime.clear();
    await storage.clearActivityStats();
    await storage.clearEnvironmentChecklist();
    await storage.saveDvrsNudgeSnoozedUntil(null);
    await storage.saveDvrsNudgeNotifiedDay('');
  }

  int get dvrsResultCount => dvrs.getDvrsHistory().length;
}
