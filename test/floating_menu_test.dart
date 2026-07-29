import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/l10n/feature_strings.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('painel principal prioriza pausas e hub de saúde', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var hubOpened = 0;
    final f = FeatureStrings.of('pt');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingMenu(
              strings: ptStrings,
              healthHubLabel: f.menuHealthHub,
              myDataLabel: f.menuMyData,
              isPaused: false,
              onStartNow: () {},
              onReset: () {},
              onTogglePause: () {},
              onExtendCycle: () {},
              onGuidance: () {},
              onHealthHub: () => hubOpened++,
              onMyData: () {},
              onCheckUpdates: () {},
              onAbout: () {},
              onSettings: () {},
              onQuit: () {},
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(f.menuHealthHub), findsOneWidget);
    expect(find.text(f.menuQuickStart), findsOneWidget);
    expect(find.text(f.menuQuickReset), findsOneWidget);
    expect(find.text(f.menuQuickPause), findsOneWidget);
    expect(find.text(f.menuQuickExtend), findsOneWidget);
    expect(find.text(ptStrings.menuGuidance), findsOneWidget);
    expect(find.text(ptStrings.menuGroupSystem), findsOneWidget);
    expect(find.text(ptStrings.menuDvrs), findsNothing);
    expect(find.text(ptStrings.menuReports), findsNothing);
    expect(find.text(f.menuMyData), findsNothing);

    final quickLabel = tester.widget<Text>(find.text(f.menuQuickStart));
    final sectionLabel = tester.widget<Text>(
      find.text(ptStrings.menuGroupActions.toUpperCase()),
    );
    expect(
      quickLabel.style?.fontSize,
      greaterThanOrEqualTo(AppTypography.minimumReadable),
    );
    expect(
      sectionLabel.style?.fontSize,
      greaterThanOrEqualTo(AppTypography.minimumReadable),
    );

    await tester.tap(find.text(f.menuHealthHub));
    await tester.pump();

    expect(hubOpened, 1);
  });

  testWidgets('ações rápidas aceitam foco e ativação pelo teclado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var started = 0;
    var hubOpened = 0;
    final f = FeatureStrings.of('pt');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingMenu(
            strings: ptStrings,
            healthHubLabel: f.menuHealthHub,
            myDataLabel: f.menuMyData,
            isPaused: false,
            onStartNow: () => started++,
            onReset: () {},
            onTogglePause: () {},
            onExtendCycle: () {},
            onGuidance: () {},
            onHealthHub: () => hubOpened++,
            onMyData: () {},
            onCheckUpdates: () {},
            onAbout: () {},
            onSettings: () {},
            onQuit: () {},
            onDismiss: () {},
            autofocusFirstAction: true,
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(started, 1);
    expect(hubOpened, 0);
  });

  testWidgets('menu elimina transição quando reduzir movimento está ativo', (
    tester,
  ) async {
    final f = FeatureStrings.of('pt');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: FloatingMenu(
            strings: ptStrings,
            healthHubLabel: f.menuHealthHub,
            myDataLabel: f.menuMyData,
            isPaused: false,
            onStartNow: () {},
            onReset: () {},
            onTogglePause: () {},
            onExtendCycle: () {},
            onGuidance: () {},
            onHealthHub: () {},
            onMyData: () {},
            onCheckUpdates: () {},
            onAbout: () {},
            onSettings: () {},
            onQuit: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
  });

  testWidgets('subpágina usa fade-through curto ancorado no topo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final f = FeatureStrings.of('pt');

    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: FloatingMenu(
            strings: ptStrings,
            healthHubLabel: f.menuHealthHub,
            myDataLabel: f.menuMyData,
            isPaused: false,
            onStartNow: () {},
            onReset: () {},
            onTogglePause: () {},
            onExtendCycle: () {},
            onGuidance: () {},
            onHealthHub: () {},
            onMyData: () {},
            onCheckUpdates: () {},
            onAbout: () {},
            onSettings: () {},
            onQuit: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, const Duration(milliseconds: 180));

    await tester.tap(find.text(ptStrings.menuGroupSystem));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));

    expect(find.byType(ScaleTransition), findsWidgets);
    final stack = tester.widget<Stack>(
      find.descendant(
        of: find.byType(AnimatedSwitcher),
        matching: find.byType(Stack),
      ),
    );
    expect(stack.alignment, Alignment.topCenter);
    final pageTransitions = <FadeTransition>[
      tester.widget(
        find.byKey(const ValueKey('floating-menu-transition-main')),
      ),
      tester.widget(
        find.byKey(const ValueKey('floating-menu-transition-system')),
      ),
    ];
    expect(
      pageTransitions
          .where((transition) => transition.opacity.value > 0.1)
          .length,
      lessThanOrEqualTo(1),
      reason: pageTransitions
          .map((transition) => transition.opacity.value.toStringAsFixed(3))
          .join(', '),
    );

    await tester.pumpAndSettle();
    expect(find.text(ptStrings.menuQuit), findsOneWidget);
  });

  testWidgets('rótulos rápidos não causam overflow com escala de 160%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(560, 760);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final f = FeatureStrings.of('pt');

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Center(
            child: FloatingMenu(
              strings: ptStrings,
              healthHubLabel: f.menuHealthHub,
              myDataLabel: f.menuMyData,
              isPaused: false,
              onStartNow: () {},
              onReset: () {},
              onTogglePause: () {},
              onExtendCycle: () {},
              onGuidance: () {},
              onHealthHub: () {},
              onMyData: () {},
              onCheckUpdates: () {},
              onAbout: () {},
              onSettings: () {},
              onQuit: () {},
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(f.menuQuickStart), findsOneWidget);
    expect(find.text(f.menuQuickExtend), findsOneWidget);
  });

  testWidgets('ações de sistema aparecem em uma segunda página', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final f = FeatureStrings.of('pt');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: FloatingMenu(
              strings: ptStrings,
              healthHubLabel: f.menuHealthHub,
              myDataLabel: f.menuMyData,
              isPaused: false,
              onStartNow: () {},
              onReset: () {},
              onTogglePause: () {},
              onExtendCycle: () {},
              onGuidance: () {},
              onHealthHub: () {},
              onMyData: () {},
              onCheckUpdates: () {},
              onAbout: () {},
              onSettings: () {},
              onQuit: () {},
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(ptStrings.menuQuit), findsNothing);

    await tester.tap(find.text(ptStrings.menuGroupSystem));
    await tester.pumpAndSettle();

    expect(find.text(f.menuMyData), findsOneWidget);
    expect(find.text(ptStrings.menuCheckUpdates), findsOneWidget);
    expect(find.text(ptStrings.menuSettings), findsOneWidget);
    expect(find.text(ptStrings.menuAbout), findsOneWidget);
    expect(find.text(ptStrings.menuQuit), findsOneWidget);
    expect(find.text(f.menuHealthHub), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text(f.menuHealthHub), findsOneWidget);
    expect(find.text(ptStrings.menuQuit), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text(ptStrings.menuQuit), findsOneWidget);

    await tester.tap(find.text(ptStrings.back));
    await tester.pumpAndSettle();

    expect(find.text(f.menuHealthHub), findsOneWidget);
    expect(find.text(ptStrings.menuQuit), findsNothing);
  });

  testWidgets(
    'silêncio temporário oferece 15 minutos e 1 hora e fecha o menu',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final selectedDurations = <Duration>[];
      var dismissed = 0;
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _menuHarness(
          onQuietBlinkReminders: selectedDurations.add,
          onDismiss: () => dismissed++,
          closeOnDismiss: true,
        ),
      );

      final quietAction = find.bySemanticsLabel(
        ptStrings.menuQuietBlinkReminders,
      );
      expect(quietAction, findsOneWidget);
      expect(
        tester
            .getSemantics(quietAction)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('quiet-blink-reminders-action')))
            .height,
        greaterThanOrEqualTo(44),
      );
      semantics.dispose();

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('quiet-blink-reminders-action')),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(ptStrings.quietBlinkRemindersTitle.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(ptStrings.quietBlinkRemindersDescription),
        findsOneWidget,
      );
      expect(find.text(ptStrings.quietBlinkFor15Minutes), findsOneWidget);
      expect(find.text(ptStrings.quietBlinkFor1Hour), findsOneWidget);

      await tester.tap(find.text(ptStrings.quietBlinkFor15Minutes));
      await tester.pumpAndSettle();

      expect(selectedDurations, const [Duration(minutes: 15)]);
      expect(dismissed, 1);
      expect(find.byType(FloatingMenu), findsNothing);

      await tester.pumpWidget(
        _menuHarness(
          onQuietBlinkReminders: selectedDurations.add,
          onDismiss: () => dismissed++,
          closeOnDismiss: true,
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('quiet-blink-reminders-action')),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(ptStrings.quietBlinkFor1Hour));
      await tester.pumpAndSettle();

      expect(selectedDurations, const [
        Duration(minutes: 15),
        Duration(hours: 1),
      ]);
      expect(dismissed, 2);
      expect(find.byType(FloatingMenu), findsNothing);
    },
  );

  testWidgets(
    'silêncio ativo permite retomar avisos de piscada imediatamente',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var resumed = 0;
      var dismissed = 0;
      await tester.pumpWidget(
        _menuHarness(
          quietUntil: DateTime(2099, 1, 1, 14, 30),
          onQuietBlinkReminders: (_) {},
          onResumeBlinkReminders: () => resumed++,
          onDismiss: () => dismissed++,
        ),
      );

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('quiet-blink-reminders-action')),
          matching: find.byType(TextButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('14:30'), findsOneWidget);
      expect(find.text(ptStrings.quietBlinkResumeNow), findsOneWidget);

      await tester.tap(find.text(ptStrings.quietBlinkResumeNow));
      await tester.pump();

      expect(resumed, 1);
      expect(dismissed, 1);
    },
  );

  testWidgets('Escape volta à principal com foco estável e depois fecha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var dismissed = 0;
    await tester.pumpWidget(
      _menuHarness(
        autofocusFirstAction: true,
        onQuietBlinkReminders: (_) {},
        onDismiss: () => dismissed++,
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('quiet-blink-reminders-action')),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(ptStrings.quietBlinkRemindersTitle.toUpperCase()),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(
      find.text(ptStrings.quietBlinkRemindersTitle.toUpperCase()),
      findsNothing,
    );
    expect(
      tester
          .widget<TextButton>(
            find.descendant(
              of: find.byKey(const ValueKey('quiet-blink-reminders-action')),
              matching: find.byType(TextButton),
            ),
          )
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(
      find.text(ptStrings.quietBlinkRemindersTitle.toUpperCase()),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(dismissed, 1);
  });

  testWidgets('linhas expõem onTap semântico e alvo mínimo de 44 pixels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_menuHarness());

    final systemAction = find.bySemanticsLabel(ptStrings.menuGroupSystem);
    expect(
      tester
          .getSemantics(systemAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSize(
            find.byKey(ValueKey('menu-row-${ptStrings.menuGroupSystem}')),
          )
          .height,
      greaterThanOrEqualTo(44),
    );

    final quickStart = find.bySemanticsLabel(ptStrings.menuStartBreak);
    expect(
      tester
          .getSemantics(quickStart)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              ValueKey(
                'quick-action-${FeatureStrings.of('pt').menuQuickStart}',
              ),
            ),
          )
          .height,
      greaterThanOrEqualTo(44),
    );
    semantics.dispose();
  });

  testWidgets('subpáginas continuam alcançáveis com texto a 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 350);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_menuHarness(textScale: 2));
    await tester.scrollUntilVisible(
      find.text(ptStrings.menuGroupSystem),
      80,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text(ptStrings.menuGroupSystem));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(ptStrings.menuQuit),
      80,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text(ptStrings.menuQuit).hitTestable(), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _menuHarness(
        quietUntil: DateTime(2099, 1, 1, 14, 30),
        onQuietBlinkReminders: (_) {},
        onResumeBlinkReminders: () {},
        textScale: 2,
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('quiet-blink-reminders-action')),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(ptStrings.quietBlinkResumeNow),
      80,
      scrollable: find.byType(Scrollable),
    );
    expect(
      find.text(ptStrings.quietBlinkResumeNow).hitTestable(),
      findsOneWidget,
    );
  });
}

Widget _menuHarness({
  DateTime? quietUntil,
  ValueChanged<Duration>? onQuietBlinkReminders,
  VoidCallback? onResumeBlinkReminders,
  VoidCallback? onDismiss,
  bool autofocusFirstAction = false,
  bool closeOnDismiss = false,
  double textScale = 1,
}) {
  final feature = FeatureStrings.of('pt');
  Widget menu(VoidCallback dismiss) => FloatingMenu(
    strings: ptStrings,
    healthHubLabel: feature.menuHealthHub,
    myDataLabel: feature.menuMyData,
    isPaused: false,
    blinkRemindersQuietUntil: quietUntil,
    onQuietBlinkReminders: onQuietBlinkReminders,
    onResumeBlinkReminders: onResumeBlinkReminders,
    autofocusFirstAction: autofocusFirstAction,
    onStartNow: () {},
    onReset: () {},
    onTogglePause: () {},
    onExtendCycle: () {},
    onGuidance: () {},
    onHealthHub: () {},
    onMyData: () {},
    onCheckUpdates: () {},
    onAbout: () {},
    onSettings: () {},
    onQuit: () {},
    onDismiss: dismiss,
  );

  Widget body;
  if (closeOnDismiss) {
    var visible = true;
    body = StatefulBuilder(
      builder: (context, setState) {
        if (!visible) return const SizedBox.shrink();
        return menu(() {
          onDismiss?.call();
          setState(() => visible = false);
        });
      },
    );
  } else {
    body = menu(onDismiss ?? () {});
  }

  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: body),
        ),
      ),
    ),
  );
}
