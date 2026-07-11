import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/widgets/dvrs/dvrs_history_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

DvrsResult _result() {
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
        value: 1,
        label: 'opt',
      ),
  ];
  return evaluateDvrs(
    answers: answers,
    id: 'result-1',
    now: DateTime(2026, 7, 11),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('exclusão de resultado DVRS exige confirmação', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final appStorage = await StorageService.init();
    final dvrsStorage = await DvrsStorageService.init();
    await dvrsStorage.saveDvrsResult(_result());
    final settings = SettingsProvider(storage: appStorage);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<DvrsStorageService>.value(value: dvrsStorage),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: const MaterialApp(home: Scaffold(body: DvrsHistoryView())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dvrs_delete_result-1')));
    await tester.pumpAndSettle();

    expect(find.text('Excluir este resultado do DVRS?'), findsOneWidget);
    expect(dvrsStorage.getDvrsHistory(), hasLength(1));

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(dvrsStorage.getDvrsHistory(), hasLength(1));

    await tester.tap(find.byKey(const ValueKey('dvrs_delete_result-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(dvrsStorage.getDvrsHistory(), isEmpty);
  });
}
