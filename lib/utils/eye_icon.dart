import 'dart:io';
import 'dart:typed_data';
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
    final eyeHalfHeight = s * 0.32; // olho mais alto/aberto

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
    final irisR = s * 0.15;
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

    // Quantiza o progresso no nome do arquivo para forçar o refresh do ícone
    // (evita cache por caminho) sem gerar lixo a cada segundo.
    final step = (p * 100).round();
    final dir = Directory.systemTemp.path;

    // No Windows o tray_manager carrega o ícone com LoadImage(IMAGE_ICON,
    // LR_LOADFROMFILE), que só aceita arquivos .ico — um .png resulta em HICON
    // nulo (ícone invisível). Geramos um .ico (DIB 32bpp) a partir dos pixels.
    if (Platform.isWindows) {
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      final ico = _buildIco(rgba!.buffer.asUint8List(), size, size);
      final file = File('$dir/dew_tray_$step.ico');
      await file.writeAsBytes(ico, flush: true);
      return file.path;
    }

    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$dir/dew_tray_$step.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    return file.path;
  }

  /// Monta um arquivo `.ico` de entrada única (DIB BMP 32bpp, sem compressão) a
  /// partir de pixels RGBA. Usa BMP não-comprimido em vez de PNG embutido
  /// porque `LoadImage` (usado pelo tray_manager no Windows) não carrega ICOs
  /// com PNG de forma confiável. A transparência vem do canal alfa (32bpp); a
  /// máscara AND fica toda zerada.
  static Uint8List _buildIco(Uint8List rgba, int width, int height) {
    final maskRow = ((width + 31) ~/ 32) * 4; // linha da máscara AND, em bytes
    final xorSize = width * height * 4;
    final andSize = maskRow * height;
    final dibSize = 40 + xorSize + andSize;
    final fileSize = 6 + 16 + dibSize;

    final out = ByteData(fileSize); // zero-inicializado (cobre a máscara AND)
    var o = 0;
    void u8(int v) {
      out.setUint8(o, v);
      o += 1;
    }

    void u16(int v) {
      out.setUint16(o, v, Endian.little);
      o += 2;
    }

    void u32(int v) {
      out.setUint32(o, v, Endian.little);
      o += 4;
    }

    void i32(int v) {
      out.setInt32(o, v, Endian.little);
      o += 4;
    }

    // ICONDIR
    u16(0); // reservado
    u16(1); // tipo = ícone
    u16(1); // quantidade de imagens
    // ICONDIRENTRY
    u8(width >= 256 ? 0 : width);
    u8(height >= 256 ? 0 : height);
    u8(0); // paleta
    u8(0); // reservado
    u16(1); // planos
    u16(32); // bits por pixel
    u32(dibSize); // bytes da imagem
    u32(22); // offset da imagem (6 + 16)
    // BITMAPINFOHEADER
    u32(40); // biSize
    i32(width); // biWidth
    i32(height * 2); // biHeight (XOR + máscara AND)
    u16(1); // biPlanes
    u16(32); // biBitCount
    u32(0); // biCompression = BI_RGB
    u32(xorSize); // biSizeImage
    i32(0); // biXPelsPerMeter
    i32(0); // biYPelsPerMeter
    u32(0); // biClrUsed
    u32(0); // biClrImportant
    // XOR bitmap: BGRA, linhas de baixo para cima.
    for (var y = height - 1; y >= 0; y--) {
      final row = y * width * 4;
      for (var x = 0; x < width; x++) {
        final i = row + x * 4;
        u8(rgba[i + 2]); // B
        u8(rgba[i + 1]); // G
        u8(rgba[i]); // R
        u8(rgba[i + 3]); // A
      }
    }
    // Máscara AND: permanece toda zerada (já alocada).
    return out.buffer.asUint8List();
  }
}
