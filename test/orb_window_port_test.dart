import 'package:dry_eye_widget/app/orb_window_port.dart';
import 'package:dry_eye_widget/app/window_layout.dart';
import 'package:dry_eye_widget/utils/edge_snap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeOrbWindowPort implements OrbWindowPort {
  _FakeOrbWindowPort({this.delay = Duration.zero});

  final Duration delay;
  final List<String> calls = <String>[];

  @override
  Future<void> setPosition(Offset position) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    calls.add('position:$position');
  }

  @override
  Future<void> setSize(Size size) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    calls.add('size:$size');
  }
}

void main() {
  const screen = Rect.fromLTWH(0, 0, 1440, 900);
  const compactSize = Size(60, 60);
  const menuSize = Size(300, 414);

  OrbWindowTransitionDriver driverFor(_FakeOrbWindowPort port) {
    return OrbWindowTransitionDriver(
      window: port,
      resolveScreen: (position, size) async => screen,
    );
  }

  test('opening a menu always applies size before position', () async {
    final port = _FakeOrbWindowPort();
    final transition = await driverFor(port).openMenu(
      anchor: const CompactWindowAnchor(Offset(120, 80)),
      compactSize: compactSize,
      ballSize: 32,
      menuSize: menuSize,
      dockEdge: null,
    );

    expect(port.calls, <String>[
      'size:$menuSize',
      'position:${transition.placement.windowPosition}',
    ]);
  });

  test('opening a docked orb preserves its dock edge', () async {
    final port = _FakeOrbWindowPort();
    final transition = await driverFor(port).openMenu(
      anchor: const CompactWindowAnchor(Offset(-16, 260)),
      compactSize: compactSize,
      ballSize: 32,
      menuSize: menuSize,
      dockEdge: BallDockEdge.left,
    );

    expect(transition.dockEdge, BallDockEdge.left);
    expect(transition.anchor.position, const Offset(-16, 260));
  });

  for (final edge in BallDockEdge.values) {
    test('closing restores the compact target docked on ${edge.id}', () async {
      final port = _FakeOrbWindowPort();
      final driver = driverFor(port);
      final anchor = CompactWindowAnchor(
        edge == BallDockEdge.left
            ? const Offset(-16, 260)
            : const Offset(1396, 260),
      );
      final transition = await driver.openMenu(
        anchor: anchor,
        compactSize: compactSize,
        ballSize: 32,
        menuSize: menuSize,
        dockEdge: edge,
      );
      port.calls.clear();

      final target = await driver.restoreCompact(transition);
      final expected = dockedWindowPosition(
        edge: edge,
        windowPos: anchor.position,
        windowSize: compactSize,
        screen: screen,
      );

      expect(target, expected);
      expect(port.calls, <String>['size:$compactSize', 'position:$expected']);
    });
  }

  test('two rapid transitions remain FIFO and do not interleave', () async {
    final port = _FakeOrbWindowPort(delay: const Duration(milliseconds: 1));
    final driver = driverFor(port);
    const firstAnchor = CompactWindowAnchor(Offset(120, 80));
    const secondAnchor = CompactWindowAnchor(Offset(980, 90));

    final first = driver.openMenu(
      anchor: firstAnchor,
      compactSize: compactSize,
      ballSize: 32,
      menuSize: menuSize,
      dockEdge: null,
    );
    final second = driver.openMenu(
      anchor: secondAnchor,
      compactSize: compactSize,
      ballSize: 32,
      menuSize: menuSize,
      dockEdge: BallDockEdge.right,
    );
    final transitions = await Future.wait([first, second]);

    expect(port.calls, <String>[
      'size:$menuSize',
      'position:${transitions[0].placement.windowPosition}',
      'size:$menuSize',
      'position:${transitions[1].placement.windowPosition}',
    ]);
  });
}
