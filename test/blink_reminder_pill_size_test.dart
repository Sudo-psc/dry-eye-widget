import 'package:dry_eye_widget/widgets/floating_ball.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Largura que o texto realmente ocupa, com o mesmo estilo da pílula.
double textWidth(String text, {TextScaler scaler = TextScaler.noScaling}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: FloatingBall.blinkReminderTextStyle),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  return painter.width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Size sizeFor(String text, {double ballSize = 29, bool showRing = true}) =>
      FloatingBall.blinkReminderSize(
        ballSize: ballSize,
        text: text,
        showRing: showRing,
      );

  // O defeito relatado: a pílula reservava espaço fixo e sobrava um rabo vazio
  // à direita de rótulos curtos.
  test('largura não sobra além do conteúdo real', () {
    const ballSize = 29.0;
    final medida = sizeFor('Pisque', ballSize: ballSize);

    final anel =
        ballSize +
        (FloatingBall.ringGapForSize(ballSize) +
                FloatingBall.ringStrokeForSize(ballSize)) *
            2;
    // padLeft(4) + anel + gap(8) + texto + padRight(12)
    final esperado = 4 + anel + 8 + textWidth('Pisque') + 12;

    expect(medida.width, closeTo(esperado, 1.0));
    // A fórmula antiga dava max(29+156, 176) = 185.
    expect(medida.width, lessThan(150));
  });

  test('rótulo mais curto gera pílula mais estreita', () {
    expect(sizeFor('Blink').width, lessThan(sizeFor('Pisque').width));
  });

  test('rótulo longo alarga em vez de cortar', () {
    final curta = sizeFor('Pisque');
    final longa = sizeFor('Pisque devagar algumas vezes agora');

    expect(longa.width, greaterThan(curta.width));
    expect(
      longa.width - curta.width,
      closeTo(
        textWidth('Pisque devagar algumas vezes agora') - textWidth('Pisque'),
        1.0,
      ),
    );
  });

  test('sem anel a pílula encolhe junto com o visual da bolinha', () {
    expect(
      sizeFor('Pisque', showRing: false).width,
      lessThan(sizeFor('Pisque', showRing: true).width),
    );
  });

  test('escala de texto aumenta a largura', () {
    final normal = FloatingBall.blinkReminderSize(
      ballSize: 29,
      text: 'Pisque',
      showRing: true,
    );
    final ampliada = FloatingBall.blinkReminderSize(
      ballSize: 29,
      text: 'Pisque',
      showRing: true,
      textScaler: const TextScaler.linear(2),
    );

    expect(ampliada.width, greaterThan(normal.width));
    expect(ampliada.height, greaterThanOrEqualTo(normal.height));
  });

  test('altura acomoda a bolinha e nunca fica abaixo do mínimo', () {
    expect(sizeFor('Pisque', ballSize: 18).height, 52);
    expect(sizeFor('Pisque', ballSize: 96).height, 96 + 24);
  });

  testWidgets('pílula desenhada não é mais larga que o necessário', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 200,
              child: FloatingBall(
                isActive: false,
                size: 29,
                dynamicOrbEffect: false,
                showProgress: true,
                blinkReminderVisible: true,
                blinkReminderText: 'Pisque',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    // O fundo da pílula é o DecoratedBox que embrulha o texto: sua largura não
    // pode passar do que o cálculo prevê.
    final esperado = FloatingBall.blinkReminderSize(
      ballSize: 29,
      text: 'Pisque',
      showRing: true,
    );
    final pilula = tester.getSize(
      find
          .ancestor(
            of: find.text('Pisque'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(pilula.width, lessThanOrEqualTo(esperado.width));
    // E não é um fundo degenerado: cobre a bolinha e o texto.
    expect(pilula.width, greaterThan(esperado.width - 2));
  });
}
