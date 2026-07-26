import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/utils/edge_snap.dart';
import 'package:dry_eye_widget/widgets/floating_ball.dart';

void main() {
  test('anel adapta espessura e folga ao tamanho da bolinha', () {
    expect(FloatingBall.ringStrokeForSize(18), 2.4);
    expect(FloatingBall.ringStrokeForSize(48), closeTo(3.456, 0.001));
    expect(FloatingBall.ringStrokeForSize(96), 4.4);
    expect(FloatingBall.ringGapForSize(18), 3.0);
    expect(FloatingBall.ringGapForSize(48), closeTo(4.32, 0.001));
    expect(FloatingBall.ringGapForSize(96), 5.0);
  });

  test('progresso ambiental não depende de animação contínua', () {
    final idleFrames = {
      for (var i = 0; i <= 1000; i++)
        FloatingBall.quantizedPhase(i / 1000, FloatingBall.idleOrbPhaseSteps),
    };
    final activeFrames = {
      for (var i = 0; i <= 1000; i++)
        FloatingBall.quantizedPhase(i / 1000, FloatingBall.activeOrbPhaseSteps),
    };

    expect(idleFrames.length, lessThanOrEqualTo(65));
    expect(activeFrames.length, lessThanOrEqualTo(46));
    expect(FloatingBall.shouldAnimateRing(0.899), isFalse);
    expect(FloatingBall.shouldAnimateRing(0.9), isFalse);
  });

  testWidgets('anel permanece estável inclusive perto da pausa', (
    tester,
  ) async {
    Widget app(double progress) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: FloatingBall(
            isActive: false,
            dynamicOrbEffect: false,
            showProgress: true,
            progress: progress,
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(0.68));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pumpWidget(app(0.94));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('botão direito (secondary tap) dispara onSecondaryTap', (
    tester,
  ) async {
    var secondaryTaps = 0;
    var leftTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              onTap: () => leftTaps++,
              onSecondaryTap: () => secondaryTaps++,
            ),
          ),
        ),
      ),
    );

    // Clique com o botão direito do mouse.
    await tester.tap(find.byType(FloatingBall), buttons: kSecondaryButton);
    await tester.pump();
    expect(secondaryTaps, 1, reason: 'botão direito deve abrir o menu');
    expect(leftTaps, 0);

    // Clique com o botão esquerdo continua funcionando.
    await tester.tap(find.byType(FloatingBall));
    await tester.pump();
    expect(leftTaps, 1);
    expect(secondaryTaps, 1);
  });

  testWidgets('secondary tap funciona sem callback primário', (tester) async {
    var secondaryTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              onSecondaryTap: () => secondaryTaps++,
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<MouseRegion>(
            find.byKey(const ValueKey('floating_ball_pointer')),
          )
          .cursor,
      SystemMouseCursors.click,
    );
    await tester.tap(find.byType(FloatingBall), buttons: kSecondaryButton);
    await tester.pump();
    expect(secondaryTaps, 1);
  });

  testWidgets('bolinha sem arraste reserva o gesto para fechar por clique', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(isActive: false, onTap: () => taps++),
          ),
        ),
      ),
    );

    final detector = tester
        .widgetList<GestureDetector>(find.byType(GestureDetector))
        .firstWhere((candidate) => candidate.onTap != null);
    expect(detector.onPanStart, isNull);
    expect(detector.onPanEnd, isNull);

    await tester.tap(find.byType(FloatingBall));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('efeito dinâmico reage ao hover sem quebrar interações', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              dynamicOrbEffect: true,
              hoverReactiveBall: true,
              orbIntensity: 1,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(FloatingBall)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(FloatingBall));
    await tester.pump();

    expect(taps, 1);
    await gesture.removePointer();
  });

  testWidgets('micronotificacao de piscada mostra texto e preserva clique', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              blinkReminderVisible: true,
              blinkReminderText: 'Pisque',
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pisque'), findsOneWidget);

    await tester.tap(find.byType(FloatingBall));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('modo encaixado continua clicavel e sem pill de texto', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              dockEdge: BallDockEdge.left,
              blinkReminderVisible: true,
              blinkReminderText: 'Pisque',
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pisque'), findsNothing);

    await tester.tap(find.byType(FloatingBall));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('cursor é clique em repouso e grabbing só durante arraste', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              onTap: () {},
              onDragStart: () {},
              onDragEnd: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<MouseRegion>(
            find.byKey(const ValueKey('floating_ball_pointer')),
          )
          .cursor,
      SystemMouseCursors.click,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FloatingBall)),
    );
    await tester.pump();
    expect(
      tester
          .widget<MouseRegion>(
            find.byKey(const ValueKey('floating_ball_pointer')),
          )
          .cursor,
      SystemMouseCursors.click,
    );

    await gesture.moveBy(const Offset(24, 0));
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      tester
          .widget<MouseRegion>(
            find.byKey(const ValueKey('floating_ball_pointer')),
          )
          .cursor,
      SystemMouseCursors.grabbing,
    );

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 260));
    expect(
      tester
          .widget<MouseRegion>(
            find.byKey(const ValueKey('floating_ball_pointer')),
          )
          .cursor,
      SystemMouseCursors.click,
    );
  });

  testWidgets(
    'arraste entrega velocidade de soltura e mantém clique separado',
    (tester) async {
      var dragStarts = 0;
      var taps = 0;
      var releaseVelocity = Offset.zero;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingBall(
                isActive: false,
                onTap: () => taps++,
                onDragStart: () => dragStarts++,
                onDragEnd: (velocity) => releaseVelocity = velocity,
              ),
            ),
          ),
        ),
      );

      await tester.fling(
        find.byType(FloatingBall),
        const Offset(120, 24),
        1000,
      );
      await tester.pump();

      expect(dragStarts, 1);
      expect(releaseVelocity.distance, greaterThan(0));
      expect(taps, 0);
    },
  );

  testWidgets('arraste não inclina nem acelera o material interno', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              onDragStart: () {},
              onDragEnd: (_) {},
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FloatingBall)),
    );
    await gesture.moveBy(const Offset(36, 18));
    await tester.pump(const Duration(milliseconds: 80));

    final material = tester.widget<Transform>(
      find.byKey(const ValueKey('floating_ball_material')),
    );
    expect(material.transform.storage[1], closeTo(0, 0.0001));
    expect(material.transform.storage[4], closeTo(0, 0.0001));

    await gesture.up();
  });

  testWidgets('anel líquido expõe progresso e respeita reduzir movimento', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: FloatingBall(
                isActive: false,
                showProgress: true,
                progress: 0.92,
                semanticLabel: 'Lembrete ocular',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('floating_ball_progress_ring')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('floating_ball_inner_effect')),
      findsOneWidget,
    );
    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Lembrete ocular'),
    );
    expect(semantics.label, 'Lembrete ocular');
    expect(semantics.value, '92%');
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('semântica expõe ação, dica e valor explícito', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    var semanticTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              showProgress: true,
              progress: 0.92,
              semanticLabel: 'Lembrete ocular',
              semanticHint: 'Abrir controles da pausa',
              semanticValue: 'Pronto para pausar',
              onTap: () => semanticTaps++,
            ),
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel('Lembrete ocular'));
    final data = node.getSemanticsData();
    expect(node.label, 'Lembrete ocular');
    expect(node.hint, 'Abrir controles da pausa');
    expect(node.value, 'Pronto para pausar');
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.flagsCollection.isButton, isTrue);
    tester.semantics.tap(find.semantics.byLabel('Lembrete ocular'));
    await tester.pump();
    expect(semanticTaps, 1);
    semanticsHandle.dispose();
  });

  testWidgets('Pisque é anunciado em live region própria', (tester) async {
    final semanticsHandle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              blinkReminderVisible: true,
              blinkReminderText: 'Pisque',
              semanticLabel: 'Lembrete ocular',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final liveRegion = tester.getSemantics(find.bySemanticsLabel('Pisque'));
    expect(liveRegion.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
    semanticsHandle.dispose();
  });

  testWidgets('não usa autofocus e ativa por Enter e Espaço com foco visível', (
    tester,
  ) async {
    final previousHighlightStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousHighlightStrategy;
    });
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              focusNode: focusNode,
              semanticLabel: 'Abrir pausa',
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    expect(focusNode.hasFocus, isFalse, reason: 'não deve roubar foco');
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    final focusIndicator = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('floating_ball_focus_indicator')),
    );
    final decoration = focusIndicator.foregroundDecoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.color, isNot(Colors.transparent));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 2);
  });

  testWidgets('tamanhos 18 e 32 preservam alvo mínimo de 44 pixels', (
    tester,
  ) async {
    for (final size in <double>[18, 32]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FloatingBall(isActive: false, size: size, onTap: () {}),
            ),
          ),
        ),
      );

      final hitTarget = tester.getSize(
        find.byKey(const ValueKey('floating_ball_hit_target')),
      );
      expect(hitTarget.width, greaterThanOrEqualTo(44));
      expect(hitTarget.height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('reduzir movimento em runtime encerra tickers e timer do orbe', (
    tester,
  ) async {
    Widget app({required bool reduceMotion}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              dynamicOrbEffect: true,
              orbIntensity: 1,
              blinkReminderVisible: true,
              blinkReminderText: 'Pisque',
              showProgress: true,
              progress: 0.95,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(reduceMotion: false));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byType(FloatingBall)));
    final press = await tester.startGesture(
      tester.getCenter(find.byType(FloatingBall)),
    );
    await tester.pump(const Duration(milliseconds: 120));
    final initialPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('floating_ball_inner_effect')),
        )
        .painter;
    await tester.pump(const Duration(milliseconds: 240));
    final movingPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('floating_ball_inner_effect')),
        )
        .painter;
    expect(identical(initialPainter, movingPainter), isFalse);
    expect(
      tester.binding.transientCallbackCount,
      greaterThan(0),
      reason: 'hover e pressão ainda oferecem feedback transitório',
    );

    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pump();
    final stoppedPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('floating_ball_inner_effect')),
        )
        .painter;
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.binding.transientCallbackCount, 0);
    expect(
      identical(
        stoppedPainter,
        tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('floating_ball_inner_effect')),
            )
            .painter,
      ),
      isTrue,
    );
    await press.up();
    await mouse.removePointer();
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('superfície oculta suspende animações, timer e interação', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var taps = 0;
    Widget app({required bool visible}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: FloatingBall(
            isActive: true,
            dynamicOrbEffect: true,
            orbIntensity: 1,
            isSurfaceVisible: visible,
            focusNode: focusNode,
            semanticLabel: 'Alerta ocular',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(visible: true));
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    expect(
      tester.binding.transientCallbackCount,
      0,
      reason: 'o alerta usa estado estático e não compete pela atenção',
    );

    await tester.pumpWidget(app(visible: false));
    await tester.pump();
    final stoppedPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('floating_ball_inner_effect')),
        )
        .painter;
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.semantics.byLabel('Alerta ocular'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 0);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.binding.transientCallbackCount, 0);
    expect(
      identical(
        stoppedPainter,
        tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('floating_ball_inner_effect')),
            )
            .painter,
      ),
      isTrue,
    );

    await tester.tap(find.byType(FloatingBall), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    semanticsHandle.dispose();
  });

  testWidgets('íris aurora só é pintada quando o efeito dinâmico está ativo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              dynamicOrbEffect: false,
              orbIntensity: 1,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('floating_ball_inner_effect')),
      findsNothing,
    );
  });

  testWidgets('íris aurora usa relógio discreto sem ticker contínuo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingBall(
              isActive: false,
              dynamicOrbEffect: true,
              hoverReactiveBall: false,
              orbIntensity: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('floating_ball_inner_effect')),
      findsOneWidget,
    );
    expect(tester.binding.transientCallbackCount, 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, 0);
  });
}
