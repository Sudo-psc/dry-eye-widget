import 'package:dry_eye_widget/widgets/floating_ball.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captura determinística do vidro líquido e anel', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: const ValueKey('preview'),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF07121F), Color(0xFF173A5E)],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingBall(
                  isActive: false,
                  size: 32,
                  showProgress: true,
                  progress: 0.35,
                  orbIntensity: 0.72,
                ),
                FloatingBall(
                  isActive: false,
                  size: 56,
                  showProgress: true,
                  progress: 0.68,
                  orbIntensity: 0.78,
                ),
                FloatingBall(
                  isActive: false,
                  size: 96,
                  showProgress: true,
                  progress: 0.94,
                  orbIntensity: 0.9,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 650));

    await expectLater(
      find.byKey(const ValueKey('preview')),
      matchesGoldenFile(
        '../projects/dry-eye-widget-app/artifacts/liquid-orb-preview.png',
      ),
    );
  });
}
