import 'dart:math' as math;

import 'package:dry_eye_widget/ui/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _linear(double channel) => channel <= 0.04045
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _linear(color.r) +
    0.7152 * _linear(color.g) +
    0.0722 * _linear(color.b);

double _contrast(Color foreground, Color background) {
  final lighter = math.max(_luminance(foreground), _luminance(background));
  final darker = math.min(_luminance(foreground), _luminance(background));
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('texto do timer atinge AAA e textos auxiliares atingem AA', () {
    expect(
      _contrast(AppColorTokens.textPrimary, AppColorTokens.canvas),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(AppColorTokens.textPrimary, AppColorTokens.surfaceRaised),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(AppColorTokens.textSecondary, AppColorTokens.canvas),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppColorTokens.textMuted, AppColorTokens.surfaceRaised),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('acento e foco preservam contraste funcional', () {
    expect(
      _contrast(AppColorTokens.accent, AppColorTokens.canvas),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppColorTokens.focus, AppColorTokens.canvas),
      greaterThanOrEqualTo(3),
    );
  });

  test('tipografia segue escala modular e contador usa tabular-nums', () {
    expect(AppTypography.body / AppTypography.supporting, closeTo(1.25, 0.001));
    expect(AppTypography.title / AppTypography.body, closeTo(1.25, 0.001));
    expect(AppTypography.headline / AppTypography.title, closeTo(1.25, 0.002));
    expect(AppTypography.timerStyle.fontFeatures?.single.feature, 'tnum');
    expect(AppTypography.timerStyle.letterSpacing, lessThan(0));
  });

  test('alvos e motion respeitam o contrato calmo', () {
    expect(AppComponentSize.minimumTarget, greaterThanOrEqualTo(44));
    expect(AppMotion.fast.inMilliseconds, greaterThanOrEqualTo(200));
    expect(AppMotion.slow.inMilliseconds, lessThanOrEqualTo(400));
  });
}
