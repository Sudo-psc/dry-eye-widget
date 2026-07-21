import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS runner registers the launch-at-startup channel', () {
    final source = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(source, contains('import ServiceManagement'));
    expect(source, contains('name: "launch_at_startup"'));
    expect(source, contains('case "launchAtStartupIsEnabled"'));
    expect(source, contains('case "launchAtStartupSetEnabled"'));
    expect(source, contains('SMAppService.mainApp'));
  });
}
