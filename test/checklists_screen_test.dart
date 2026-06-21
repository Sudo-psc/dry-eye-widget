import 'package:dry_eye_widget/services/checklist_storage_service.dart';
import 'package:dry_eye_widget/services/screen_time_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/widgets/checklists/checklists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;
  late ScreenTimeService screenTime;
  late ChecklistStorageService checklistStorage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.init();
    screenTime = ScreenTimeService(storage: storage);
    checklistStorage = await ChecklistStorageService.init();
  });

  Widget wrap() => MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storage),
          Provider<ChecklistStorageService>.value(value: checklistStorage),
          ChangeNotifierProvider<ScreenTimeService>.value(value: screenTime),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChecklistsScreen(onClose: () {}),
          ),
        ),
      );

  // Janela alta para que as listas roláveis (lazy) construam todos os itens.
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('exibe os 7 cards de checklists', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Ergonomia visual'), findsOneWidget);
    expect(find.text('Ambiente de tela'), findsOneWidget);
    expect(find.text('Sintomas visuais'), findsOneWidget);
    expect(find.text('Sinais de alerta'), findsOneWidget);
    expect(find.text('Pausas e hábitos'), findsOneWidget);
    expect(find.text('Triagem oftalmológica'), findsOneWidget);
    expect(find.text('Resumo de risco visual'), findsOneWidget);
  });

  testWidgets(
    'abre ergonomia, responde, calcula e mostra resultado sem termos proibidos',
    (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Abre o checklist de ergonomia visual.
      await tester.tap(find.text('Ergonomia visual'));
      await tester.pumpAndSettle();

      // O aviso não-diagnóstico deve estar presente.
      expect(
        find.textContaining('não substitui consulta médica'),
        findsWidgets,
      );

      // Responde a primeira pergunta tocando em uma opção "Sim".
      final simOption = find.text('Sim').first;
      await tester.ensureVisible(simOption);
      await tester.tap(simOption);
      await tester.pumpAndSettle();

      // Calcula o resultado (botão fica após as 12 perguntas; rola até ele).
      final calc = find.text('Calcular resultado');
      await tester.scrollUntilVisible(
        calc,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(calc);
      await tester.pumpAndSettle();

      // O resultado mostra os botões de salvar e o aviso permanece.
      expect(find.text('Salvar'), findsOneWidget);
      expect(find.text('Incluir no PDF'), findsOneWidget);
      expect(
        find.textContaining('não substitui consulta médica'),
        findsWidgets,
      );

      // Linguagem proibida (afirmativa/diagnóstica) não pode aparecer.
      expect(find.textContaining('você tem olho seco'), findsNothing);
      expect(find.textContaining('tratamento indicado'), findsNothing);
      // A palavra "diagnóstico" só pode aparecer no aviso que a NEGA
      // ("não realiza diagnóstico"); nunca como afirmação isolada.
      final diagnosisFinder = find.textContaining('diagnóstico');
      for (final element in diagnosisFinder.evaluate()) {
        final widget = element.widget;
        if (widget is Text) {
          expect(
            widget.data,
            contains('não'),
            reason: 'A palavra "diagnóstico" deve sempre vir negada.',
          );
        }
      }
    },
  );
}
