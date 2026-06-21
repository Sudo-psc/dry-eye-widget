import 'package:flutter/material.dart';

import '../../models/checklist.dart';

/// Helpers visuais compartilhados pelos widgets de Checklists.
///
/// Centraliza a tradução de [ChecklistRiskLevel] e [ChecklistTrend] em
/// rótulo + ícone + cor, garantindo que a cor NUNCA seja o único indicador
/// (sempre acompanhada de texto e ícone) e que a linguagem seja de triagem.
class ChecklistUi {
  const ChecklistUi._();

  /// Rótulo curto, não-diagnóstico, para um nível de risco.
  static String riskLabel(ChecklistRiskLevel level) {
    switch (level) {
      case ChecklistRiskLevel.low:
        return 'Baixo risco';
      case ChecklistRiskLevel.attention:
        return 'Atenção';
      case ChecklistRiskLevel.increased:
        return 'Risco aumentado';
      case ChecklistRiskLevel.recommendedEvaluation:
        return 'Avaliação recomendada';
      case ChecklistRiskLevel.urgentAttention:
        return 'Atenção prioritária';
    }
  }

  /// Ícone associado ao nível (reforça o significado sem depender da cor).
  static IconData riskIcon(ChecklistRiskLevel level) {
    switch (level) {
      case ChecklistRiskLevel.low:
        return Icons.check_circle_outline;
      case ChecklistRiskLevel.attention:
        return Icons.info_outline;
      case ChecklistRiskLevel.increased:
        return Icons.warning_amber_outlined;
      case ChecklistRiskLevel.recommendedEvaluation:
        return Icons.medical_services_outlined;
      case ChecklistRiskLevel.urgentAttention:
        return Icons.priority_high;
    }
  }

  /// Cor (apoio visual, nunca o único indicador).
  static Color riskColor(ChecklistRiskLevel level) {
    switch (level) {
      case ChecklistRiskLevel.low:
        return Colors.green;
      case ChecklistRiskLevel.attention:
        return Colors.orange;
      case ChecklistRiskLevel.increased:
        return Colors.deepOrange;
      case ChecklistRiskLevel.recommendedEvaluation:
        return Colors.red;
      case ChecklistRiskLevel.urgentAttention:
        return Colors.red.shade700;
    }
  }

  /// Chip de risco: ícone + texto + cor, com `Semantics` descritivo.
  static Widget riskChip(ChecklistRiskLevel level, {bool dense = false}) {
    final color = riskColor(level);
    final label = riskLabel(level);
    return Semantics(
      label: 'Nível de risco: $label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(riskIcon(level), size: dense ? 14 : 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: dense ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rótulo da tendência de evolução.
  static String trendLabel(ChecklistTrend trend) {
    switch (trend) {
      case ChecklistTrend.improving:
        return 'Em melhora';
      case ChecklistTrend.stable:
        return 'Estável';
      case ChecklistTrend.worsening:
        return 'Em piora';
    }
  }

  static IconData trendIcon(ChecklistTrend trend) {
    switch (trend) {
      case ChecklistTrend.improving:
        return Icons.trending_down; // menos pontos = melhora
      case ChecklistTrend.stable:
        return Icons.trending_flat;
      case ChecklistTrend.worsening:
        return Icons.trending_up;
    }
  }

  static Color trendColor(ChecklistTrend trend) {
    switch (trend) {
      case ChecklistTrend.improving:
        return Colors.green;
      case ChecklistTrend.stable:
        return Colors.blueGrey;
      case ChecklistTrend.worsening:
        return Colors.orange;
    }
  }

  /// Aviso fixo de não-diagnóstico usado em todos os fluxos.
  static const String disclaimer =
      'Este resultado não substitui consulta médica e não realiza diagnóstico.';

  /// Banner de aviso reutilizável.
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

  /// Formata uma data como dd/MM/aaaa.
  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
