import 'package:dry_eye_widget/models/checklist.dart';
import 'package:dry_eye_widget/models/checklist_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Termos proibidos (linguagem diagnóstica), case-insensitive.
const List<String> _forbiddenTerms = [
  'diagnóstico',
  'diagnostico',
  'você tem olho seco',
  'voce tem olho seco',
  'tratamento indicado',
  'normal/anormal',
];

void main() {
  group('ids estáveis e parse reverso', () {
    test('ChecklistType: todos os 7 têm id e parse reverso', () {
      expect(ChecklistType.values, hasLength(7));
      for (final type in ChecklistType.values) {
        expect(type.id, isNotEmpty);
        expect(ChecklistTypeId.fromId(type.id), type);
      }
      expect(ChecklistTypeId.fromId('desconhecido'), isNull);
    });

    test('ids esperados', () {
      expect(ChecklistType.visualErgonomics.id, 'visual_ergonomics');
      expect(ChecklistType.screenEnvironment.id, 'screen_environment');
      expect(ChecklistType.visualSymptoms.id, 'visual_symptoms');
      expect(ChecklistType.warningSigns.id, 'warning_signs');
      expect(ChecklistType.breakHabits.id, 'break_habits');
      expect(ChecklistType.ophthalmologyTriage.id, 'ophthalmology_triage');
      expect(ChecklistType.visualRiskSummary.id, 'visual_risk_summary');
    });

    test('ChecklistRiskLevel: todos têm id e parse reverso', () {
      for (final level in ChecklistRiskLevel.values) {
        expect(level.id, isNotEmpty);
        expect(ChecklistRiskLevelId.fromId(level.id), level);
      }
      expect(ChecklistRiskLevelId.fromId('xpto'), isNull);
    });
  });

  group('registro de definições (módulos 1-5)', () {
    test('contém exatamente os 5 módulos de questionário', () {
      expect(kChecklistDefinitions.keys, containsAll([
        ChecklistType.visualErgonomics,
        ChecklistType.screenEnvironment,
        ChecklistType.visualSymptoms,
        ChecklistType.warningSigns,
        ChecklistType.breakHabits,
      ]));
      expect(kChecklistDefinitions.length, 5);
      // Módulos 6 e 7 NÃO entram no registro.
      expect(
        kChecklistDefinitions.containsKey(ChecklistType.ophthalmologyTriage),
        isFalse,
      );
      expect(
        kChecklistDefinitions.containsKey(ChecklistType.visualRiskSummary),
        isFalse,
      );
    });

    test('cada definição tem perguntas, opções e faixas', () {
      for (final def in kChecklistDefinitions.values) {
        expect(def.title, isNotEmpty);
        expect(def.questions, isNotEmpty);
        expect(def.bands, isNotEmpty);
        for (final q in def.questions) {
          expect(q.id, isNotEmpty);
          expect(q.options, isNotEmpty);
        }
      }
    });

    test('faixas cobrem o intervalo de score sem buracos', () {
      for (final def in kChecklistDefinitions.values) {
        final bands = [...def.bands]
          ..sort((a, b) => a.minScore.compareTo(b.minScore));
        // Começa em 0.
        expect(bands.first.minScore, 0,
            reason: '${def.type.id}: primeira faixa deve começar em 0');
        // Contígua: cada faixa começa logo após a anterior.
        for (var i = 1; i < bands.length; i++) {
          expect(bands[i].minScore, bands[i - 1].maxScore + 1,
              reason: '${def.type.id}: faixa $i deve ser contígua');
        }
        // Última faixa aberta à direita (cobre score máximo possível).
        final maxPossible = def.questions.fold<int>(0, (sum, q) {
          final maxOpt =
              q.options.map((o) => o.score).reduce((a, b) => a > b ? a : b);
          return sum + maxOpt;
        });
        expect(bands.last.maxScore, greaterThanOrEqualTo(maxPossible),
            reason: '${def.type.id}: última faixa deve cobrir o score máximo');
      }
    });
  });

  group('linguagem não-diagnóstica', () {
    test('nenhum feedback/classification contém termos proibidos', () {
      final texts = <String>[];
      for (final def in kChecklistDefinitions.values) {
        texts.add(def.title);
        texts.add(def.shortDescription);
        for (final band in def.bands) {
          texts.add(band.classification);
          texts.add(band.feedback);
        }
        for (final q in def.questions) {
          texts.add(q.text);
          for (final o in q.options) {
            texts.add(o.label);
          }
        }
      }
      // Inclui as constantes de alerta crítico.
      texts.add(kWarningSignsUrgentClassification);
      texts.add(kWarningSignsUrgentFeedback);

      for (final text in texts) {
        final lower = text.toLowerCase();
        for (final term in _forbiddenTerms) {
          expect(lower.contains(term), isFalse,
              reason: 'Termo proibido "$term" encontrado em: "$text"');
        }
      }
    });
  });
}
