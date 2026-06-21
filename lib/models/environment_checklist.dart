import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Classificação do ambiente de trabalho visual.
enum EnvironmentRisk { adequate, attention, increased }

/// Checklist ambiental autorreferido (opcional) usado no relatório.
///
/// Cada campo representa um fator. Os campos `*Ok` indicam ergonomia adequada
/// (`true` = ok); os demais indicam a presença de um fator de risco
/// (`true` = fator presente). A classificação soma os pontos de risco.
@immutable
class EnvironmentChecklist {
  const EnvironmentChecklist({
    required this.updatedAt,
    this.screenDistanceOk = true,
    this.monitorHeightOk = true,
    this.brightnessOk = true,
    this.contrastOk = true,
    this.lightingOk = true,
    this.glare = false,
    this.airConditioning = false,
    this.dryAir = false,
    this.multiMonitor = false,
    this.homeOffice = false,
    this.fanOnFace = false,
  });

  final DateTime updatedAt;

  // Ergonomia (true = adequado)
  final bool screenDistanceOk;
  final bool monitorHeightOk;
  final bool brightnessOk;
  final bool contrastOk;
  final bool lightingOk;

  // Fatores de risco (true = presente)
  final bool glare; // reflexo na tela
  final bool airConditioning;
  final bool dryAir; // ambiente seco / baixa umidade
  final bool multiMonitor;
  final bool homeOffice;
  final bool fanOnFace; // ventilador direcionado ao rosto

  /// Pontos de risco: ergonomia inadequada + fatores presentes.
  int get riskPoints {
    var points = 0;
    if (!screenDistanceOk) points++;
    if (!monitorHeightOk) points++;
    if (!brightnessOk) points++;
    if (!contrastOk) points++;
    if (!lightingOk) points++;
    if (glare) points++;
    if (airConditioning) points++;
    if (dryAir) points++;
    if (multiMonitor) points++;
    if (homeOffice) points++;
    if (fanOnFace) points++;
    return points;
  }

  EnvironmentRisk get risk {
    final p = riskPoints;
    if (p <= 1) return EnvironmentRisk.adequate;
    if (p <= 3) return EnvironmentRisk.attention;
    return EnvironmentRisk.increased;
  }

  EnvironmentChecklist copyWith({
    DateTime? updatedAt,
    bool? screenDistanceOk,
    bool? monitorHeightOk,
    bool? brightnessOk,
    bool? contrastOk,
    bool? lightingOk,
    bool? glare,
    bool? airConditioning,
    bool? dryAir,
    bool? multiMonitor,
    bool? homeOffice,
    bool? fanOnFace,
  }) =>
      EnvironmentChecklist(
        updatedAt: updatedAt ?? this.updatedAt,
        screenDistanceOk: screenDistanceOk ?? this.screenDistanceOk,
        monitorHeightOk: monitorHeightOk ?? this.monitorHeightOk,
        brightnessOk: brightnessOk ?? this.brightnessOk,
        contrastOk: contrastOk ?? this.contrastOk,
        lightingOk: lightingOk ?? this.lightingOk,
        glare: glare ?? this.glare,
        airConditioning: airConditioning ?? this.airConditioning,
        dryAir: dryAir ?? this.dryAir,
        multiMonitor: multiMonitor ?? this.multiMonitor,
        homeOffice: homeOffice ?? this.homeOffice,
        fanOnFace: fanOnFace ?? this.fanOnFace,
      );

  Map<String, dynamic> toMap() => {
        'updatedAt': updatedAt.toIso8601String(),
        'screenDistanceOk': screenDistanceOk,
        'monitorHeightOk': monitorHeightOk,
        'brightnessOk': brightnessOk,
        'contrastOk': contrastOk,
        'lightingOk': lightingOk,
        'glare': glare,
        'airConditioning': airConditioning,
        'dryAir': dryAir,
        'multiMonitor': multiMonitor,
        'homeOffice': homeOffice,
        'fanOnFace': fanOnFace,
      };

  String toJson() => jsonEncode(toMap());

  static bool _b(Object? v, bool fallback) => v is bool ? v : fallback;

  factory EnvironmentChecklist.fromMap(Map<String, dynamic> m) =>
      EnvironmentChecklist(
        updatedAt:
            DateTime.tryParse(m['updatedAt'] as String? ?? '') ?? DateTime(2000),
        screenDistanceOk: _b(m['screenDistanceOk'], true),
        monitorHeightOk: _b(m['monitorHeightOk'], true),
        brightnessOk: _b(m['brightnessOk'], true),
        contrastOk: _b(m['contrastOk'], true),
        lightingOk: _b(m['lightingOk'], true),
        glare: _b(m['glare'], false),
        airConditioning: _b(m['airConditioning'], false),
        dryAir: _b(m['dryAir'], false),
        multiMonitor: _b(m['multiMonitor'], false),
        homeOffice: _b(m['homeOffice'], false),
        fanOnFace: _b(m['fanOnFace'], false),
      );

  /// Decodifica um JSON salvo; retorna `null` se ausente ou inválido.
  static EnvironmentChecklist? fromJson(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return null;
      return EnvironmentChecklist.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}
