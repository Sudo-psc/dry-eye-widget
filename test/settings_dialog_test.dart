import 'dart:async';

import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/widgets/settings_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required WidgetSettings initial,
    required FutureOr<void> Function(WidgetSettings settings) onSave,
    VoidCallback? onClose,
    VoidCallback? onReset,
    FutureOr<void> Function()? onResetLearning,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: SizedBox(
              width: 460,
              height: 900,
              child: SettingsDialog(
                initial: initial,
                onSave: onSave,
                onClose: onClose ?? () {},
                onReset: onReset ?? () {},
                onResetLearning: onResetLearning ?? () {},
                onOpenScreenTime: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renderiza dentro da janela de configuracoes sem overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(initial: WidgetSettings.defaults(), onSave: (_) {}),
    );

    expect(find.text(ptStrings.settingsTitle), findsOneWidget);
    expect(find.text(ptStrings.blinkSpeed), findsNothing);
    expect(find.text(ptStrings.save), findsOneWidget);
    expect(find.text(ptStrings.workCycle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-category-reminders')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('settings-category-reminders')));
    await tester.pumpAndSettle();

    expect(find.text(ptStrings.blinkReminderFrequency), findsOneWidget);
  });

  testWidgets('aguarda salvar antes de fechar o menu de configuracoes', (
    tester,
  ) async {
    final completer = Completer<void>();
    var saveCalls = 0;
    var closeCalls = 0;

    await tester.pumpWidget(
      host(
        initial: WidgetSettings.defaults(),
        onSave: (_) async {
          saveCalls++;
          await completer.future;
        },
        onClose: () => closeCalls++,
      ),
    );

    await tester.tap(find.text(ptStrings.save));
    await tester.pump();

    expect(saveCalls, 1);
    expect(closeCalls, 0);

    completer.complete();
    await tester.pump();

    expect(closeCalls, 1);
  });

  testWidgets('nao dispara resets de aprendizado concorrentes', (tester) async {
    final completer = Completer<void>();
    var resetCalls = 0;

    await tester.pumpWidget(
      host(
        initial: WidgetSettings.defaults(),
        onSave: (_) {},
        onResetLearning: () async {
          resetCalls++;
          await completer.future;
        },
      ),
    );

    await tester.tap(find.byKey(const ValueKey('settings-category-privacy')));
    await tester.pumpAndSettle();

    final resetButton = find.text(ptStrings.resetLearningLabel);
    await tester.ensureVisible(resetButton);
    await tester.pump();

    await tester.tap(resetButton);
    await tester.pump();
    await tester.tap(resetButton);
    await tester.pump();

    expect(resetCalls, 1);

    completer.complete();
    await tester.pump();
    await tester.tap(resetButton);
    await tester.pump();

    expect(resetCalls, 2);
  });

  testWidgets('permite ativar aviso sonoro de piscada e escolher toque', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    WidgetSettings? saved;

    await tester.pumpWidget(
      host(initial: WidgetSettings.defaults(), onSave: (s) => saved = s),
    );

    await tester.tap(find.byKey(const ValueKey('settings-category-reminders')));
    await tester.pumpAndSettle();

    final soundLabel = find.text(ptStrings.blinkReminderSound);
    await tester.ensureVisible(soundLabel);
    await tester.pump();

    final soundRow = find.ancestor(of: soundLabel, matching: find.byType(Row));
    final soundSwitch = find.descendant(
      of: soundRow,
      matching: find.byType(Switch),
    );
    await tester.ensureVisible(soundSwitch);
    await tester.tap(soundSwitch);
    await tester.pumpAndSettle();

    expect(find.text(ptStrings.blinkReminderToneSoftPulse), findsOneWidget);
    expect(find.text(ptStrings.blinkReminderToneWarmBell), findsOneWidget);

    await tester.ensureVisible(find.text(ptStrings.blinkReminderToneWarmBell));
    await tester.pump();
    await tester.tap(find.text(ptStrings.blinkReminderToneWarmBell));
    await tester.pump();

    await tester.ensureVisible(find.text(ptStrings.save));
    await tester.tap(find.text(ptStrings.save));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.blinkReminderSoundEnabled, isTrue);
    expect(saved!.blinkReminderSound, BlinkReminderSound.warmBell);
  });

  testWidgets('aparência mostra prévia viva da bolinha', (tester) async {
    await tester.pumpWidget(
      host(initial: WidgetSettings.defaults(), onSave: (_) {}),
    );

    await tester.tap(
      find.byKey(const ValueKey('settings-category-appearance')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-ball-preview')), findsOneWidget);
    expect(find.text(ptStrings.ballSize), findsOneWidget);
  });

  testWidgets('categorias permanecem utilizáveis com texto a 200%', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        initial: WidgetSettings.defaults(),
        onSave: (_) {},
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey('settings-category-appearance')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-ball-preview')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escape fecha configurações sem salvar', (tester) async {
    var closes = 0;
    var saves = 0;
    await tester.pumpWidget(
      host(
        initial: WidgetSettings.defaults(),
        onSave: (_) => saves++,
        onClose: () => closes++,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(closes, 1);
    expect(saves, 0);
  });
}
