import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/dvrs_assessment.dart';
import '../utils/constants.dart';

/// Persistência local dos resultados do **DVRS** (questionário principal).
///
/// Serviço próprio sobre [SharedPreferences] — guarda todos os resultados em
/// uma única chave JSON ([StorageKeys.dvrsResults]). Os dados ficam apenas no
/// dispositivo; nada é enviado a servidores.
class DvrsStorageService {
  DvrsStorageService._(this._prefs);

  final SharedPreferences _prefs;

  /// Retenção máxima de resultados (descarta os mais antigos acima disso).
  static const int maxRetainedResults = 200;

  static Future<DvrsStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = DvrsStorageService._(prefs);
    await service._migrateLegacyPresentationFields();
    return service;
  }

  // --- Leitura interna ----------------------------------------------------

  /// Remove campos de apresentação persistidos por versões antigas.
  ///
  /// Mensagens públicas são sempre derivadas da chave semântica atual na UI ou
  /// do texto neutro atual no PDF. Assim, um payload legado não consegue
  /// reintroduzir linguagem obsoleta depois do upgrade.
  Future<void> _migrateLegacyPresentationFields() async {
    final raw = _prefs.getString(StorageKeys.dvrsResults);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      var changed = false;
      const legacyPresentationFields = <String>{
        'educationalMessage',
        'safetyAlertMessage',
      };
      for (final item in decoded) {
        if (item is Map) {
          for (final field in legacyPresentationFields) {
            if (item.containsKey(field)) {
              item.remove(field);
              changed = true;
            }
          }
        }
      }
      if (changed) {
        await _prefs.setString(StorageKeys.dvrsResults, jsonEncode(decoded));
      }
    } catch (_) {
      // Mantém a política existente: payload integralmente corrompido é
      // ignorado na leitura, sem substituir dados que possam ser recuperados.
    }
  }

  List<DvrsResult> _readAll() {
    final raw = _prefs.getString(StorageKeys.dvrsResults);
    if (raw == null || raw.isEmpty) return <DvrsResult>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <DvrsResult>[];
      final results = <DvrsResult>[];
      for (final item in decoded) {
        if (item is Map) {
          try {
            results.add(DvrsResult.fromMap(Map<String, dynamic>.from(item)));
          } catch (_) {
            // Ignora entradas corrompidas isoladas.
          }
        }
      }
      return results;
    } catch (_) {
      return <DvrsResult>[];
    }
  }

  Future<void> _writeAll(List<DvrsResult> results) async {
    final sorted = [...results]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final trimmed = sorted.length <= maxRetainedResults
        ? sorted
        : sorted.sublist(sorted.length - maxRetainedResults);
    final encoded = jsonEncode(trimmed.map((r) => r.toMap()).toList());
    await _prefs.setString(StorageKeys.dvrsResults, encoded);
  }

  // --- API pública --------------------------------------------------------

  /// Salva um resultado. Se já existir um com o mesmo [DvrsResult.id], ele é
  /// substituído.
  Future<void> saveDvrsResult(DvrsResult result) async {
    final all = _readAll()..removeWhere((r) => r.id == result.id);
    all.add(result);
    await _writeAll(all);
  }

  /// Histórico ordenado por data (mais antigo → mais recente).
  List<DvrsResult> getDvrsHistory() {
    final all = _readAll()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List<DvrsResult>.unmodifiable(all);
  }

  /// Resultado mais recente, ou `null` se não houver.
  DvrsResult? getLatestDvrsResult() {
    final history = getDvrsHistory();
    return history.isEmpty ? null : history.last;
  }

  /// Remove o resultado com o [id] informado.
  Future<void> deleteDvrsResult(String id) async {
    final all = _readAll()..removeWhere((r) => r.id == id);
    await _writeAll(all);
  }

  /// Apaga todo o histórico do DVRS.
  Future<void> clearAll() => _prefs.remove(StorageKeys.dvrsResults);

  // --- Rascunho parcial (DVRS 1.1) ----------------------------------------

  /// Mapa perguntaId → índice da opção (0–4), ou vazio se não houver rascunho.
  Map<String, int> loadDraft() {
    final raw = _prefs.getString(StorageKeys.dvrsDraft);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, int>{};
      decoded.forEach((key, value) {
        if (key is String && value is num) {
          out[key] = value.toInt().clamp(0, 4);
        }
      });
      return out;
    } catch (_) {
      return const {};
    }
  }

  Future<void> saveDraft(Map<String, int> selected) async {
    if (selected.isEmpty) {
      await clearDraft();
      return;
    }
    await _prefs.setString(StorageKeys.dvrsDraft, jsonEncode(selected));
  }

  Future<void> clearDraft() => _prefs.remove(StorageKeys.dvrsDraft);

  bool get hasDraft => loadDraft().isNotEmpty;
}
