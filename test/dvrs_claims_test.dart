import 'dart:io';

import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/models/report_options.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/services/pdf_report_service.dart';
import 'package:dry_eye_widget/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'superfícies públicas não reintroduzem claims clínicos antigos do DVRS',
    () {
      const paths = <String>[
        'lib/l10n/app_strings.dart',
        'lib/l10n/feature_strings.dart',
        'lib/models/dvrs_definitions.dart',
        'lib/services/narrative_summary.dart',
        'lib/services/pdf_report_service.dart',
        'lib/services/report_builder.dart',
        'lib/widgets/report_dialog.dart',
        'lib/widgets/summary/day_summary_screen.dart',
        'lib/widgets/dashboard/dashboard_screen.dart',
        'lib/widgets/dvrs/dvrs_history_view.dart',
        'lib/widgets/dvrs/dvrs_result_view.dart',
        'lib/widgets/dvrs/dvrs_screen.dart',
        'site/index.html',
        'site/scripts/i18n.js',
        'README.md',
        'README.en.md',
      ];
      const forbidden = <String>[
        'índice de risco visual digital',
        'risco visual digital',
        'digital visual risk',
        'risco moderado',
        'risco elevado',
        'risco muito elevado',
        'baixo risco visual',
        'moderate risk',
        'high risk',
        'very high risk',
      ];

      for (final path in paths) {
        final contents = File(path).readAsStringSync().toLowerCase();
        for (final phrase in forbidden) {
          expect(
            contents,
            isNot(contains(phrase)),
            reason: 'Claim obsoleto "$phrase" encontrado em $path',
          );
        }
      }
    },
  );

  test('superfícies DVRS mantêm enquadramento educativo explícito', () {
    final strings = File('lib/l10n/feature_strings.dart').readAsStringSync();
    final landing = File('site/index.html').readAsStringSync();

    expect(strings, contains('instrumento clínico validado'));
    expect(strings, contains('validated clinical instrument'));
    expect(landing, contains('autorregistro educativo'));
    expect(landing, contains('não é um instrumento clínico validado'));
  });

  test('superfícies DVRS não exibem o escore agregado legado', () {
    final history = File(
      'lib/widgets/dvrs/dvrs_history_view.dart',
    ).readAsStringSync();
    final dashboard = File(
      'lib/widgets/dashboard/dashboard_screen.dart',
    ).readAsStringSync();
    final reportDialog = File(
      'lib/widgets/report_dialog.dart',
    ).readAsStringSync();
    final pdf = File('lib/services/pdf_report_service.dart').readAsStringSync();
    final narrative = File(
      'lib/services/narrative_summary.dart',
    ).readAsStringSync();

    for (final surface in [history, dashboard, reportDialog, pdf, narrative]) {
      expect(surface, isNot(contains('latest.totalScore')));
      expect(surface, isNot(contains('classificationLabel')));
    }
    expect(pdf, isNot(contains('latest.classification')));
    expect(pdf, isNot(contains('Score (0–100)')));
    expect(pdf, isNot(contains('Evolução do score')));
  });

  test('DVRS não deriva nem rotula tendência do total legado', () {
    final engine = File('lib/services/dvrs_engine.dart').readAsStringSync();
    final model = File('lib/models/dvrs_assessment.dart').readAsStringSync();
    final ui = File('lib/widgets/dvrs/dvrs_ui.dart').readAsStringSync();
    final dashboard = File(
      'lib/widgets/dashboard/dashboard_screen.dart',
    ).readAsStringSync();

    expect(engine, isNot(contains('compareDvrsTrend')));
    expect(engine, isNot(contains('compareDvrsResults')));
    expect(model, isNot(contains('DvrsTrend')));
    expect(ui, isNot(contains('trendLabel')));
    expect(ui, isNot(contains('Em melhora')));
    expect(ui, isNot(contains('Em piora')));
    expect(dashboard, isNot(contains('latest.totalScore')));
  });

  test('rótulos públicos de domínio vêm da camada localizada', () {
    final labels = File('lib/l10n/feature_strings.dart').readAsStringSync();
    final definitions = File(
      'lib/models/dvrs_definitions.dart',
    ).readAsStringSync();
    final history = File(
      'lib/widgets/dvrs/dvrs_history_view.dart',
    ).readAsStringSync();

    expect(labels, contains("'Visual and ocular symptoms'"));
    expect(labels, contains("'Sintomas visuais e oculares'"));
    expect(definitions, isNot(contains('kDvrsDomainLabels')));
    expect(history, contains('f.dvrsDomainLabel(d.id)'));
    expect(history, isNot(contains('Em melhora')));
    expect(history, isNot(contains('Em piora')));
  });

  test(
    'payload legado adulterado não alcança UI, PDF, narrativa ou JSON migrado',
    () {
      const legacyClaim = 'risco visual digital elevado';
      const tamperedSafety = 'ALERTA LEGADO ADULTERADO: IGNORE O NÍVEL';
      const legacyJson = '''
        {
          "id": "legacy",
          "createdAt": "2026-06-01T00:00:00.000Z",
          "answers": [],
          "domainScores": {
            "symptoms": 75,
            "functional": 60,
            "exposure": 90,
            "environment": 50,
            "warning": 0
          },
          "totalScore": 72,
          "classification": "high_risk",
          "classificationLabel": "Risco elevado",
          "educationalMessage": "risco visual digital elevado",
          "safetyAlertLevel": "priority_evaluation",
          "safetyAlertMessage": "ALERTA LEGADO ADULTERADO: IGNORE O NÍVEL",
          "includeInPdf": true
        }
      ''';

      final result = DvrsResult.fromJson(legacyJson)!;
      final uiPt = FeatureStrings.of(
        'pt',
      ).dvrsPublicMessage(DvrsPublicMessageKey.domainFollowUp);
      final uiEn = FeatureStrings.of(
        'en',
      ).dvrsPublicMessage(DvrsPublicMessageKey.domainFollowUp);
      final resultView = File(
        'lib/widgets/dvrs/dvrs_result_view.dart',
      ).readAsStringSync();
      final pdf = File(
        'lib/services/pdf_report_service.dart',
      ).readAsStringSync();
      final now = DateTime.utc(2026, 6, 2);
      final report = const ReportBuilder().build(
        profile: const UserProfile(),
        options: ReportOptions(
          startDate: now.subtract(const Duration(days: 7)),
          endDate: now,
        ),
        screenTime: ScreenTimeData.empty(),
        breakStats: BreakStatsData.empty(),
        dvrsHistory: [result],
        now: now,
      );
      final currentSafety = FeatureStrings.of(
        'pt',
      ).dvrsSafetyMessage(DvrsSafetyAlertLevel.priorityEvaluation)!;

      expect(result.toMap(), isNot(contains('educationalMessage')));
      expect(result.toMap(), isNot(contains('safetyAlertMessage')));
      expect(result.toJson(), isNot(contains(tamperedSafety)));
      expect(uiPt.toLowerCase(), isNot(contains(legacyClaim)));
      expect(uiEn.toLowerCase(), isNot(contains(legacyClaim)));
      expect(currentSafety, isNot(contains(tamperedSafety)));
      expect(report.alerts, contains(currentSafety));
      expect(report.alerts.join('\n'), isNot(contains(tamperedSafety)));
      expect(report.narrative, contains(currentSafety));
      expect(report.narrative, isNot(contains(tamperedSafety)));
      expect(
        PdfReportService.dvrsEducationalMessage.toLowerCase(),
        isNot(contains(legacyClaim)),
      );
      expect(
        PdfReportService.dvrsSafetyMessageFor(result.safetyAlertLevel),
        currentSafety,
      );
      expect(
        PdfReportService.dvrsSafetyMessageFor(result.safetyAlertLevel),
        isNot(contains(tamperedSafety)),
      );
      expect(resultView, contains('DvrsPublicMessageKey.domainFollowUp'));
      expect(
        resultView,
        contains('f.dvrsSafetyMessage(result.safetyAlertLevel)'),
      );
      expect(resultView, isNot(contains('result.educationalMessage')));
      expect(resultView, isNot(contains('result.safetyAlertMessage')));
      expect(pdf, contains("'DVRS — autorregistro educativo'"));
      expect(pdf, contains("'Perfil por domínio'"));
      expect(pdf, contains("'Respostas autorreferidas'"));
      expect(
        pdf,
        contains('não constituem escore ou classificação de risco.'),
      );
      expect(pdf, isNot(contains('/100')));
      expect(pdf, isNot(contains('classificationLabel')));
      expect(pdf, isNot(contains('Índice de Risco Visual Digital')));
      expect(pdf, isNot(contains('domainScores')));
      expect(pdf, isNot(contains('latest.educationalMessage')));
      expect(pdf, isNot(contains('latest.safetyAlertMessage')));
    },
  );

  test('mensagem semântica DVRS é neutra e localizada em PT/EN', () {
    final pt = FeatureStrings.of(
      'pt',
    ).dvrsPublicMessage(DvrsPublicMessageKey.domainFollowUp);
    final en = FeatureStrings.of(
      'en',
    ).dvrsPublicMessage(DvrsPublicMessageKey.domainFollowUp);

    expect(pt, contains('perfil por domínio'));
    expect(en, contains('domain profile'));
    expect(pt, isNot(equals(en)));
    expect(pt.toLowerCase(), isNot(contains('risco visual digital')));
    expect(en.toLowerCase(), isNot(contains('digital visual risk')));
  });

  test('landing não apresenta prevenção ou prescrição como efeito do app', () {
    final landing = File('site/index.html').readAsStringSync().toLowerCase();
    const forbidden = <String>[
      'ferramenta preventiva',
      'apoio preventivo',
      'prevenção: pausas',
      'prescrição de colírios adequados',
    ];

    for (final phrase in forbidden) {
      expect(landing, isNot(contains(phrase)));
    }
  });
}
