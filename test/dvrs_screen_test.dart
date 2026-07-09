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
      child: MaterialApp(home: DvrsScreen(onClose: onClose ?? () {})),
    ),
  );
  await tester.pumpAndSettle();
}

/// Responde as 16 perguntas escolhendo a opção [optionIndex] em cada uma.
Future<void> _answerAll(WidgetTester tester, {int optionIndex = 0}) async {
  for (final question in kDvrsQuestions) {
    final card = find.byKey(ValueKey<String>('dvrs_question_${question.id}'));
    await tester.scrollUntilVisible(card, 500);
    await tester.pumpAndSettle();
    final option = find.descendant(
      of: card,
      matching: find.text(question.options[optionIndex].label),
    );
    await tester.tap(option);
    await tester.pump();
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

  testWidgets('inicia o questionário em página única com progresso', (
    tester,
  ) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();
    expect(find.text('0 de 16 respondidas'), findsOneWidget);
    expect(
      find.text('Olhos secos, sensação de areia ou corpo estranho'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('dvrs_question_q16')),
      500,
    );
    expect(
      find.text('Sinais que merecem avaliação oftalmológica'),
      findsOneWidget,
    );
  });

  testWidgets('não calcula enquanto todas as perguntas não forem respondidas', (
    tester,
  ) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();
    final calcular = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Calcular resultado'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(calcular.onPressed, isNull);
  });

  testWidgets('fluxo completo calcula e exibe resultado', (tester) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();

    await _answerAll(tester, optionIndex: 0);

    expect(find.text('16 de 16 respondidas'), findsOneWidget);
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
    await tester.tap(find.text('Calcular resultado'));
    await tester.pumpAndSettle();

    final saveLabel = find.text('Salvar resultado');
    await tester.scrollUntilVisible(saveLabel, 200);
    final saveButton = find.ancestor(
      of: saveLabel,
      matching: find.byType(FilledButton),
    );
    await tester.tapAt(tester.getTopLeft(saveButton) + const Offset(16, 8));
    await tester.pumpAndSettle();

    expect(storage.getDvrsHistory(), hasLength(1));
  });
}
