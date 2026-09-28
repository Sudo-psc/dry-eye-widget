import 'package:dry_eye_widget/models/break_stats_data.dart';
import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/models/dvrs_definitions.dart';
import 'package:dry_eye_widget/models/report_options.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';
import 'package:dry_eye_widget/services/pdf_report_service.dart';
import 'package:dry_eye_widget/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

DvrsResult _result({
  required String id,
  required DateTime createdAt,
  int value = 2,
}) {
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
  return evaluateDvrs(answers: answers, id: id, now: createdAt);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 6, 30);
  const builder = ReportBuilder();

  ReportData build({
    ReportOptions? options,
    List<DvrsResult> dvrsHistory = const [],
  }) =>
      builder.build(
        profile: const UserProfile(),
        options: options ??
            ReportOptions(
              startDate: now.subtract(const Duration(days: 30)),
              endDate: now,
            ),
        screenTime: ScreenTimeData.empty(),
        breakStats: BreakStatsData.empty(),
        dvrsHistory: dvrsHistory,
        now: now,
      );

  group('prepareDvrsForPdf', () {
    test('devolve null para histórico vazio', () {
      expect(prepareDvrsForPdf(const []), isNull);
    });

    test('latest é o mais recente; ordena cópia sem alterar a entrada', () {
      final c = _result(id: 'c', createdAt: DateTime(2026, 6, 3));
      final a = _result(id: 'a', createdAt: DateTime(2026, 6, 1));
      final b = _result(id: 'b', createdAt: DateTime(2026, 6, 2));
      final input = <DvrsResult>[c, a, b];

      final data = prepareDvrsForPdf(input);

      expect(data, isNotNull);
      expect(data!.latest, same(c));
      expect(data.history.map((r) => r.id).toList(), ['a', 'b', 'c']);
      expect(input.map((r) => r.id).toList(), ['c', 'a', 'b']);
      expect(data.history, isNot(same(input)));
      expect(data.hasEvolution, isTrue);
    });

    test('aceita histórico já ordenado e não modificável', () {
      final a = _result(id: 'a', createdAt: DateTime(2026, 6, 1));
      final b = _result(id: 'b', createdAt: DateTime(2026, 6, 2));
      final c = _result(id: 'c', createdAt: DateTime(2026, 6, 3));
      final input = List<DvrsResult>.unmodifiable([a, b, c]);

      final data = prepareDvrsForPdf(input);

      expect(data, isNotNull);
      expect(data!.latest, same(c));
      expect(data.history, orderedEquals([a, b, c]));
      expect(data.history, isNot(same(input)));
    });

    test('histórico único não sinaliza evolução', () {
      final only = _result(id: 'only', createdAt: DateTime(2026, 6, 1));

      final data = prepareDvrsForPdf([only]);

      expect(data, isNotNull);
      expect(data!.latest, same(only));
      expect(data.history, orderedEquals([only]));
      expect(data.hasEvolution, isFalse);
    });
  });

  group('ReportBuilder + DVRS', () {
    test('inclui DVRS por padrão quando há histórico', () {
      final data = build(dvrsHistory: [_result(id: 'a', createdAt: now)]);
      expect(data.dvrs, isNotNull);
      expect(data.dvrs!.latest.id, 'a');
    });

    test('não inclui DVRS quando includeDvrs é falso', () {
      final data = build(
        options: ReportOptions(
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
          includeDvrs: false,
        ),
        dvrsHistory: [_result(id: 'a', createdAt: now)],
      );
      expect(data.dvrs, isNull);
    });
  });

  group('PdfReportService + DVRS', () {
    final service = PdfReportService();

    test('gera PDF com a seção DVRS', () async {
      final data = build(dvrsHistory: [
        _result(id: 'a', createdAt: DateTime(2026, 6, 1), value: 1),
        _result(id: 'b', createdAt: DateTime(2026, 6, 8), value: 3),
      ]);
      final bytes = await service.generateReport(data);
      expect(bytes.length, greaterThan(100));
    });

    test('o aviso médico-legal do DVRS está definido', () {
      expect(kDvrsPdfLegalNotice, contains('confirma diagnóstico'));
      expect(kDvrsPdfLegalNotice, contains('não substitui consulta'));
    });
  });
}
