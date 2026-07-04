import 'package:flutter/material.dart';

import '../../models/dvrs_assessment.dart';

/// Helpers visuais compartilhados pelos widgets do DVRS.
///
/// Centraliza a tradução de [DvrsClassification], [DvrsSafetyAlertLevel] e
/// [DvrsTrend] em rótulo + ícone + cor — a cor NUNCA é o único indicador
/// (sempre acompanhada de texto e ícone). Linguagem sempre de triagem.
class DvrsUi {
  const DvrsUi._();

  /// Cor de apoio da classificação (nunca o único indicador).
  static Color classificationColor(DvrsClassification c) {
    switch (c) {
      case DvrsClassification.low:
        return Colors.green;
      case DvrsClassification.mildAttention:
        return Colors.orange;
      case DvrsClassification.moderateRisk:
        return Colors.deepOrange;
      case DvrsClassification.highRisk:
        return Colors.red;
      case DvrsClassification.veryHighRisk:
        return Colors.red.shade700;
    }
  }

  static IconData classificationIcon(DvrsClassification c) {
    switch (c) {
      case DvrsClassification.low:
        return Icons.check_circle_outline;
      case DvrsClassification.mildAttention:
        return Icons.info_outline;
      case DvrsClassification.moderateRisk:
        return Icons.warning_amber_outlined;
      case DvrsClassification.highRisk:
        return Icons.medical_services_outlined;
      case DvrsClassification.veryHighRisk:
        return Icons.priority_high;
    }
  }

  /// Chip de classificação: ícone + rótulo + cor, com `Semantics`.
  static Widget classificationChip(DvrsClassification c) {
    final color = classificationColor(c);
    final label = c.label;
    return Semantics(
      label: 'Classificação: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(classificationIcon(c), size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Alerta de segurança ------------------------------------------------

  static Color safetyColor(DvrsSafetyAlertLevel level) {
    switch (level) {
      case DvrsSafetyAlertLevel.none:
        return Colors.green;
      case DvrsSafetyAlertLevel.attention:
        return Colors.orange;
      case DvrsSafetyAlertLevel.medicalEvaluation:
        return Colors.red;
      case DvrsSafetyAlertLevel.priorityEvaluation:
        return Colors.red.shade700;
    }
  }

  static IconData safetyIcon(DvrsSafetyAlertLevel level) {
    switch (level) {
      case DvrsSafetyAlertLevel.none:
        return Icons.check_circle_outline;
      case DvrsSafetyAlertLevel.attention:
        return Icons.info_outline;
      case DvrsSafetyAlertLevel.medicalEvaluation:
        return Icons.medical_services_outlined;
      case DvrsSafetyAlertLevel.priorityEvaluation:
        return Icons.priority_high;
    }
  }

  /// Banner do alerta de segurança (destaque visual sem tom alarmista).
  /// Devolve `null` quando não há alerta.
  static Widget? safetyBanner(DvrsSafetyAlertLevel level, String? message) {
    if (level == DvrsSafetyAlertLevel.none || message == null) return null;
    final color = safetyColor(level);
    final priority = level == DvrsSafetyAlertLevel.priorityEvaluation;
    return Semantics(
      label: 'Alerta de segurança',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: priority ? 0.8 : 0.5),
            width: priority ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(safetyIcon(level), color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: color,
                  fontWeight: priority ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tendência ----------------------------------------------------------

  static String trendLabel(DvrsTrend trend) {
    switch (trend) {
      case DvrsTrend.improving:
        return 'Em melhora';
      case DvrsTrend.stable:
        return 'Estável';
      case DvrsTrend.worsening:
        return 'Em piora';
    }
  }

  static IconData trendIcon(DvrsTrend trend) {
    switch (trend) {
      case DvrsTrend.improving:
        return Icons.trending_down; // menos pontos = melhora
      case DvrsTrend.stable:
        return Icons.trending_flat;
      case DvrsTrend.worsening:
        return Icons.trending_up;
    }
  }

  static Color trendColor(DvrsTrend trend) {
    switch (trend) {
      case DvrsTrend.improving:
        return Colors.green;
      case DvrsTrend.stable:
        return Colors.blueGrey;
      case DvrsTrend.worsening:
        return Colors.orange;
    }
  }

  /// Aviso fixo de não-diagnóstico.
  static const String disclaimer =
      'Este resultado é educativo, não confirma diagnóstico e não substitui '
      'avaliação oftalmológica.';

  static Widget disclaimerBanner(ThemeData theme, {String? text}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text ?? disclaimer,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      );

  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Cores das 5 faixas de classificação em ordem (0–19 … 80–100).
  static List<Color> get classificationSegments => [
        for (final c in DvrsClassification.values) classificationColor(c),
      ];

  /// Barra de risco 0–100 com marcador na posição do [score].
  static Widget riskBar(DvrsClassification classification, int score) {
    final color = classificationColor(classification);
    return Semantics(
      label: 'Score $score de 100',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final pos = (score / 100).clamp(0.0, 1.0) * width;
          return SizedBox(
            height: 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.green,
                        Colors.orange,
                        Colors.deepOrange,
                        Colors.red,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: (pos - 6).clamp(0.0, width - 12),
                  child: Container(
                    width: 12,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
