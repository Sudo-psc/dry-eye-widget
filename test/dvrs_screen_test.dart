import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/models/dvrs_definitions.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/widgets/dvrs/dvrs_result_view.dart';
import 'package:dry_eye_widget/widgets/dvrs/dvrs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _semanticsWidget(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  DvrsStorageService storage, {
  VoidCallback? onClose,
  String languageCode = 'pt',
}) async {
  final appStorage = await StorageService.init();
  final settings = SettingsProvider(storage: appStorage);
  await settings.update(settings.value.copyWith(languageCode: languageCode));
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
Future<void> _answerAll(
  WidgetTester tester, {
  int optionIndex = 0,
  String languageCode = 'pt',
}) async {
  final f = FeatureStrings.of(languageCode);
  for (final question in kDvrsQuestions) {
    final card = find.byKey(ValueKey<String>('dvrs_question_${question.id}'));
    await tester.scrollUntilVisible(card, 500);
    await tester.pumpAndSettle();
    final option = find.descendant(
      of: card,
      matching: find.text(f.dvrsOptionLabel(question.id, optionIndex)),
    );
    await tester.tap(option);
    await tester.pump();
  }
}

DvrsResult _resultForAlert(DvrsSafetyAlertLevel expectedLevel) {
  final warningValue = switch (expectedLevel) {
    DvrsSafetyAlertLevel.none => 0,
    DvrsSafetyAlertLevel.attention => 2,
    DvrsSafetyAlertLevel.medicalEvaluation => 3,
    DvrsSafetyAlertLevel.priorityEvaluation => 4,
  };
  final answers = <DvrsAnswer>[
    for (final question in kDvrsQuestions)
      DvrsAnswer(
        questionId: question.id,
        domain: question.domain,
        value: question.id == 'q16' ? warningValue : 0,
        label: 'semantic-key-test',
      ),
  ];
  final result = evaluateDvrs(
    answers: answers,
    id: 'alert-${expectedLevel.name}',
    now: DateTime.utc(2026, 7, 29),
  );
  assert(result.safetyAlertLevel == expectedLevel);
  return result;
}

Future<void> _pumpResult(
  WidgetTester tester, {
  required String languageCode,
  required DvrsResult result,
}) async {
  final appStorage = await StorageService.init();
  final settings = SettingsProvider(storage: appStorage);
  await settings.update(settings.value.copyWith(languageCode: languageCode));
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: DvrsResultView(result: result)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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

  testWidgets('questionário integral usa textos e acessibilidade em inglês', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final f = FeatureStrings.of('en');
    await _pumpScreen(tester, storage, languageCode: 'en');

    expect(find.text(f.dvrsIntroTitle), findsOneWidget);
    expect(find.text('Start DVRS'), findsOneWidget);
    await tester.tap(find.text('Start DVRS'));
    await tester.pumpAndSettle();

    expect(find.text('0 of 16 answered'), findsOneWidget);
    expect(find.text('Question 1'), findsOneWidget);
    expect(find.text(f.dvrsQuestionTitle('q1')), findsOneWidget);
    expect(find.text(f.dvrsQuestionPrompt('q1')), findsOneWidget);
    expect(find.text(f.dvrsOptionLabel('q1', 0)), findsOneWidget);
    expect(
      _semanticsWidget('DVRS progress: 0 of 16 questions answered'),
      findsOneWidget,
    );
    expect(
      _semanticsWidget('Question 1, answer: ${f.dvrsOptionLabel('q1', 0)}'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey<String>('dvrs_question_q16')),
      500,
    );
    await tester.pumpAndSettle();
    expect(find.text('Question 16'), findsOneWidget);
    expect(find.text(f.dvrsQuestionTitle('q16')), findsOneWidget);
    expect(find.text(f.dvrsQuestionPrompt('q16')), findsOneWidget);
    expect(find.text(f.dvrsOptionLabel('q16', 4)), findsOneWidget);
    semantics.dispose();
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

  for (final languageCode in const ['pt', 'en']) {
    for (final level in const [
      DvrsSafetyAlertLevel.attention,
      DvrsSafetyAlertLevel.medicalEvaluation,
      DvrsSafetyAlertLevel.priorityEvaluation,
    ]) {
      testWidgets('alerta ${level.name} deriva texto atual em $languageCode', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final f = FeatureStrings.of(languageCode);
        final result = _resultForAlert(level);
        await _pumpResult(tester, languageCode: languageCode, result: result);

        final message = f.dvrsSafetyMessage(level)!;
        expect(find.text(message), findsOneWidget);
        expect(_semanticsWidget(f.dvrsSafetyAlertLabel), findsOneWidget);
        expect(find.textContaining('ALERTA LEGADO'), findsNothing);
        semantics.dispose();
      });
    }
  }
}
