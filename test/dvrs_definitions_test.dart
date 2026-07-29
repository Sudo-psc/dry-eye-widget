import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/models/dvrs_definitions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kDvrsQuestions', () {
    test('tem exatamente 16 perguntas', () {
      expect(kDvrsQuestions.length, 16);
    });

    test('ids são q1..q16 e únicos', () {
      final ids = kDvrsQuestions.map((q) => q.id).toList();
      expect(ids.toSet().length, 16);
      for (var i = 0; i < 16; i++) {
        expect(ids[i], 'q${i + 1}');
      }
    });

    test('distribuição por domínio: 6/3/3/3/1', () {
      int count(DvrsDomain d) =>
          kDvrsQuestions.where((q) => q.domain == d).length;
      expect(count(DvrsDomain.symptoms), 6);
      expect(count(DvrsDomain.functional), 3);
      expect(count(DvrsDomain.exposure), 3);
      expect(count(DvrsDomain.environment), 3);
      expect(count(DvrsDomain.warning), 1);
    });

    test('ordem canônica dos domínios por índice', () {
      for (var i = 0; i < 16; i++) {
        final expected = i < 6
            ? DvrsDomain.symptoms
            : i < 9
            ? DvrsDomain.functional
            : i < 12
            ? DvrsDomain.exposure
            : i < 15
            ? DvrsDomain.environment
            : DvrsDomain.warning;
        expect(kDvrsQuestions[i].domain, expected, reason: 'q${i + 1}');
      }
    });

    test('cada pergunta tem 5 opções com scores 0..4', () {
      for (final q in kDvrsQuestions) {
        expect(q.options.length, 5, reason: q.id);
        final scores = q.options.map((o) => o.score).toList();
        expect(scores, [0, 1, 2, 3, 4], reason: q.id);
        for (final o in q.options) {
          expect(o.label.trim(), isNotEmpty, reason: q.id);
        }
      }
    });

    test('enunciados e títulos não-vazios', () {
      for (final q in kDvrsQuestions) {
        expect(q.title.trim(), isNotEmpty, reason: q.id);
        expect(q.text.trim(), isNotEmpty, reason: q.id);
      }
    });

    test('chaves semânticas cobrem integralmente o questionário PT/EN', () {
      final pt = FeatureStrings.of('pt');
      final en = FeatureStrings.of('en');

      expect(en.dvrsQuestionInstructions, isNot(pt.dvrsQuestionInstructions));
      expect(en.dvrsAnsweredProgress(3, 16), '3 of 16 answered');
      expect(en.dvrsQuestionNumber(7), 'Question 7');
      for (final question in kDvrsQuestions) {
        expect(pt.dvrsQuestionTitle(question.id), question.title);
        expect(pt.dvrsQuestionPrompt(question.id), question.text);
        expect(
          en.dvrsQuestionTitle(question.id),
          isNot(equals(question.title)),
          reason: '${question.id} title',
        );
        expect(
          en.dvrsQuestionPrompt(question.id),
          isNot(equals(question.text)),
          reason: '${question.id} prompt',
        );
        for (var i = 0; i < question.options.length; i++) {
          expect(pt.dvrsOptionLabel(question.id, i), question.options[i].label);
          expect(
            en.dvrsOptionLabel(question.id, i).trim(),
            isNotEmpty,
            reason: '${question.id} option $i',
          );
        }
      }
    });

    test('linguagem não-diagnóstica em todo o conteúdo visível', () {
      const proibidos = [
        'diagnóstico de olho seco',
        'você tem olho seco',
        'resultado clínico',
        'tratamento indicado',
        'score diagnóstico',
        'produtividade comprometida',
        'o app detecta doença',
      ];
      final buffer = StringBuffer()
        ..writeAll(
          kDvrsQuestions.map((q) => '${q.title} ${q.text} ${q.detail ?? ''}'),
        )
        ..write(kDvrsPdfEducationalMessage)
        ..writeAll(
          DvrsSafetyAlertLevel.values.map(
            (level) => FeatureStrings.of('pt').dvrsSafetyMessage(level) ?? '',
          ),
        )
        ..write(kDvrsIntroDescription)
        ..write(kDvrsIntroDisclaimer)
        ..write(kDvrsPdfLegalNotice);
      final text = buffer.toString().toLowerCase();
      for (final termo in proibidos) {
        expect(text.contains(termo), isFalse, reason: 'contém "$termo"');
      }
    });
  });
}
