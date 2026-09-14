import 'package:dry_eye_widget/services/secure_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dry_eye_widget/secure_store');
  const store = ChannelSecureStore();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('chave ausente retorna null sem simular erro do SO', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);

    expect(await store.read('presence_model_enc'), isNull);
  });

  test(
    'leitura retorna o valor e gravação e exclusão aguardam o canal',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'read' ? 'aggregate-state' : null;
      });

      expect(await store.read('presence_model_enc'), 'aggregate-state');
      await store.write('presence_model_enc', 'aggregate-state');
      await store.delete('presence_model_enc');

      expect(calls.map((call) => call.method), ['read', 'write', 'delete']);
      expect(calls[1].arguments, {
        'key': 'presence_model_enc',
        'value': 'aggregate-state',
      });
    },
  );

  for (final operation in ['read', 'write', 'delete']) {
    test('$operation propaga falha nativa sem reportar sucesso', () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'secure_store_failed',
          details: {'operation': operation, 'status': 5},
        );
      });

      final result = switch (operation) {
        'read' => store.read('presence_model_enc'),
        'write' => store.write('presence_model_enc', 'aggregate-state'),
        _ => store.delete('presence_model_enc'),
      };

      await expectLater(
        result,
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'secure_store_failed',
          ),
        ),
      );
    });
  }
}
