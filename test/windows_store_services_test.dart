import 'dart:async';

import 'package:dry_eye_widget/services/notification_service.dart';
import 'package:dry_eye_widget/services/startup_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storeChannel = MethodChannel('dry_eye_widget/windows_store');
  const localChannel = MethodChannel('local_notifier');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> storeCalls;
  late List<MethodCall> localCalls;

  setUp(() {
    storeCalls = [];
    localCalls = [];
    messenger.setMockMethodCallHandler(localChannel, (call) async {
      localCalls.add(call);
      return true;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(storeChannel, null);
    messenger.setMockMethodCallHandler(localChannel, null);
  });

  test(
    'MSIX uses the package notifier and respects the app preference',
    () async {
      messenger.setMockMethodCallHandler(storeChannel, (call) async {
        storeCalls.add(call);
        return true;
      });
      final service = NotificationService(platform: TargetPlatform.windows);
      await service.init();
      service.enabled = false;
      await service.show('Title', 'Body');
      expect(storeCalls.map((call) => call.method), [
        'isPackaged',
        'initializeNotifications',
      ]);
      await service.showForced('Title <&>', 'Body "text"');
      expect(storeCalls.last.method, 'showNotification');
      expect(storeCalls.last.arguments, {
        'title': 'Title <&>',
        'body': 'Body "text"',
      });
      expect(localCalls, isEmpty);
    },
  );

  test(
    'failed MSIX notifier initialization never announces a notification',
    () async {
      messenger.setMockMethodCallHandler(storeChannel, (call) async {
        storeCalls.add(call);
        return call.method == 'isPackaged';
      });
      final service = NotificationService(platform: TargetPlatform.windows);
      await service.init();
      await service.showForced('Title', 'Body');
      expect(storeCalls.map((call) => call.method), [
        'isPackaged',
        'initializeNotifications',
      ]);
      expect(localCalls, isEmpty);
    },
  );

  test(
    'a blocked Windows toast is tolerated without retrying another identity',
    () async {
      messenger.setMockMethodCallHandler(storeChannel, (call) async {
        storeCalls.add(call);
        if (call.method == 'showNotification') {
          throw PlatformException(code: 'notifications_disabled');
        }
        return true;
      });
      final service = NotificationService(platform: TargetPlatform.windows);
      await service.init();
      await service.showForced('Title', 'Body');
      expect(storeCalls.last.method, 'showNotification');
      expect(localCalls, isEmpty);
    },
  );

  test('unpackaged Windows retains local notifications', () async {
    messenger.setMockMethodCallHandler(storeChannel, (call) async {
      storeCalls.add(call);
      return false;
    });
    final service = NotificationService(platform: TargetPlatform.windows);
    await service.init();
    await service.show('Title', 'Body');
    expect(storeCalls.map((call) => call.method), ['isPackaged']);
    expect(localCalls.where((call) => call.method == 'notify'), hasLength(1));
  });

  test('macOS notifications do not query Windows package APIs', () async {
    messenger.setMockMethodCallHandler(storeChannel, (call) async {
      fail('Windows API used on macOS');
    });
    final service = NotificationService(platform: TargetPlatform.macOS);
    await service.init();
    await service.show('Title', 'Body');
    expect(localCalls.where((call) => call.method == 'notify'), hasLength(1));
  });

  test(
    'MSIX startup waits for identity and returns the actual OS state',
    () async {
      final identity = Completer<bool>();
      messenger.setMockMethodCallHandler(storeChannel, (call) async {
        storeCalls.add(call);
        if (call.method == 'isPackaged') return identity.future;
        return false; // DisabledByUser must not appear enabled in preferences.
      });
      final service = StartupService(platform: TargetPlatform.windows)..init();
      final enabled = service.setEnabled(true);
      await Future<void>.delayed(Duration.zero);
      expect(storeCalls.map((call) => call.method), ['isPackaged']);
      identity.complete(true);
      expect(await enabled, isFalse);
      expect(storeCalls.last.method, 'setStartupEnabled');
      expect(storeCalls.last.arguments, isTrue);
      expect(await service.isEnabled(), isFalse);
      expect(storeCalls.last.method, 'getStartupEnabled');
    },
  );

  test(
    'MSIX startup disable returns state enforced by Windows policy',
    () async {
      messenger.setMockMethodCallHandler(storeChannel, (call) async {
        storeCalls.add(call);
        return true; // EnabledByPolicy may remain enabled after disable.
      });
      final service = StartupService(platform: TargetPlatform.windows)..init();
      expect(await service.setEnabled(false), isTrue);
      expect(storeCalls.last.arguments, isFalse);
    },
  );

  test('startup operation failure re-reads effective state', () async {
    messenger.setMockMethodCallHandler(storeChannel, (call) async {
      storeCalls.add(call);
      if (call.method == 'setStartupEnabled') {
        throw PlatformException(code: 'windows_store_error');
      }
      return true;
    });
    final service = StartupService(platform: TargetPlatform.windows)..init();
    expect(await service.setEnabled(false), isTrue);
    expect(storeCalls.map((call) => call.method), [
      'isPackaged',
      'setStartupEnabled',
      'getStartupEnabled',
    ]);
  });

  for (final unknownIdentity in ['missing', 'null']) {
    test(
      '$unknownIdentity identity never falls back to unpackaged integration',
      () async {
        messenger.setMockMethodCallHandler(storeChannel, (call) async {
          storeCalls.add(call);
          if (unknownIdentity == 'missing') throw MissingPluginException();
          return null;
        });
        final notifications = NotificationService(
          platform: TargetPlatform.windows,
        );
        final startup = StartupService(platform: TargetPlatform.windows)
          ..init();
        await notifications.init();
        await notifications.showForced('Title', 'Body');
        expect(await startup.setEnabled(true), isFalse);
        expect(await startup.isEnabled(), isFalse);
        expect(storeCalls.map((call) => call.method), [
          'isPackaged',
          'isPackaged',
        ]);
        expect(localCalls, isEmpty);
      },
    );
  }
}
