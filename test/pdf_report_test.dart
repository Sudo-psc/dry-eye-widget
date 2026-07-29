import 'dart:async';

import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/models/environment_checklist.dart';
import 'package:dry_eye_widget/models/report_options.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';
import 'package:dry_eye_widget/services/pdf_report_service.dart';
import 'package:dry_eye_widget/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const builder = ReportBuilder();
  final service = PdfReportService();
  final now = DateTime(2026, 6, 21, 12);

  DvrsResult dvrs(int value, {int daysAgo = 1, String id = 'r'}) {
    final answers = [
      for (var i = 0; i < 16; i++)
        DvrsAnswer(
          questionId: 'q${i + 1}',
          domain: i < 6
              ? DvrsDomain.symptoms
              : i < 9
              ? DvrsDomain.functional
              : i < 12
              ? DvrsDomain.exposure
              : i < 15
              ? DvrsDomain.environment
              : DvrsDomain.warning,
          value: value,
          label: 'opt',
        ),
    ];
    return evaluateDvrs(
      answers: answers,
      id: id,
      now: now.subtract(Duration(days: daysAgo)),
    );
  }

  ReportData build({
    List<DvrsResult> dvrsHistory = const [],
    ScreenTimeData? screenTime,
    BreakStatsData? breakStats,
    ReportOptions? options,
    UserProfile profile = const UserProfile(),
    EnvironmentChecklist? environment,
  }) => builder.build(
    profile: profile,
    options:
        options ??
        ReportOptions(
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
        ),
    screenTime: screenTime ?? ScreenTimeData.empty(),
    breakStats: breakStats ?? BreakStatsData.empty(),
    environment: environment,
    dvrsHistory: dvrsHistory,
    now: now,
  );

  Future<int> sizeOf(ReportData data) async =>
      (await service.generateReport(data)).length;

  group('PdfReportService.generateReport', () {
    test('gera PDF com todos os dados', () async {
      final data = build(
        profile: const UserProfile(
          name: 'Teste Silva',
          observations: 'Piora à tarde.',
        ),
        dvrsHistory: [
          dvrs(1, daysAgo: 15, id: 'a'),
          dvrs(3, daysAgo: 1, id: 'b'),
        ],
        screenTime: ScreenTimeData({ScreenTimeData.dayKey(now): 3600}),
        breakStats: BreakStatsData.empty().incremented(
          now,
          reminders: 8,
          completed: 6,
        ),
      );
      expect(await sizeOf(data), greaterThan(1000));
    });

    test('embute fontes para texto Unicode sem avisos de glifos', () async {
      final messages = <String>[];
      final data = build(
        profile: const UserProfile(
          name: 'José “Teste”',
          observations: 'Visão — melhor após a pausa 20–20–20.',
        ),
      );

      final bytes = await runZoned(
        () => service.generateReport(data),
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, message) => messages.add(message),
        ),
      );

      expect(bytes.length, greaterThan(1000));
      expect(
        messages.where(
          (message) =>
              message.contains('no Unicode support') ||
              message.contains('Unable to find a font'),
        ),
        isEmpty,
      );
    });

    test('gera PDF sem dados (período vazio) sem lançar', () async {
      expect(await sizeOf(build()), greaterThan(100));
    });

    test('gera PDF sem DVRS mas com tempo de tela', () async {
      final data = build(
        screenTime: ScreenTimeData({ScreenTimeData.dayKey(now): 7200}),
      );
      expect(data.dvrs, isNull);
      expect(await sizeOf(data), greaterThan(100));
    });

    test(
      'gera PDF com a seção DVRS (inclui alerta prioritário da Q16)',
      () async {
        final data = build(dvrsHistory: [dvrs(4)]);
        expect(data.dvrs, isNotNull);
        expect(
          data.dvrs!.latest.safetyAlertLevel,
          DvrsSafetyAlertLevel.priorityEvaluation,
        );
        expect(await sizeOf(data), greaterThan(100));
      },
    );

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

    test('ambiente não entra quando includeEnvironment é falso', () async {
      final data = build(
        environment: EnvironmentChecklist(updatedAt: now, glare: true),
      );
      expect(data.environment, isNull);
    });
  });

  test('constantes médico-legais obrigatórias presentes', () {
    expect(
      PdfReportService.legalFooter,
      contains('constitui diagnóstico'),
      reason: 'rodapé deve negar caráter diagnóstico',
    );
    expect(
      PdfReportService.privacyNotice,
      contains('informações pessoais de saúde'),
    );
    expect(
      PdfReportService.dvrsEducationalMessage,
      contains('perfil por domínio'),
    );
    expect(
      PdfReportService.dvrsEducationalMessage.toLowerCase(),
      isNot(contains('risco visual digital')),
    );
  });
}
