import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/vision_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('dry_eye_widget/vision');
  late VisionService visionService;

  setUp(() {
    visionService = const VisionService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  group('VisionService', () {
    test('returns true when channel returns true', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'hasFace') {
          return true;
        }
        return null;
      });

      final result = await visionService.hasFace();
      expect(result, isTrue);
    });

    test('returns false when channel returns false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'hasFace') {
          return false;
        }
        return null;
      });

      final result = await visionService.hasFace();
      expect(result, isFalse);
    });

    test('returns false when channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'hasFace') {
          return null;
        }
        return null;
      });

      final result = await visionService.hasFace();
      expect(result, isFalse);
    });

    test('returns false when channel throws exception', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR', message: 'Simulated error');
      });

      final result = await visionService.hasFace();
      expect(result, isFalse);
    });
  });
}
