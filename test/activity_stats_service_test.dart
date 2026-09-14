import 'dart:async';

import 'package:dry_eye_widget/models/activity_stats_data.dart';
import 'package:dry_eye_widget/services/activity_monitor_service.dart';
import 'package:dry_eye_widget/services/activity_stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dry_eye_widget/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<StorageService> newStorage() => StorageService.init();

  test('sample acumula cliques/teclas e tempo do app em foco', () async {
    final storage = await newStorage();
    final svc = ActivityStatsService(
      storage: storage,
      monitor: const ActivityMonitorService(),
      pollIntervalSeconds: 5,
    );
    final now = DateTime(2026, 7, 5, 10);

    svc.applySample(
      const ActivitySample(clicks: 12, keys: 40, frontApp: 'Safari'),
      now,
    );
    svc.applySample(
      const ActivitySample(clicks: 3, keys: 10, frontApp: 'Safari'),
      now,
    );
    svc.applySample(const ActivitySample(clicks: 1, frontApp: 'Xcode'), now);

    expect(svc.data.clicksForDay(now), 16);
    expect(svc.data.keysForDay(now), 50);
    // Cada sample atribui pollIntervalSeconds ao app em foco.
    expect(svc.data.appSecondsForDay(now)['Safari'], 10);
    expect(svc.data.appSecondsForDay(now)['Xcode'], 5);

    await svc.dispose();
  });

  test('flush persiste e recarrega', () async {
    final storage = await newStorage();
    final svc = ActivityStatsService(
      storage: storage,
      monitor: const ActivityMonitorService(),
      pollIntervalSeconds: 5,
    );
    final now = DateTime(2026, 7, 5, 10);
    svc.applySample(
      const ActivitySample(clicks: 5, keys: 20, frontApp: 'Mail'),
      now,
    );
    await svc.flush(now);

    final reloaded = ActivityStatsData.fromJson(
      storage.loadActivityStats().toJson(),
    );
    expect(reloaded.clicksForDay(now), 5);
    expect(reloaded.appSecondsForDay(now)['Mail'], 5);
    await svc.dispose();
  });

  test('clear zera os dados', () async {
    final storage = await newStorage();
    final svc = ActivityStatsService(
      storage: storage,
      monitor: const ActivityMonitorService(),
      pollIntervalSeconds: 5,
    );
    final now = DateTime(2026, 7, 5, 10);
    svc.applySample(const ActivitySample(clicks: 9, frontApp: 'X'), now);
    await svc.clear();
    expect(svc.data.clicksForDay(now), 0);
    await svc.dispose();
  });

  test('stop persiste amostras mesmo quando a coleta já está parada', () async {
    final storage = await newStorage();
    final svc = ActivityStatsService(
      storage: storage,
      monitor: const ActivityMonitorService(),
      pollIntervalSeconds: 5,
    );
    final now = DateTime(2026, 7, 16, 14);
    svc.applySample(
      const ActivitySample(clicks: 7, keys: 3, frontApp: 'Finder'),
      now,
    );

    await svc.stop();

    final persisted = storage.loadActivityStats();
    expect(persisted.clicksForDay(now), 7);
    expect(persisted.keysForDay(now), 3);
    expect(persisted.appSecondsForDay(now)['Finder'], 5);
    await svc.dispose();
  });

  test(
    'stop durante start não deixa timer ativo nem duplica ao religar',
    () async {
      final storage = await newStorage();
      fakeAsync((async) {
        final monitor = _ControlledMonitor()..startGate = Completer<void>();
        final svc = ActivityStatsService(storage: storage, monitor: monitor);
        unawaited(svc.start());
        async.flushMicrotasks();
        unawaited(svc.stop());
        async.flushMicrotasks();
        expect(monitor.stops, 0); // Aguarda o start nativo pendente.

        monitor.startGate!.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 15));
        expect(svc.isRunning, isFalse);
        expect(monitor.stops, 1);
        expect(monitor.polls, 0);

        unawaited(svc.start());
        unawaited(svc.start());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        expect(monitor.starts, 2);
        expect(monitor.polls, 2);
        unawaited(svc.stop());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        expect(monitor.polls, 2);
        unawaited(svc.dispose());
        async.flushMicrotasks();
      });
    },
  );

  test(
    'consulta lenta não sobrepõe polls nem aplica resposta após stop',
    () async {
      final storage = await newStorage();
      fakeAsync((async) {
        final pending = Completer<ActivitySample?>();
        final monitor = _ControlledMonitor()..pendingPolls.add(pending);
        final svc = ActivityStatsService(storage: storage, monitor: monitor);
        unawaited(svc.start());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 20));
        expect(monitor.polls, 1);

        unawaited(svc.stop());
        pending.complete(const ActivitySample(clicks: 9, frontApp: 'Browser'));
        async.flushMicrotasks();
        expect(svc.data.byDay, isEmpty);
        expect(storage.loadActivityStats().byDay, isEmpty);
        expect(monitor.stops, 1);
        unawaited(svc.dispose());
        async.flushMicrotasks();
      });
    },
  );

  test(
    'clear descarta consulta antiga e contadores nativos antes de retomar',
    () async {
      final storage = await newStorage();
      fakeAsync((async) {
        final pending = Completer<ActivitySample?>();
        final monitor = _ControlledMonitor()
          ..pendingPolls.add(pending)
          ..nextSample = const ActivitySample(clicks: 7, frontApp: 'Old app');
        final svc = ActivityStatsService(storage: storage, monitor: monitor);
        unawaited(svc.start());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));

        unawaited(svc.clear());
        async.flushMicrotasks();
        pending.complete(const ActivitySample(clicks: 9, frontApp: 'Old app'));
        async.flushMicrotasks();
        expect(monitor.polls, 2); // Consulta pendente e drenagem sem registrar.
        expect(svc.data.byDay, isEmpty);
        expect(storage.loadActivityStats().byDay, isEmpty);

        monitor.nextSample = const ActivitySample(
          clicks: 3,
          frontApp: 'New app',
        );
        async.elapse(const Duration(seconds: 5));
        expect(svc.data.clicksForDay(DateTime.now()), 3);
        expect(svc.data.appSecondsForDay(DateTime.now()), {'New app': 5});
        unawaited(svc.dispose());
        async.flushMicrotasks();
      });
    },
  );

  test(
    'dispose durante poll não atualiza nem notifica serviço encerrado',
    () async {
      final storage = await newStorage();
      fakeAsync((async) {
        final pending = Completer<ActivitySample?>();
        final monitor = _ControlledMonitor()..pendingPolls.add(pending);
        final svc = ActivityStatsService(storage: storage, monitor: monitor);
        unawaited(svc.start());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 5));
        unawaited(svc.dispose());
        pending.complete(const ActivitySample(clicks: 9, frontApp: 'Browser'));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        expect(svc.data.byDay, isEmpty);
        expect(monitor.polls, 1);
        expect(monitor.stops, 1);
      });
    },
  );
}

class _ControlledMonitor extends ActivityMonitorService {
  Completer<void>? startGate;
  final pendingPolls = <Completer<ActivitySample?>>[];
  ActivitySample? nextSample;
  int starts = 0;
  int stops = 0;
  int polls = 0;

  @override
  Future<void> start() async {
    starts++;
    await startGate?.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<ActivitySample?> poll() async {
    polls++;
    if (pendingPolls.isNotEmpty) return pendingPolls.removeAt(0).future;
    final sample = nextSample;
    nextSample = null;
    return sample;
  }
}
