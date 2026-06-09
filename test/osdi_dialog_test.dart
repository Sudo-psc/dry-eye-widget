import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/osdi_assessment.dart';
import 'package:dry_eye_widget/widgets/osdi_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OSDI salva uma avaliação respondida e mostra histórico', (
    tester,
  ) async {
    final saved = <OsdiAssessment>[];
    final history = [
      OsdiAssessment.fromAnswers(const [
        1,
        1,
        1,
        1,
        1,
        1,
        null,
        null,
        null,
        null,
        null,
        null,
      ], completedAt: DateTime.utc(2026, 6, 1)),
      OsdiAssessment.fromAnswers(const [
        3,
        3,
        3,
        3,
        3,
        3,
        null,
        null,
        null,
        null,
        null,
        null,
      ], completedAt: DateTime.utc(2026, 6, 8)),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OsdiDialog(
              strings: ptStrings,
              history: history,
              onSave: saved.add,
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(ptStrings.osdiTitle), findsOneWidget);
    expect(find.text(ptStrings.osdiHistoryTitle), findsOneWidget);

    final firstMaxOption = find.byKey(const ValueKey('osdi-q0-option-4'));
    await tester.ensureVisible(firstMaxOption);
    await tester.pump();
    await tester.tap(firstMaxOption);
    await tester.pump();
    await tester.tap(find.text(ptStrings.osdiSave));
    await tester.pump();

    expect(saved, hasLength(1));
    expect(saved.single.score, 100);
    expect(
      find.text(ptStrings.osdiScoreLabel.replaceAll('{score}', '100')),
      findsOneWidget,
    );
  });
}
