import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/fullscreen_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FullscreenService', () {
    late FullscreenService service;
    const channel = MethodChannel('dry_eye_widget/display');
    bool? mockResult;
    bool shouldThrow = false;

    setUp(() {
      service = FullscreenService();
      mockResult = null;
      shouldThrow = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'frontmostFullscreen') {
              if (shouldThrow) {
                throw PlatformException(
                  code: 'UNAVAILABLE',
                  message: 'Mock exception',
                );
              }
              return mockResult;
            }
            return null;
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'isFrontmostFullscreen returns true when channel returns true on macOS',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        mockResult = true;

        final result = await service.isFrontmostFullscreen();

        expect(result, isTrue);
      },
    );

    test(
      'isFrontmostFullscreen returns false when channel returns false on macOS',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        mockResult = false;

        final result = await service.isFrontmostFullscreen();

        expect(result, isFalse);
      },
    );

    test(
      'isFrontmostFullscreen returns false when channel returns null on macOS',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        mockResult = null;

        final result = await service.isFrontmostFullscreen();

        expect(result, isFalse);
      },
    );

    test(
      'isFrontmostFullscreen returns false when channel throws exception on macOS',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        shouldThrow = true;

        final result = await service.isFrontmostFullscreen();

        expect(result, isFalse);
      },
    );

    test(
      'isFrontmostFullscreen returns false on non-macOS platform (e.g. Windows)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        mockResult = true; // Even if channel would return true

        final result = await service.isFrontmostFullscreen();

        expect(result, isFalse);
      },
    );

    test(
      'isFrontmostFullscreen returns false on non-macOS platform (e.g. Linux)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        mockResult = true; // Even if channel would return true

        final result = await service.isFrontmostFullscreen();

        expect(result, isFalse);
      },
    );
  });
}
