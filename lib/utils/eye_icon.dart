import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Gera dinamicamente o ícone do item da barra de menu: um olho estilizado
/// com uma barra inferior que se preenche conforme o progresso até a pausa.
///
/// O desenho é feito num [Canvas], convertido em PNG e salvo num arquivo
/// temporário cujo caminho é devolvido para o `tray_manager`.
class EyeIcon {
  EyeIcon._();

  /// Renderiza o ícone e retorna o caminho do PNG.
  ///
  /// [progress] 0–1 controla a barra inferior. [color] é a cor do traço
  /// (preto no macOS como template; branco no Windows). [size] é o lado do
  /// ícone em pixels (use 2x para telas retina).
  static Future<String> render({
    required double progress,
    required Color color,
    int size = 36,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final s = size.toDouble();
    final p = progress.clamp(0.0, 1.0);

    final stroke = s * 0.07;
    final eyeCenterY = s * 0.42;
    final eyeHalfWidth = s * 0.42;
    final eyeHalfHeight = s * 0.24;

    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Contorno do olho: amêndoa formada por duas curvas quadráticas.
    final left = Offset(s / 2 - eyeHalfWidth, eyeCenterY);
    final right = Offset(s / 2 + eyeHalfWidth, eyeCenterY);
    final eye = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(s / 2, eyeCenterY - eyeHalfHeight, right.dx, right.dy)
      ..quadraticBezierTo(s / 2, eyeCenterY + eyeHalfHeight, left.dx, left.dy);
    canvas.drawPath(eye, line);

    // Íris (círculo) + pupila preenchida.
    final irisR = s * 0.14;
    canvas.drawCircle(Offset(s / 2, eyeCenterY), irisR, line);
    canvas.drawCircle(
      Offset(s / 2, eyeCenterY),
      irisR * 0.45,
      Paint()..color = color,
    );

    // Barra inferior de progresso.
    final barH = s * 0.13;
    final barTop = s - barH;
    final barLeft = s * 0.1;
    final barRight = s * 0.9;
    final barWidth = barRight - barLeft;
    final radius = Radius.circular(barH / 2);

    final trackRect = RRect.fromLTRBR(
      barLeft, barTop, barRight, s - stroke * 0.2, radius);
    canvas.drawRRect(
      trackRect,
      Paint()..color = color.withValues(alpha: 0.3),
    );
    if (p > 0) {
      final fillRect = RRect.fromLTRBR(
        barLeft, barTop, barLeft + barWidth * p, s - stroke * 0.2, radius);
      canvas.drawRRect(fillRect, Paint()..color = color);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    // Quantiza o progresso no nome do arquivo para forçar o refresh do ícone
    // (evita cache por caminho) sem gerar lixo a cada segundo.
    final step = (p * 100).round();
    final file = File('${Directory.systemTemp.path}/dew_tray_$step.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    return file.path;
  }
}
