import 'package:dry_eye_widget/models/dvrs_definitions.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/widgets/dvrs/dvrs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpScreen(
  WidgetTester tester,
  DvrsStorageService storage, {
  VoidCallback? onClose,
}) async {
  await tester.pumpWidget(
    Provider<DvrsStorageService>.value(
      value: storage,
      child: MaterialApp(
        home: DvrsScreen(onClose: onClose ?? () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Responde as 16 perguntas escolhendo a opção [optionIndex] em cada uma e
/// avançando até a revisão.
Future<void> _answerAll(WidgetTester tester, {int optionIndex = 0}) async {
  for (var i = 0; i < kDvrsQuestions.length; i++) {
    final option = kDvrsQuestions[i].options[optionIndex].label;
    await tester.tap(find.text(option));
    await tester.pump();
    final nextLabel = i == kDvrsQuestions.length - 1 ? 'Revisar' : 'Próxima';
    await tester.tap(find.text(nextLabel));
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DvrsStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await DvrsStorageService.init();
  });

  testWidgets('tela inicial exibe nome, aviso e botão iniciar', (tester) async {
    await _pumpScreen(tester, storage);
    expect(find.text('Índice de Risco Visual Digital'), findsOneWidget);
    expect(find.text('Iniciar DVRS'), findsOneWidget);
    expect(find.textContaining('não substitui'), findsWidgets);
  });

  testWidgets('inicia o questionário e mostra progresso 1 de 16',
      (tester) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();
    expect(find.text('Pergunta 1 de 16'), findsOneWidget);
  });

  testWidgets('não avança enquanto a pergunta não é respondida', (tester) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();
    final proxima = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Próxima'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(proxima.onPressed, isNull);
  });

  testWidgets('fluxo completo calcula e exibe resultado', (tester) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();

    await _answerAll(tester, optionIndex: 0);

    // Na revisão, calcular.
    expect(find.text('Revise suas respostas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Calcular resultado'), 200);
    await tester.tap(find.text('Calcular resultado'));
    await tester.pumpAndSettle();

    // Tudo na opção 0 => score 0 => baixo risco.
    expect(find.text('Baixo risco visual digital'), findsWidgets);
    expect(find.text('Scores por domínio'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Salvar resultado'), 200);
    expect(find.text('Salvar resultado'), findsOneWidget);
  });

  testWidgets('salvar resultado persiste no histórico', (tester) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();
    await _answerAll(tester, optionIndex: 0);
    await tester.scrollUntilVisible(find.text('Calcular resultado'), 200);
    await tester.tap(find.text('Calcular resultado'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Salvar resultado'), 200);
    await tester.tap(find.text('Salvar resultado'));
    await tester.pumpAndSettle();

    expect(storage.getDvrsHistory(), hasLength(1));
  });
}
