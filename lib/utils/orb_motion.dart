import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'edge_snap.dart';

/// Plano determinístico para a curta animação após soltar a bolinha.
@immutable
class OrbReleasePlan {
  const OrbReleasePlan({
    required this.start,
    required this.target,
    required this.velocity,
    required this.duration,
    required this.screen,
    required this.windowSize,
    this.dockEdge,
  });

  final Offset start;
  final Offset target;
  final Offset velocity;
  final Duration duration;
  final Rect screen;
  final Size windowSize;
  final BallDockEdge? dockEdge;

  bool get isDocking => dockEdge != null;
}

const double kOrbMaxReleaseSpeed = 1100;
const double kOrbProjectionSeconds = 0.10;

Offset clampOrbVelocity(
  Offset velocity, {
  double maxSpeed = kOrbMaxReleaseSpeed,
}) {
  final speed = velocity.distance;
  if (!speed.isFinite || speed <= maxSpeed || speed == 0) return velocity;
  return velocity * (maxSpeed / speed);
}

Offset clampWindowPosition(Offset position, Size windowSize, Rect screen) {
  final maxX = math.max(screen.left, screen.right - windowSize.width);
  final maxY = math.max(screen.top, screen.bottom - windowSize.height);
  return Offset(
    position.dx.clamp(screen.left, maxX).toDouble(),
    position.dy.clamp(screen.top, maxY).toDouble(),
  );
}

OrbReleasePlan planOrbRelease({
  required Offset start,
  required Offset velocity,
  required Size windowSize,
  required Rect screen,
  required bool edgeSnapEnabled,
  double dockThreshold = kDockThreshold,
}) {
  final safeVelocity = clampOrbVelocity(velocity);
  final speed = safeVelocity.distance;
  final projected = clampWindowPosition(
    start + safeVelocity * kOrbProjectionSeconds,
    windowSize,
    screen,
  );

  BallDockEdge? edge;
  var target = projected;
  if (edgeSnapEnabled) {
    edge = dockEdgeFor(
      windowPos: projected,
      windowSize: windowSize,
      screen: screen,
      threshold: dockThreshold,
    );
    if (edge != null) {
      target = dockedWindowPosition(
        edge: edge,
        windowPos: projected,
        windowSize: windowSize,
        screen: screen,
      );
    }
  }

  final milliseconds = (180 + speed / kOrbMaxReleaseSpeed * 160).round().clamp(
    180,
    340,
  );
  return OrbReleasePlan(
    start: start,
    target: target,
    velocity: safeVelocity,
    duration: Duration(milliseconds: milliseconds),
    screen: screen,
    windowSize: windowSize,
    dockEdge: edge,
  );
}

/// Posição interpolada com desaceleração monotônica e sem overshoot.
Offset orbReleasePosition(OrbReleasePlan plan, double progress) {
  final t = progress.clamp(0.0, 1.0).toDouble();
  final eased = Curves.easeOutCubic.transform(t);
  final position = Offset.lerp(plan.start, plan.target, eased)!;
  if (plan.isDocking) return position;
  return clampWindowPosition(position, plan.windowSize, plan.screen);
}
