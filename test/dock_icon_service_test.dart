import 'dart:io' show Platform;

import 'package:dry_eye_widget/services/dock_icon_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dry_eye_widget/dock');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  void mockChannel(Object? Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(calls.clear);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  // O caminho nativo só existe no macOS; no Windows o serviço cai no
  // setSkipTaskbar do window_manager, que não é exercitável aqui.
  group('macOS', skip: !Platform.isMacOS, () {
    test('ocultar pede a política de acessório ao nativo', () async {
      mockChannel((_) => true);

      final applied = await const DockIconService().setHidden(true);

      expect(applied, isTrue);
      expect(calls.single.method, 'setDockIconVisible');
      expect(calls.single.arguments, {'visible': false});
    });

    test('mostrar pede a política regular ao nativo', () async {
      mockChannel((_) => true);

      final applied = await const DockIconService().setHidden(false);

      expect(applied, isTrue);
      expect(calls.single.arguments, {'visible': true});
    });

    test('reporta falha quando o sistema não aplica a política', () async {
      mockChannel((_) => false);

      expect(await const DockIconService().setHidden(true), isFalse);
    });

    test('canal indisponível não derruba o app', () async {
      mockChannel((_) => throw PlatformException(code: 'unavailable'));

      expect(await const DockIconService().setHidden(true), isFalse);
    });

    test('isHidden inverte a visibilidade informada pelo sistema', () async {
      mockChannel((_) => false);

      expect(await const DockIconService().isHidden(), isTrue);
      expect(calls.single.method, 'isDockIconVisible');
    });
  });

  // applyWithRetry coordena tentativas em cima de setHidden/isHidden, então é
  // exercitada com um serviço falso — roda em qualquer plataforma, inclusive na
  // CI Linux, onde o grupo do canal nativo é pulado.
  group('applyWithRetry', () {
    test('sucesso na primeira tentativa não repete', () async {
      final dock = _FakeDock(results: [true]);

      expect(await dock.applyWithRetry(true, retryDelay: Duration.zero), isTrue);
      expect(dock.requested, [true]);
    });

    test('repete uma vez quando o sistema recusa', () async {
      final dock = _FakeDock(results: [false, true]);

      expect(await dock.applyWithRetry(true, retryDelay: Duration.zero), isTrue);
      expect(dock.requested, [true, true]);
    });

    test('devolve o estado real quando as duas tentativas falham', () async {
      final dock = _FakeDock(results: [false, false], actual: false);

      expect(
        await dock.applyWithRetry(true, retryDelay: Duration.zero),
        isFalse,
      );
      expect(dock.requested, [true, true]);
      expect(dock.queried, 1);
    });

    test('null quando nem dá para consultar o estado', () async {
      final dock = _FakeDock(results: [false, false]);

      expect(
        await dock.applyWithRetry(true, retryDelay: Duration.zero),
        isNull,
      );
    });

    // O ponto do achado de corrida: uma preferência antiga que falhou não pode
    // continuar tentando depois que o usuário já escolheu o contrário.
    test('aborta a repetição quando a preferência mudou no meio', () async {
      final dock = _FakeDock(results: [false, true]);

      final settled = await dock.applyWithRetry(
        true,
        retryDelay: Duration.zero,
        isStale: () => true,
      );

      expect(settled, isNull);
      expect(dock.requested, [true]);
      expect(dock.queried, 0);
    });
  });
}

/// Serviço de Dock sem plataforma: devolve [results] em ordem para cada
/// `setHidden` e [actual] para a consulta de estado.
class _FakeDock extends DockIconService {
  _FakeDock({required this.results, this.actual});

  final List<bool> results;
  final bool? actual;
  final List<bool> requested = [];
  int queried = 0;

  @override
  Future<bool> setHidden(bool hidden) async {
    requested.add(hidden);
    return results[requested.length - 1];
  }

  @override
  Future<bool?> isHidden() async {
    queried++;
    return actual;
  }
}
