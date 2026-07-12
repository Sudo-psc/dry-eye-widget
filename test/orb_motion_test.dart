import 'package:dry_eye_widget/utils/edge_snap.dart';
import 'package:dry_eye_widget/utils/orb_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const screen = Rect.fromLTWH(0, 0, 1440, 900);
  const window = Size(48, 48);

  test('limita velocidade preservando direção', () {
    final velocity = clampOrbVelocity(const Offset(3000, 4000));
    expect(velocity.distance, closeTo(kOrbMaxReleaseSpeed, 0.001));
    expect(velocity.dx / velocity.dy, closeTo(0.75, 0.001));
  });

  test('projeta inércia curta e mantém destino dentro da área útil', () {
    final plan = planOrbRelease(
      start: const Offset(500, 300),
      velocity: const Offset(900, 200),
      windowSize: window,
      screen: screen,
      edgeSnapEnabled: false,
    );

    expect(plan.target.dx, greaterThan(plan.start.dx));
    expect(plan.target.dy, greaterThan(plan.start.dy));
    expect(plan.target.dx + window.width, lessThanOrEqualTo(screen.right));
    expect(plan.duration.inMilliseconds, inInclusiveRange(180, 340));
  });

  test('inércia próxima da direita termina em docking monotônico', () {
    final plan = planOrbRelease(
      start: const Offset(1320, 320),
      velocity: const Offset(1000, 0),
      windowSize: window,
      screen: screen,
      edgeSnapEnabled: true,
      dockThreshold: 80,
    );

    expect(plan.dockEdge, BallDockEdge.right);
    expect(plan.target.dx, greaterThan(screen.right - window.width));
    expect(orbReleasePosition(plan, 0), plan.start);
    expect(orbReleasePosition(plan, 1), plan.target);

    var previousX = plan.start.dx;
    for (var i = 1; i <= 20; i++) {
      final x = orbReleasePosition(plan, i / 20).dx;
      expect(x, greaterThanOrEqualTo(previousX));
      expect(x, lessThanOrEqualTo(plan.target.dx));
      previousX = x;
    }
  });

  test('inércia controlada termina exatamente no alvo sem sair da tela', () {
    final plan = planOrbRelease(
      start: const Offset(200, 200),
      velocity: const Offset(-700, 300),
      windowSize: window,
      screen: screen,
      edgeSnapEnabled: false,
    );

    var previous = plan.start;
    for (var i = 0; i <= 20; i++) {
      final position = orbReleasePosition(plan, i / 20);
      expect(position.dx, inInclusiveRange(screen.left, screen.right - 48));
      expect(position.dy, inInclusiveRange(screen.top, screen.bottom - 48));
      if (i > 0) {
        expect(position.dx, lessThanOrEqualTo(previous.dx));
        expect(position.dy, greaterThanOrEqualTo(previous.dy));
      }
      previous = position;
    }
    expect(orbReleasePosition(plan, 1), plan.target);
  });
}
