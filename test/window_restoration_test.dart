import 'package:dry_eye_widget/app/window_restoration.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/utils/edge_snap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const laptop = Rect.fromLTWH(0, 25, 1512, 945);
  const compact = Size(50, 50);

  late List<Offset> positions;
  late List<Offset> saved;

  BallPositionRestorer restorer({
    Future<List<Rect>> Function()? loadDisplays,
    Future<Rect> Function()? loadPrimaryDisplay,
  }) {
    return BallPositionRestorer(
      loadDisplays: loadDisplays ?? () async => const [laptop],
      loadPrimaryDisplay: loadPrimaryDisplay ?? () async => laptop,
      setWindowPosition: (position) async => positions.add(position),
      saveBallPosition: (x, y) async => saved.add(Offset(x, y)),
    );
  }

  setUp(() {
    positions = [];
    saved = [];
  });

  test('posição salva visível é aplicada sem regravar', () async {
    await restorer().restore(
      savedX: 400,
      savedY: 300,
      defaultCorner: BallCorner.topLeft,
      windowSize: compact,
      dockEdge: null,
    );

    expect(positions, const [Offset(400, 300)]);
    expect(saved, isEmpty);
  });

  test('posição fora das telas volta e persiste a correção', () async {
    await restorer().restore(
      savedX: 2560,
      savedY: 400,
      defaultCorner: BallCorner.topLeft,
      windowSize: compact,
      dockEdge: null,
    );

    const expected = Offset(1462, 400);
    expect(positions, const [expected]);
    expect(saved, const [expected]);
  });

  test(
    'bolinha encaixada continua fora da tela e não regrava a posição',
    () async {
      // Encaixada à direita, parte da janela fica fora da área visível por
      // design. Recortá-la para dentro a desencaixaria.
      const docked = Offset(1481, 400);
      await restorer().restore(
        savedX: docked.dx,
        savedY: docked.dy,
        defaultCorner: BallCorner.topLeft,
        windowSize: compact,
        dockEdge: BallDockEdge.right,
      );

      expect(positions, hasLength(1));
      expect(
        positions.single.dx + compact.width,
        greaterThan(laptop.right),
        reason: 'o encaixe precisa manter parte da bolinha fora da borda',
      );
      expect(positions.single.dy, docked.dy);
      expect(
        saved,
        isEmpty,
        reason: 'a posição salva não pode ser sobrescrita',
      );
    },
  );

  test(
    'encaixe em monitor desconectado volta para uma tela existente',
    () async {
      await restorer(loadDisplays: () async => const [laptop]).restore(
        savedX: 3000,
        savedY: 400,
        defaultCorner: BallCorner.topLeft,
        windowSize: compact,
        dockEdge: BallDockEdge.right,
      );

      expect(positions, hasLength(1));
      expect(positions.single.dx, lessThan(laptop.right));
      expect(
        positions.single.dx + compact.width,
        greaterThan(laptop.right),
        reason: 'reencaixa na tela conectada, ainda como meia-lua',
      );
      expect(saved, isEmpty);
    },
  );

  test('falha ao consultar monitores preserva posição salva', () async {
    await restorer(
      loadDisplays: () => Future<List<Rect>>.error(StateError('indisponível')),
    ).restore(
      savedX: 320,
      savedY: 240,
      defaultCorner: BallCorner.topLeft,
      windowSize: compact,
      dockEdge: null,
    );

    expect(positions, const [Offset(320, 240)]);
    expect(saved, isEmpty);
  });

  test('sem posição salva usa canto relativo à origem visível', () async {
    const secondary = Rect.fromLTWH(-1920, -120, 1920, 1080);
    await restorer(loadPrimaryDisplay: () async => secondary).restore(
      savedX: null,
      savedY: null,
      defaultCorner: BallCorner.bottomRight,
      windowSize: compact,
      dockEdge: null,
    );

    expect(positions, const [Offset(-74, 886)]);
    expect(saved, isEmpty);
  });

  test('falha na tela primária usa posição segura conhecida', () async {
    await restorer(
      loadPrimaryDisplay: () => Future<Rect>.error(StateError('indisponível')),
    ).restore(
      savedX: null,
      savedY: null,
      defaultCorner: BallCorner.center,
      windowSize: compact,
      dockEdge: null,
    );

    expect(positions, const [Offset(100, 100)]);
  });
}
