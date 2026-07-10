import 'package:dry_eye_widget/models/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('frequências de piscada têm intervalos distintos e ordenados', () {
    expect(BlinkReminderFrequency.discreet.intervalMs, 12000);
    expect(BlinkReminderFrequency.normal.intervalMs, 7500);
    expect(BlinkReminderFrequency.frequent.intervalMs, 4500);
    expect(
      BlinkReminderFrequency.discreet.intervalMs,
      greaterThan(BlinkReminderFrequency.normal.intervalMs),
    );
    expect(
      BlinkReminderFrequency.normal.intervalMs,
      greaterThan(BlinkReminderFrequency.frequent.intervalMs),
    );
  });
}
