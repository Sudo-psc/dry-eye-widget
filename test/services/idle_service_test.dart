import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/idle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IdleService', () {
    late IdleService idleService;
    const MethodChannel channel = MethodChannel('dry_eye_widget/idle');

    setUp(() {
      idleService = IdleService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('idleSeconds returns value from channel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'idleSeconds') {
          return 42.5;
        }
        return null;
      });

      final result = await idleService.idleSeconds();
      expect(result, 42.5);
    });

    test('idleSeconds returns 0 when channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'idleSeconds') {
          return null;
        }
        return null;
      });

      final result = await idleService.idleSeconds();
      expect(result, 0.0);
    });

    test('idleSeconds returns 0 when channel throws PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'idleSeconds') {
          throw PlatformException(code: 'UNAVAILABLE', message: 'Idle info unavailable');
        }
        return null;
      });

      final result = await idleService.idleSeconds();
      expect(result, 0.0);
    });

    test('idleSeconds returns 0 when channel throws an unexpected error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'idleSeconds') {
          throw Exception('Unexpected error');
        }
        return null;
      });

      final result = await idleService.idleSeconds();
      expect(result, 0.0);
    });
  });
}
