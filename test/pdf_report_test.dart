import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/models/osdi_assessment.dart';
import 'package:dry_eye_widget/models/report_options.dart';
import 'package:dry_eye_widget/models/screen_time_data.dart';
import 'package:dry_eye_widget/services/pdf_report_service.dart';

void main() {
  group('PdfReportService', () {
    test('generateReport não deve falhar mesmo com dados vazios', () async {
      final data = ReportData(
        profile: const UserProfile(),
        options: ReportOptions(
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        ),
        osdiHistory: [],
        screenTimeData: ScreenTimeData.empty(),
      );

      final service = PdfReportService();
      final pdfBytes = await service.generateReport(data);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(100)); // Pelo menos um header de PDF válido
    });

    test('generateReport deve gerar PDF com dados mockados', () async {
      final now = DateTime.now();
      
      final history = [
        OsdiAssessment.fromAnswers(
          [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // score ~ 25
          completedAt: now.subtract(const Duration(days: 15)),
        ),
        OsdiAssessment.fromAnswers(
          [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3], // score ~ 75
          completedAt: now,
        ),
      ];

      final stData = ScreenTimeData({'${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}': 3600});

      final data = ReportData(
        profile: const UserProfile(name: 'Teste Silva', observations: 'Sinto piora.'),
        options: ReportOptions(
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
        ),
        osdiHistory: history,
        screenTimeData: stData,
        latestOsdi: history.last,
        previousOsdi: history.first,
        averageScreenTimeSeconds: 3600,
        totalScreenTimeSeconds: 3600,
      );

      final service = PdfReportService();
      final pdfBytes = await service.generateReport(data);

      expect(pdfBytes, isNotEmpty);
    });
  });
}
