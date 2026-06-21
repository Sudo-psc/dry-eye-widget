import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/environment_checklist.dart';
import 'package:dry_eye_widget/models/osdi_assessment.dart';
import 'package:dry_eye_widget/models/report_options.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/services/pdf_report_service.dart';
import 'package:dry_eye_widget/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = ReportBuilder();
  final service = PdfReportService();
  final now = DateTime(2026, 6, 21, 12);

  const symptomLabels = [
    'Luz', 'Areia', 'Dor', 'Embaçada', 'Visão ruim', 'Ler',
    'Dirigir', 'Computador', 'TV', 'Vento', 'Seco', 'Ar-condicionado',
  ];

  ReportData build({
    List<OsdiAssessment> osdiHistory = const [],
    ScreenTimeData? screenTime,
    BreakStatsData? breakStats,
    ReportOptions? options,
    UserProfile profile = const UserProfile(),
    EnvironmentChecklist? environment,
  }) =>
      builder.build(
        profile: profile,
        options: options ??
            ReportOptions(
              startDate: now.subtract(const Duration(days: 30)),
              endDate: now,
            ),
        osdiHistory: osdiHistory,
        screenTime: screenTime ?? ScreenTimeData.empty(),
        breakStats: breakStats ?? BreakStatsData.empty(),
        symptomLabels: symptomLabels,
        environment: environment,
        now: now,
      );

  Future<int> sizeOf(ReportData data) async =>
      (await service.generateReport(data)).length;

  group('PdfReportService.generateReport', () {
    test('gera PDF com todos os dados', () async {
      final history = [
        OsdiAssessment.fromAnswers(List.filled(12, 1),
            completedAt: now.subtract(const Duration(days: 15))),
        OsdiAssessment.fromAnswers(List.filled(12, 3), completedAt: now),
      ];
      final data = build(
        profile: const UserProfile(
            name: 'Teste Silva', observations: 'Piora à tarde.'),
        osdiHistory: history,
        screenTime: ScreenTimeData({ScreenTimeData.dayKey(now): 3600}),
        breakStats: BreakStatsData.empty()
            .incremented(now, reminders: 8, completed: 6),
      );
      expect(await sizeOf(data), greaterThan(1000));
    });

    test('gera PDF sem dados (período vazio) sem lançar', () async {
      expect(await sizeOf(build()), greaterThan(100));
    });

    test('gera PDF sem OSDI mas com tempo de tela', () async {
      final data = build(
        screenTime: ScreenTimeData({ScreenTimeData.dayKey(now): 7200}),
      );
      expect(await sizeOf(data), greaterThan(100));
    });

    test('gera PDF sem tempo de tela mas com OSDI', () async {
      final data = build(
        osdiHistory: [
          OsdiAssessment.fromAnswers(List.filled(12, 2), completedAt: now),
        ],
      );
      expect(await sizeOf(data), greaterThan(100));
    });

    test('gera PDF com checklist ambiental incluído', () async {
      final data = build(
        options: ReportOptions(
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
          includeEnvironment: true,
        ),
        environment: EnvironmentChecklist(
          updatedAt: now,
          glare: true,
          airConditioning: true,
          dryAir: true,
          screenDistanceOk: false,
        ),
      );
      expect(data.environment, isNotNull);
      expect(data.environment!.risk, EnvironmentRisk.increased);
      expect(await sizeOf(data), greaterThan(100));
    });

    test('checklist não entra quando includeEnvironment é falso', () async {
      final data = build(
        environment: EnvironmentChecklist(updatedAt: now, glare: true),
      );
      expect(data.environment, isNull);
    });

    test('gera PDF sem sintomas quando includeSymptoms é falso', () async {
      final data = build(
        options: ReportOptions(
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
          includeSymptoms: false,
        ),
        osdiHistory: [
          OsdiAssessment.fromAnswers(List.filled(12, 2), completedAt: now),
        ],
      );
      expect(data.symptoms, isEmpty);
      expect(await sizeOf(data), greaterThan(100));
    });
  });

  test('constantes médico-legais obrigatórias presentes', () {
    expect(PdfReportService.legalFooter, contains('constitui diagnóstico'),
        reason: 'rodapé deve negar caráter diagnóstico');
    expect(PdfReportService.osdiDisclaimer, contains('OSDI'));
    expect(PdfReportService.privacyNotice, contains('informações pessoais de saúde'));
  });
}
