import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/checklist.dart';
import '../utils/constants.dart';

/// Persistência local dos resultados dos checklists de saúde visual digital.
///
/// Serviço próprio sobre [SharedPreferences] — NÃO estende [StorageService]
/// para não interferir no fake usado nos testes. Guarda todos os resultados em
/// uma única chave JSON ([StorageKeys.checklistResults]).
class ChecklistStorageService {
  ChecklistStorageService._(this._prefs);

  final SharedPreferences _prefs;

  /// Retenção máxima de resultados (descarta os mais antigos acima disso).
  static const int maxRetainedResults = 200;

  static Future<ChecklistStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return ChecklistStorageService._(prefs);
  }

  // --- Leitura interna ----------------------------------------------------

  List<ChecklistResult> _readAll() {
    final raw = _prefs.getString(StorageKeys.checklistResults);
    if (raw == null || raw.isEmpty) return <ChecklistResult>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <ChecklistResult>[];
      final results = <ChecklistResult>[];
      for (final item in decoded) {
        if (item is Map) {
          try {
            results.add(
              ChecklistResult.fromMap(Map<String, dynamic>.from(item)),
            );
          } catch (_) {
            // Ignora entradas corrompidas isoladas.
          }
        }
      }
      return results;
    } catch (_) {
      return <ChecklistResult>[];
    }
  }

  Future<void> _writeAll(List<ChecklistResult> results) async {
    final sorted = [...results]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final trimmed = sorted.length <= maxRetainedResults
        ? sorted
        : sorted.sublist(sorted.length - maxRetainedResults);
    final encoded = jsonEncode(trimmed.map((r) => r.toMap()).toList());
    await _prefs.setString(StorageKeys.checklistResults, encoded);
  }

  // --- API pública --------------------------------------------------------

  /// Salva um resultado. Se já existir um com o mesmo [ChecklistResult.id],
  /// ele é substituído.
  Future<void> saveChecklistResult(ChecklistResult result) async {
    final all = _readAll()..removeWhere((r) => r.id == result.id);
    all.add(result);
    await _writeAll(all);
  }

  /// Histórico de resultados ordenado por data (mais antigo → mais recente).
  /// Filtra por [type] quando informado.
  List<ChecklistResult> getChecklistHistory({ChecklistType? type}) {
    final all = _readAll()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final filtered =
        type == null ? all : all.where((r) => r.type == type).toList();
    return List<ChecklistResult>.unmodifiable(filtered);
  }

  /// Resultado mais recente de um [type], ou `null` se não houver.
  ChecklistResult? latestByType(ChecklistType type) {
    final history = getChecklistHistory(type: type);
    return history.isEmpty ? null : history.last;
  }

  /// Remove o resultado com o [id] informado.
  Future<void> deleteChecklistResult(String id) async {
    final all = _readAll()..removeWhere((r) => r.id == id);
    await _writeAll(all);
  }

  /// Apaga todo o histórico de checklists.
  Future<void> clearAll() => _prefs.remove(StorageKeys.checklistResults);
}
