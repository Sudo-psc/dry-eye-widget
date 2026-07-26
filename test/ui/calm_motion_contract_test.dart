import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('superfícies ativas não reintroduzem loops decorativos', () {
    const paths = [
      'lib/widgets/floating_ball.dart',
      'lib/widgets/gentle_break_card.dart',
      'lib/widgets/glass_overlay.dart',
      'lib/widgets/timer_display.dart',
    ];

    for (final path in paths) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains('.repeat(')),
        reason: '$path deve usar apenas feedback transitório',
      );
    }
  });
}
