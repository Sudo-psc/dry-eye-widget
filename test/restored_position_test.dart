import 'package:dry_eye_widget/app/window_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const windowSize = Size(50, 50);

  // Layout típico: notebook em (0,0) e monitor externo à direita.
  const laptop = Rect.fromLTWH(0, 25, 1512, 945);
  const externo = Rect.fromLTWH(1512, 0, 1920, 1080);

  Offset? resolve(Offset saved, List<Rect> screens) => resolveRestoredPosition(
    savedPosition: saved,
    windowSize: windowSize,
    screens: screens,
  );

  test('posição já visível é preservada', () {
    const saved = Offset(400, 300);

    expect(resolve(saved, [laptop, externo]), saved);
  });

  test('posição no monitor externo é preservada enquanto ele existe', () {
    const saved = Offset(2560, 400);

    expect(resolve(saved, [laptop, externo]), saved);
  });

  // O caso que deixava a bolinha inalcançável.
  test('monitor externo desconectado traz a bolinha de volta', () {
    const saved = Offset(2560, 400);

    final resolvido = resolve(saved, [laptop])!;

    expect(laptop.contains(resolvido), isTrue);
    expect(resolvido.dx, laptop.right - windowSize.width);
    expect(resolvido.dy, 400);
  });

  test('posição acima do topo visível desce para dentro', () {
    // y = 0 fica sob a barra de menus: a área visível começa em 25.
    final resolvido = resolve(const Offset(200, 0), [laptop])!;

    expect(resolvido.dy, laptop.top);
    expect(resolvido.dx, 200);
  });

  test('monitor à esquerda com origem negativa é respeitado', () {
    const esquerdo = Rect.fromLTWH(-1920, 0, 1920, 1080);

    // Bolinha bem à esquerda do monitor negativo, fora de qualquer tela.
    final resolvido = resolve(const Offset(-3000, 500), [esquerdo, laptop])!;

    expect(esquerdo.contains(resolvido), isTrue);
    expect(resolvido.dx, esquerdo.left);
  });

  test('janela maior que a tela é fixada na origem visível', () {
    final resolvido = resolveRestoredPosition(
      savedPosition: const Offset(900, 900),
      windowSize: const Size(4000, 4000),
      screens: const [laptop],
    )!;

    expect(resolvido, Offset(laptop.left, laptop.top));
  });

  test('sem telas devolve null para o chamador manter o que tinha', () {
    expect(resolve(const Offset(10, 10), const []), isNull);
    expect(resolve(const Offset(10, 10), const [Rect.fromLTWH(0, 0, 0, 0)]),
        isNull);
  });
}
