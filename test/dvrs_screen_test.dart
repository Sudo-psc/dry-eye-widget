import 'package:dry_eye_widget/models/dvrs_definitions.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
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
  final appStorage = await StorageService.init();
  final settings = SettingsProvider(storage: appStorage);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<DvrsStorageService>.value(value: storage),
        Provider<StorageService>.value(value: appStorage),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ],
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
    expect(
      find.text('Registro educativo de sintomas e hábitos'),
      findsOneWidget,
    );
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

  testWidgets('mantém somente a vizinhança visível do questionário montada', (
    tester,
  ) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();

    final mountedQuestions = kDvrsQuestions.where((question) {
      return find
          .byKey(ValueKey<String>('dvrs_question_${question.id}'))
          .evaluate()
          .isNotEmpty;
    }).length;

    expect(mountedQuestions, lessThanOrEqualTo(4));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('dvrs_question_q16')),
      500,
    );
    await tester.pumpAndSettle();
    final retainedQuestions = kDvrsQuestions.where((question) {
      return find
          .byKey(ValueKey<String>('dvrs_question_${question.id}'))
          .evaluate()
          .isNotEmpty;
    }).length;

    expect(retainedQuestions, lessThanOrEqualTo(4));
  });

  testWidgets('leva à primeira pergunta não respondida antes de calcular', (
    tester,
  ) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();

    final firstCard = find.byKey(const ValueKey<String>('dvrs_question_q1'));
    await tester.tap(
      find.descendant(of: firstCard, matching: find.text('Nunca')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('dvrs_question_q16')),
      500,
    );
    await tester.tap(find.text('Calcular resultado'));
    await tester.pumpAndSettle();

    expect(find.textContaining('15 perguntas não respondidas'), findsOneWidget);
    final secondCard = find.byKey(const ValueKey<String>('dvrs_question_q2'));
    expect(tester.getRect(secondCard).top, lessThan(250));
    expect(find.text('Perfil por domínio'), findsNothing);
  });

  testWidgets('fluxo completo calcula e exibe resultado', (tester) async {
    await _pumpScreen(tester, storage);
    await tester.tap(find.text('Iniciar DVRS'));
    await tester.pumpAndSettle();

    await _answerAll(tester, optionIndex: 0);

    expect(find.text('16 de 16 respondidas'), findsOneWidget);
    await tester.tap(find.text('Calcular resultado'));
    await tester.pumpAndSettle();

    // Tudo na opção 0 => perfil educativo de baixa carga relatada.
    expect(find.text('Registro educativo de sintomas e hábitos'), findsWidgets);
    expect(find.text('Perfil por domínio'), findsOneWidget);
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
