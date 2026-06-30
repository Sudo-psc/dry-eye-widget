import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/checklist.dart';
import 'package:dry_eye_widget/models/osdi_assessment.dart';
import 'package:dry_eye_widget/models/report_options.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = ReportBuilder();
  final now = DateTime(2026, 6, 21, 12);

  // Rótulos canônicos dos 12 itens OSDI (índices: 0=luz, 2=dor, 3=embaçada).
  const symptomLabels = [
    'Olhos sensíveis à luz',
    'Sensação de areia',
    'Dor ocular',
    'Visão embaçada',
    'Visão ruim',
    'Dificuldade para ler',
    'Dirigir à noite',
    'Computador',
    'TV',
    'Vento',
    'Locais secos',
    'Ar-condicionado',
  ];

  OsdiAssessment osdi(List<int?> answers, int daysAgo) =>
      OsdiAssessment.fromAnswers(answers,
          completedAt: now.subtract(Duration(days: daysAgo)));

  ReportOptions options({int days = 30}) => ReportOptions(
        startDate: now.subtract(Duration(days: days)),
        endDate: now,
        // O OSDI/sintomas viraram opcionais (DVRS é o principal); estes testes
        // cobrem a lógica legada do builder, então habilitamos explicitamente.
        includeOsdi: true,
        includeSymptoms: true,
      );

  ReportData build({
    List<OsdiAssessment>? osdiHistory,
    ScreenTimeData? screenTime,
    BreakStatsData? breakStats,
    UserProfile profile = const UserProfile(),
    int days = 30,
  }) =>
      builder.build(
        profile: profile,
        options: options(days: days),
        osdiHistory: osdiHistory ?? const [],
        screenTime: screenTime ?? ScreenTimeData.empty(),
        breakStats: breakStats ?? BreakStatsData.empty(),
        symptomLabels: symptomLabels,
        now: now,
      );

  group('OSDI', () {
    test('calcula variação absoluta e percentual entre as duas últimas', () {
      final history = [
        osdi(List.filled(12, 1), 15), // score 25
        osdi(List.filled(12, 2), 1), // score 50
      ];
      final data = build(osdiHistory: history);
      expect(data.osdi.latest!.score, closeTo(50, 0.01));
      expect(data.osdi.previous!.score, closeTo(25, 0.01));
      expect(data.osdi.variation, closeTo(25, 0.01));
      expect(data.osdi.variationPercent, closeTo(100, 0.01));
    });

    test('filtra avaliações fora do período', () {
      final history = [
        osdi(List.filled(12, 1), 100), // fora do período de 30 dias
        osdi(List.filled(12, 2), 5),
      ];
      final data = build(osdiHistory: history, days: 30);
      expect(data.osdi.history, hasLength(1));
    });
  });

  group('Tempo de tela', () {
    test('calcula média diária apenas sobre dias com dados', () {
      final st = ScreenTimeData({
        ScreenTimeData.dayKey(now): 3600,
        ScreenTimeData.dayKey(now.subtract(const Duration(days: 1))): 1800,
      });
      final data = build(screenTime: st);
      expect(data.screenTime.totalSeconds, 5400);
      expect(data.screenTime.daysWithData, 2);
      expect(data.screenTime.averageDailySeconds, 2700); // (3600+1800)/2
      expect(data.screenTime.peakDay!.seconds, 3600);
    });

    test('período sem tempo de tela retorna summary vazio', () {
      final data = build();
      expect(data.screenTime.hasData, isFalse);
      expect(data.screenTime.averageDailySeconds, 0);
    });
  });

  group('Pausas', () {
    test('calcula taxa de adesão concluídas/lembretes', () {
      final breaks = BreakStatsData.empty()
          .incremented(now, reminders: 10, completed: 8);
      final data = build(breakStats: breaks);
      expect(data.breaks.reminders, 10);
      expect(data.breaks.completed, 8);
      expect(data.breaks.skipped, 2);
      expect(data.breaks.adherenceRate, closeTo(0.8, 0.001));
    });

    test('sem pausas registradas, adesão é nula', () {
      final data = build();
      expect(data.breaks.hasData, isFalse);
      expect(data.breaks.adherenceRate, isNull);
    });
  });

  group('Sintomas', () {
    test('deriva frequência e sintoma mais frequente das respostas OSDI', () {
      // Dor (índice 2) presente nas duas avaliações; resto baixo.
      final history = [
        osdi([0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0], 10),
        osdi([0, 0, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0], 1),
      ];
      final data = build(osdiHistory: history);
      final dor = data.symptoms[2];
      expect(dor.label, 'Dor ocular');
      expect(dor.frequency, 2);
      expect(dor.averageIntensity, closeTo(3.5, 0.01));
      expect(data.topSymptom!.label, 'Dor ocular');
    });
  });

  group('Indicação e alertas', () {
    test('OSDI grave gera indicação de avaliação e alerta', () {
      final history = [osdi(List.filled(12, 4), 1)]; // score 100 (grave)
      final data = build(osdiHistory: history);
      expect(data.indication, OverallIndication.seekEvaluation);
      expect(data.alerts, isNotEmpty);
    });

    test('OSDI normal sem outros gatilhos indica acompanhar', () {
      final history = [osdi(List.filled(12, 0)..[0] = 1, 1)]; // score baixo
      final data = build(osdiHistory: history);
      expect(data.indication, OverallIndication.monitor);
    });

    test('baixa adesão sem dados clínicos indica reforçar pausas', () {
      final breaks = BreakStatsData.empty()
          .incremented(now, reminders: 10, completed: 3);
      final data = build(breakStats: breaks);
      expect(data.indication, OverallIndication.reinforceBreaks);
    });
  });

  group('Checklists', () {
    final checklist = ChecklistResult(
      id: 'c1',
      type: ChecklistType.visualSymptoms,
      createdAt: now.subtract(const Duration(days: 2)),
      answers: const [],
      totalScore: 7,
      riskLevel: ChecklistRiskLevel.attention,
      classification: 'Sinais de atenção',
      feedback: 'Considere ajustar hábitos visuais.',
      includeInPdf: true,
    );

    ReportData buildWith({
      required bool includeChecklists,
      List<ChecklistResult> checklistResults = const [],
    }) =>
        builder.build(
          profile: const UserProfile(),
          options: ReportOptions(
            startDate: now.subtract(const Duration(days: 30)),
            endDate: now,
            includeChecklists: includeChecklists,
          ),
          osdiHistory: const [],
          screenTime: ScreenTimeData.empty(),
          breakStats: BreakStatsData.empty(),
          symptomLabels: symptomLabels,
          checklistResults: checklistResults,
          now: now,
        );

    test('inclui checklists quando includeChecklists é verdadeiro', () {
      final data = buildWith(
        includeChecklists: true,
        checklistResults: [checklist],
      );
      expect(data.checklists, hasLength(1));
      expect(data.checklists.first.type, ChecklistType.visualSymptoms);
    });

    test('descarta checklists quando includeChecklists é falso', () {
      final data = buildWith(
        includeChecklists: false,
        checklistResults: [checklist],
      );
      expect(data.checklists, isEmpty);
    });
  });

  test('relatório totalmente vazio não lança e indica acompanhar', () {
    final data = build();
    expect(data.osdi.hasData, isFalse);
    expect(data.symptoms.where((s) => s.frequency > 0), isEmpty);
    expect(data.indication, OverallIndication.monitor);
    expect(data.alerts, isEmpty);
  });
}
