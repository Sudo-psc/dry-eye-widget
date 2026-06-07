import 'package:flutter/material.dart';

/// Bandeiras simples desenhadas via [CustomPaint] (sem dependências externas,
/// para renderizar igual em macOS e Windows). Usadas no seletor de idioma.
class FlagIcon extends StatelessWidget {
  const FlagIcon.brazil({super.key})
      : _painter = const _BrazilFlagPainter();
  const FlagIcon.usa({super.key}) : _painter = const _UsaFlagPainter();

  final CustomPainter _painter;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: CustomPaint(
        size: const Size(28, 20),
        painter: _painter,
      ),
    );
  }
}

class _BrazilFlagPainter extends CustomPainter {
  const _BrazilFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF009C3B),
    );
    // Losango amarelo.
    final inset = w * 0.10;
    final diamond = Path()
      ..moveTo(w / 2, inset)
      ..lineTo(w - inset, h / 2)
      ..lineTo(w / 2, h - inset)
      ..lineTo(inset, h / 2)
      ..close();
    canvas.drawPath(diamond, Paint()..color = const Color(0xFFFFDF00));
    // Círculo azul.
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      h * 0.24,
      Paint()..color = const Color(0xFF002776),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _UsaFlagPainter extends CustomPainter {
  const _UsaFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const red = Color(0xFFB22234);
    const white = Color(0xFFFFFFFF);
    const blue = Color(0xFF3C3B6E);

    // 7 faixas (vermelho/branco), começando e terminando em vermelho.
    const stripes = 7;
    final sh = h / stripes;
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * sh, w, sh),
        Paint()..color = i.isEven ? red : white,
      );
    }
    // Cantão azul.
    final cantonW = w * 0.42;
    final cantonH = sh * 4;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cantonW, cantonH),
      Paint()..color = blue,
    );
    // Algumas "estrelas" (pontos brancos).
    final star = Paint()..color = white;
    final r = h * 0.045;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 4; col++) {
        final dx = cantonW * (0.18 + col * 0.22);
        final dy = cantonH * (0.22 + row * 0.28);
        canvas.drawCircle(Offset(dx, dy), r, star);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
