import 'package:dry_eye_widget/models/environment_checklist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 6, 21);

  test('ambiente sem fatores de risco é adequado', () {
    final env = EnvironmentChecklist(updatedAt: now);
    expect(env.riskPoints, 0);
    expect(env.risk, EnvironmentRisk.adequate);
  });

  test('2-3 pontos => atenção', () {
    final env = EnvironmentChecklist(
      updatedAt: now,
      glare: true,
      airConditioning: true,
    );
    expect(env.riskPoints, 2);
    expect(env.risk, EnvironmentRisk.attention);
  });

  test('>=4 pontos => risco aumentado (ergonomia + fatores)', () {
    final env = EnvironmentChecklist(
      updatedAt: now,
      screenDistanceOk: false,
      brightnessOk: false,
      glare: true,
      dryAir: true,
    );
    expect(env.riskPoints, 4);
    expect(env.risk, EnvironmentRisk.increased);
  });

  test('serialização round-trip preserva fatores', () {
    final env = EnvironmentChecklist(
      updatedAt: now,
      monitorHeightOk: false,
      fanOnFace: true,
      multiMonitor: true,
    );
    final restored = EnvironmentChecklist.fromJson(env.toJson());
    expect(restored, isNotNull);
    expect(restored!.monitorHeightOk, isFalse);
    expect(restored.fanOnFace, isTrue);
    expect(restored.multiMonitor, isTrue);
    expect(restored.risk, env.risk);
  });

  test('fromJson tolera entrada inválida', () {
    expect(EnvironmentChecklist.fromJson(null), isNull);
    expect(EnvironmentChecklist.fromJson('{['), isNull);
  });
}
