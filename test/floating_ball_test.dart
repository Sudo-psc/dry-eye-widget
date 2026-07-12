import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  testWidgets('pressionar comprime imediatamente o material', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: FloatingBall(isActive: false))),
      ),
    );

    expect(
      tester
          .widget<MouseRegion>(
            find.byKey(const ValueKey('floating_ball_pointer')),
          )
          .cursor,
      SystemMouseCursors.grab,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FloatingBall)),
    );
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
    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Lembrete ocular'),
    );
    expect(semantics.label, 'Lembrete ocular');
    expect(semantics.value, '92%');
    expect(tester.binding.transientCallbackCount, 0);
  });
}
