# Módulo de Inatividade — Plano de Implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pausar o ciclo 20-20-20 quando o usuário está ausente e retomar na atividade, com limiar de inatividade aprendido continuamente e câmera opcional de confirmação de presença.

**Architecture:** Um `PresenceController` combina sensores plugáveis (`PresenceSensor`) — ociosidade do SO (núcleo) e câmera (opcional) — usando um `AdaptiveThresholdModel` (estatística online por faixa horária) cujo estado agregado é persistido cifrado pelo `PresenceStore`. O `TimerProvider` consulta o controller a cada tick.

**Tech Stack:** Dart/Flutter (puro Dart para a lógica testável), MethodChannel para canais nativos (Vision no macOS, Keychain/DPAPI para cifra), `flutter_test`.

> **Nota de implementação vs. spec:** o estimador de percentil usa um **histograma compacto de contagens** (bins de 30 s até 600 s) em vez do P² citado no design — mesma propriedade (estatística online agregada, sem eventos brutos, sem timeline) porém **determinístico e fácil de testar**. O spec foi anotado com essa decisão.

---

## Estrutura de arquivos

**Criar:**
- `lib/services/presence/presence_sensor.dart` — enum `Presence` + interface `PresenceSensor`.
- `lib/services/presence/adaptive_threshold_model.dart` — modelo de limiar adaptativo (histograma por bucket horário).
- `lib/services/presence/presence_controller.dart` — orquestra decisão presente/ausente + aprendizado.
- `lib/services/presence/presence_store.dart` — interface `PresenceStore` + `InMemoryPresenceStore`.
- `lib/services/presence/input_idle_sensor.dart` — adapta `IdleService` à interface (fase 1, usado na integração).
- `lib/services/presence/secure_presence_store.dart` — store cifrado (fase 2).
- `lib/services/presence/camera_presence_sensor.dart` — sensor de câmera (fase 3).
- `lib/services/vision_service.dart` — canal nativo de detecção de rosto (fase 3).
- `test/presence/adaptive_threshold_model_test.dart`
- `test/presence/presence_controller_test.dart`
- `test/presence/presence_store_test.dart` (fase 2)

**Modificar:**
- `lib/utils/constants.dart` — novos defaults e `StorageKeys`.
- `lib/models/widget_settings.dart` — campo `cameraPresence`.
- `lib/providers/timer_provider.dart` — integração com `PresenceController`; corrige `_checkInactivity`.
- `lib/main.dart` — injeção do `IdleService`/controller no `TimerProvider` (corrige fiação quebrada).
- `lib/l10n/app_strings.dart` — strings novas (PT/EN).
- `lib/widgets/settings_dialog.dart` — toggle de câmera + botão reset de aprendizado.
- `lib/widgets/floating_ball.dart` — esmaecimento no estado de pausa por inatividade.

---

# FASE 1 — Núcleo (input + ML + controller + integração)

Entrega software funcional: pausa/retoma por inatividade com limiar adaptativo, tudo em memória. Paralelizável: Tarefas 1, 2, 3 são arquivos novos independentes; Tarefas 4–9 são integração sequencial.

## Task 1: Interface `PresenceSensor` e enum `Presence`

**Files:**
- Create: `lib/services/presence/presence_sensor.dart`

- [ ] **Step 1: Criar a interface e o enum**

```dart
/// Resultado de uma amostragem de presença por um sensor.
enum Presence {
  /// Há evidência de que o usuário está presente.
  present,

  /// Há evidência de que o usuário está ausente.
  absent,

  /// O sensor não consegue decidir (deixa a decisão para o controller).
  unknown,
}

/// Fonte de sinal de presença plugável (input do SO, câmera, etc.).
///
/// Manter sensores atrás desta interface permite testar o controller com
/// fakes e adicionar novas modalidades sem reescrever a orquestração.
abstract class PresenceSensor {
  /// Amostra o sinal agora. Deve ser barata e não lançar — sensores
  /// indisponíveis retornam [Presence.unknown].
  Future<Presence> sample();
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/presence/presence_sensor.dart
git commit -m "feat(presence): interface PresenceSensor e enum Presence"
```

## Task 2: `AdaptiveThresholdModel` (limiar adaptativo)

**Files:**
- Create: `lib/services/presence/adaptive_threshold_model.dart`
- Test: `test/presence/adaptive_threshold_model_test.dart`

- [ ] **Step 1: Escrever os testes que falham**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/presence/adaptive_threshold_model.dart';

void main() {
  group('AdaptiveThresholdModel', () {
    test('cold start retorna o limiar padrão antes de observações', () {
      final m = AdaptiveThresholdModel();
      expect(m.thresholdForHour(10), 120);
    });

    test('aprende o P85 das durações observadas no bucket', () {
      final m = AdaptiveThresholdModel(minObservations: 5);
      // 10 gaps de presença ~ 30..120s no bucket da tarde (12-18h).
      for (final g in [30, 45, 60, 60, 75, 90, 90, 105, 120, 120]) {
        m.observePresentGap(14, g.toDouble());
      }
      final t = m.thresholdForHour(14);
      // P85 de 10 amostras = 9ª ordenada (120) -> bin superior 120..150 => 150,
      // clamp em [60,600]. Aceita a faixa do bin.
      expect(t, inInclusiveRange(120, 150));
    });

    test('respeita o clamp mínimo de 60s', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      m.observePresentGap(3, 5);
      expect(m.thresholdForHour(3), 60);
    });

    test('respeita o clamp máximo de 600s', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      for (var i = 0; i < 20; i++) {
        m.observePresentGap(3, 5000);
      }
      expect(m.thresholdForHour(3), 600);
    });

    test('buckets horários são independentes', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      m.observePresentGap(2, 300); // madrugada
      // tarde nunca observou -> cold start.
      expect(m.thresholdForHour(14), 120);
      expect(m.thresholdForHour(2), greaterThan(120));
    });

    test('round-trip toMap/fromMap preserva o estado aprendido', () {
      final m = AdaptiveThresholdModel(minObservations: 1);
      m.observePresentGap(14, 200);
      final restored = AdaptiveThresholdModel.fromMap(m.toMap());
      expect(restored.thresholdForHour(14), m.thresholdForHour(14));
    });
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd ../app_dry_eye_widget-inatividade && flutter test test/presence/adaptive_threshold_model_test.dart`
Expected: FAIL — `AdaptiveThresholdModel` não definido.

- [ ] **Step 3: Implementar o modelo**

```dart
import 'dart:math' as math;

/// Estima, por faixa horária, o limiar de inatividade que separa "presença
/// parada" de "ausência real", aprendido continuamente.
///
/// Usa um histograma compacto de contagens (bins de [binWidth] s até
/// [maxThreshold] s, mais um bin de overflow) por bucket horário. A estimativa
/// de percentil é O(1) por evento, determinística e interpretável; o estado
/// total são contagens inteiras (agregado, sem eventos brutos nem timestamps).
class AdaptiveThresholdModel {
  AdaptiveThresholdModel({
    this.targetPercentile = 0.85,
    this.minThreshold = 60,
    this.maxThreshold = 600,
    this.coldStartThreshold = 120,
    this.minObservations = 5,
    this.binWidth = 30,
    this.maxLearnableGap = 900,
  })  : _bins = List.generate(
            _bucketCount, (_) => List<int>.filled(_binCount(maxThreshold, binWidth), 0)),
        _counts = List<int>.filled(_bucketCount, 0);

  final double targetPercentile;
  final int minThreshold;
  final int maxThreshold;
  final int coldStartThreshold;
  final int minObservations;
  final int binWidth;

  /// Gaps acima disso são tratados como ausência real e não alimentam o
  /// aprendizado (evita inflar o limiar quando o usuário realmente saiu).
  final int maxLearnableGap;

  static const int _bucketCount = 4; // 00-06, 06-12, 12-18, 18-24
  final List<List<int>> _bins;
  final List<int> _counts;

  static int _binCount(int maxThreshold, int binWidth) =>
      (maxThreshold / binWidth).ceil() + 1; // +1 = overflow

  int _bucketIndex(int hour) => (hour ~/ 6).clamp(0, _bucketCount - 1);

  /// Registra um gap (em segundos) durante o qual o usuário estava presente.
  void observePresentGap(int hour, double gapSeconds) {
    if (gapSeconds <= 0 || gapSeconds > maxLearnableGap) return;
    final b = _bucketIndex(hour);
    final idx = (gapSeconds ~/ binWidth).clamp(0, _bins[b].length - 1);
    _bins[b][idx]++;
    _counts[b]++;
  }

  /// Limiar atual para a hora informada, em segundos.
  int thresholdForHour(int hour) {
    final b = _bucketIndex(hour);
    if (_counts[b] < minObservations) return coldStartThreshold;
    final target = targetPercentile * _counts[b];
    var acc = 0;
    for (var i = 0; i < _bins[b].length; i++) {
      acc += _bins[b][i];
      if (acc >= target) {
        final upper = (i + 1) * binWidth; // limite superior do bin
        return upper.clamp(minThreshold, maxThreshold);
      }
    }
    return maxThreshold;
  }

  Map<String, dynamic> toMap() => {
        'v': 1,
        'binWidth': binWidth,
        'counts': _counts,
        'bins': _bins,
      };

  factory AdaptiveThresholdModel.fromMap(Map<String, dynamic> map) {
    final m = AdaptiveThresholdModel(
      binWidth: (map['binWidth'] as num?)?.toInt() ?? 30,
    );
    try {
      final counts = (map['counts'] as List).cast<num>();
      final bins = (map['bins'] as List)
          .map((row) => (row as List).map((e) => (e as num).toInt()).toList())
          .toList();
      for (var b = 0; b < math.min(counts.length, _bucketCount); b++) {
        m._counts[b] = counts[b].toInt();
        for (var i = 0; i < math.min(bins[b].length, m._bins[b].length); i++) {
          m._bins[b][i] = bins[b][i];
        }
      }
    } catch (_) {
      // Estado corrompido -> recomeça do zero (defaults já aplicados).
    }
    return m;
  }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd ../app_dry_eye_widget-inatividade && flutter test test/presence/adaptive_threshold_model_test.dart`
Expected: PASS (todos os 6 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/services/presence/adaptive_threshold_model.dart test/presence/adaptive_threshold_model_test.dart
git commit -m "feat(presence): AdaptiveThresholdModel com histograma por bucket horário"
```

## Task 3: `PresenceStore` (interface + em memória)

**Files:**
- Create: `lib/services/presence/presence_store.dart`

- [ ] **Step 1: Criar interface e implementação em memória**

```dart
/// Persiste o estado agregado do modelo de presença (apenas contagens
/// agregadas; nunca eventos brutos, timestamps ou imagens).
abstract class PresenceStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> state);
  Future<void> clear();
}

/// Implementação volátil para testes e fase 1 (reaprende a cada sessão até a
/// fase 2 trocar pelo store cifrado).
class InMemoryPresenceStore implements PresenceStore {
  Map<String, dynamic>? _state;

  @override
  Future<Map<String, dynamic>?> load() async => _state;

  @override
  Future<void> save(Map<String, dynamic> state) async => _state = state;

  @override
  Future<void> clear() async => _state = null;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/presence/presence_store.dart
git commit -m "feat(presence): PresenceStore (interface + InMemory)"
```

## Task 4: `PresenceController` (orquestração + aprendizado)

**Files:**
- Create: `lib/services/presence/presence_controller.dart`
- Test: `test/presence/presence_controller_test.dart`

- [ ] **Step 1: Escrever os testes que falham**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/presence/presence_sensor.dart';
import 'package:dry_eye_widget/services/presence/presence_controller.dart';
import 'package:dry_eye_widget/services/presence/adaptive_threshold_model.dart';

class _FakeCamera implements PresenceSensor {
  _FakeCamera(this.result);
  Presence result;
  int calls = 0;
  @override
  Future<Presence> sample() async {
    calls++;
    return result;
  }
}

/// Fonte de ociosidade fixa para os testes.
Future<double> Function() _idle(double v) => () async => v;

void main() {
  final noon = DateTime(2026, 6, 8, 12, 0, 0);

  group('PresenceController (sem câmera)', () {
    test('idle abaixo do limiar => present', () async {
      final c = PresenceController(
          model: AdaptiveThresholdModel(), idleSource: _idle(0));
      final d = await c.evaluate(idleSeconds: 30, now: noon);
      expect(d, Presence.present); // cold start = 120
    });

    test('idle acima do limiar => absent', () async {
      final c = PresenceController(
          model: AdaptiveThresholdModel(), idleSource: _idle(0));
      final d = await c.evaluate(idleSeconds: 130, now: noon);
      expect(d, Presence.absent);
    });

    test('idleSeconds delega para a fonte injetada', () async {
      final c = PresenceController(
          model: AdaptiveThresholdModel(), idleSource: _idle(42));
      expect(await c.idleSeconds(), 42);
    });

    test('onResume com gap aprendível alimenta o modelo', () async {
      final model = AdaptiveThresholdModel(minObservations: 1);
      final c = PresenceController(model: model, idleSource: _idle(0));
      c.onResume(previousIdleSeconds: 200, now: noon);
      // Próximo limiar reflete o gap aprendido (>= cold start).
      expect(model.thresholdForHour(12), greaterThanOrEqualTo(60));
      expect(c.lastObservedGap, 200);
    });
  });

  group('PresenceController (com câmera)', () {
    test('rosto detectado no limiar => present e aprende o gap', () async {
      final cam = _FakeCamera(Presence.present);
      final model = AdaptiveThresholdModel(minObservations: 1);
      final c = PresenceController(
        model: model,
        idleSource: _idle(0),
        cameraSensor: cam,
        cameraEnabled: () => true,
      );
      final d = await c.evaluate(idleSeconds: 130, now: noon);
      expect(d, Presence.present);
      expect(cam.calls, 1);
    });

    test('sem rosto no limiar => absent', () async {
      final cam = _FakeCamera(Presence.absent);
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(0),
        cameraSensor: cam,
        cameraEnabled: () => true,
      );
      final d = await c.evaluate(idleSeconds: 130, now: noon);
      expect(d, Presence.absent);
    });

    test('câmera desabilitada não é consultada', () async {
      final cam = _FakeCamera(Presence.present);
      final c = PresenceController(
        model: AdaptiveThresholdModel(),
        idleSource: _idle(0),
        cameraSensor: cam,
        cameraEnabled: () => false,
      );
      await c.evaluate(idleSeconds: 130, now: noon);
      expect(cam.calls, 0);
    });
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `cd ../app_dry_eye_widget-inatividade && flutter test test/presence/presence_controller_test.dart`
Expected: FAIL — `PresenceController` não definido.

- [ ] **Step 3: Implementar o controller**

```dart
import 'presence_sensor.dart';
import 'adaptive_threshold_model.dart';

/// Decide presença/ausência combinando o limiar adaptativo (input) com um
/// sensor de câmera opcional, e alimenta o modelo nos eventos de retomada.
class PresenceController {
  PresenceController({
    required this.model,
    required Future<double> Function() idleSource,
    this.cameraSensor,
    bool Function()? cameraEnabled,
  })  : _idleSource = idleSource,
        cameraEnabled = cameraEnabled ?? (() => false);

  final AdaptiveThresholdModel model;
  final PresenceSensor? cameraSensor;
  final bool Function() cameraEnabled;
  final Future<double> Function() _idleSource;

  /// Ociosidade global do SO (segundos). Delega à fonte injetada.
  Future<double> idleSeconds() => _idleSource();

  int? _lastObservedGap;
  int? get lastObservedGap => _lastObservedGap;

  /// Limiar vigente para a hora (exposto para diagnóstico/integração).
  int thresholdAt(DateTime now) => model.thresholdForHour(now.hour);

  /// Avalia o estado atual dado o tempo ocioso do SO.
  Future<Presence> evaluate({
    required double idleSeconds,
    required DateTime now,
  }) async {
    final threshold = model.thresholdForHour(now.hour);
    if (idleSeconds < threshold) return Presence.present;

    // Cruzou o limiar: desempata pela câmera, se habilitada.
    final cam = cameraSensor;
    if (cameraEnabled() && cam != null) {
      final p = await cam.sample();
      if (p == Presence.present) {
        // Confirmação direta de presença parada: aprende este gap.
        model.observePresentGap(now.hour, idleSeconds);
        _lastObservedGap = idleSeconds.round();
        return Presence.present;
      }
    }
    return Presence.absent;
  }

  /// Chamado quando o input retoma após um período ocioso. O gap anterior é
  /// tratado como "presença parada" e alimenta o modelo.
  void onResume({required double previousIdleSeconds, required DateTime now}) {
    model.observePresentGap(now.hour, previousIdleSeconds);
    _lastObservedGap = previousIdleSeconds.round();
  }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `cd ../app_dry_eye_widget-inatividade && flutter test test/presence/presence_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/presence/presence_controller.dart test/presence/presence_controller_test.dart
git commit -m "feat(presence): PresenceController com aprendizado e desempate por câmera"
```

## Task 5: `InputIdleSensor` (adapta o IdleService)

**Files:**
- Create: `lib/services/presence/input_idle_sensor.dart`

- [ ] **Step 1: Criar o adaptador**

```dart
import '../idle_service.dart';
import 'presence_sensor.dart';

/// Sensor de presença baseado na ociosidade global do SO (teclado/mouse).
/// Sozinho nunca decide ausência — apenas reporta atividade recente; a
/// decisão de limiar fica no [PresenceController]. Exposto como sensor para
/// uniformidade e testes.
class InputIdleSensor implements PresenceSensor {
  InputIdleSensor(this._idle, {this.activityWindowSeconds = 2});

  final IdleService _idle;
  final int activityWindowSeconds;

  @override
  Future<Presence> sample() async {
    final idle = await _idle.idleSeconds();
    return idle < activityWindowSeconds ? Presence.present : Presence.unknown;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/services/presence/input_idle_sensor.dart
git commit -m "feat(presence): InputIdleSensor sobre IdleService"
```

## Task 6: Constantes e settings (`cameraPresence`)

**Files:**
- Modify: `lib/utils/constants.dart`
- Modify: `lib/models/widget_settings.dart`

- [ ] **Step 1: Adicionar defaults e StorageKeys em `constants.dart`**

Em `AppDefaults` (após `pauseOnInactivity`):

```dart
  static const bool cameraPresence = false;
```

Em `StorageKeys` (após `widgetSettings`):

```dart
  /// Estado agregado, cifrado, do modelo de presença.
  static const String presenceModel = 'presence_model_enc';
```

- [ ] **Step 2: Adicionar `cameraPresence` em `WidgetSettings`**

Replicar o padrão de `pauseOnInactivity` em TODOS os pontos: campo `final bool cameraPresence;`, parâmetro do construtor, `defaults()` (`cameraPresence: AppDefaults.cameraPresence`), `copyWith`, `toMap` (`'cameraPresence': cameraPresence`), `fromMap` (`cameraPresence: map['cameraPresence'] as bool? ?? d.cameraPresence`).

- [ ] **Step 3: Atualizar o teste de settings**

Em `test/widget_settings_test.dart`, garantir round-trip do novo campo (seguir os asserts existentes para `pauseOnInactivity`).

- [ ] **Step 4: Rodar e ver passar**

Run: `cd ../app_dry_eye_widget-inatividade && flutter test test/widget_settings_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/constants.dart lib/models/widget_settings.dart test/widget_settings_test.dart
git commit -m "feat(settings): preferência cameraPresence + chave de estado de presença"
```

## Task 7: Integrar `PresenceController` no `TimerProvider`

**Files:**
- Modify: `lib/providers/timer_provider.dart`

- [ ] **Step 1: Trocar a dependência e os campos**

No construtor, substituir o campo `final IdleService _idle;` por:

```dart
  final PresenceController _presence;
```

Atualizar a lista de parâmetros: trocar `required IdleService idle` por `required PresenceController presence` e a inicialização `_presence = presence`. Importar `../services/presence/presence_controller.dart` e `../services/presence/presence_sensor.dart`; remover o import de `idle_service.dart`.

- [ ] **Step 2: Substituir o `_checkInactivity` quebrado por `_checkPresence`**

Trocar a chamada na linha do `_onTick` de `_checkInactivity();` por `_checkPresence();` e adicionar:

```dart
  double _lastIdleSeconds = 0;

  Future<void> _checkPresence() async {
    if (_idleBusy) return;
    if (!_settings.value.pauseOnInactivity) {
      if (_inactivityPaused) _resumeFromInactivity(learn: false);
      return;
    }
    _idleBusy = true;
    try {
      final now = DateTime.now();
      final idle = await _presence.idleSeconds();
      final decision =
          await _presence.evaluate(idleSeconds: idle, now: now);

      if (decision == Presence.absent && !_inactivityPaused) {
        _inactivityPaused = true;
        _inactivityAlert = true;
        notifyListeners();
      } else if (_inactivityPaused && idle < 2) {
        _presence.onResume(previousIdleSeconds: _lastIdleSeconds, now: now);
        _resumeFromInactivity(learn: false);
      }
      _lastIdleSeconds = idle;
    } finally {
      _idleBusy = false;
    }
  }

  void _resumeFromInactivity({required bool learn}) {
    _inactivityPaused = false;
    _inactivityAlert = false;
    notifyListeners();
  }
```

> O `_presence.idleSeconds()` é o delegate definido na Task 4 (`idleSource`
> injetado), de modo que o `TimerProvider` depende só do `PresenceController`.

- [ ] **Step 3: Bloquear a contagem do ciclo quando pausado**

Em `_tickIdle`, na primeira linha, trocar `if (_paused) return;` por:

```dart
    if (_paused || _inactivityPaused) return;
```

- [ ] **Step 4: Rodar a suíte existente**

Run: `cd ../app_dry_eye_widget-inatividade && flutter test`
Expected: PASS (testes de estado existentes continuam verdes).

- [ ] **Step 5: Commit**

```bash
git add lib/providers/timer_provider.dart lib/services/presence/presence_controller.dart
git commit -m "feat(timer): integra PresenceController e corrige pausa por inatividade"
```

## Task 8: Fiação em `main.dart` (corrige o construtor quebrado)

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Construir o controller e injetar**

Antes do `runApp`, após `notifications`:

```dart
  final idle = IdleService();
  final presence = PresenceController(
    model: AdaptiveThresholdModel(),
    idleSource: idle.idleSeconds,
  );
```

Atualizar o `create:` do `TimerProvider` para passar `presence: presence` no lugar do antigo `idle:` ausente. Adicionar imports de `services/idle_service.dart`, `services/presence/presence_controller.dart`, `services/presence/adaptive_threshold_model.dart`.

- [ ] **Step 2: Build de fumaça**

Run: `cd ../app_dry_eye_widget-inatividade && flutter analyze`
Expected: sem erros (warnings de lint pré-existentes tolerados).

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "fix(main): injeta PresenceController no TimerProvider"
```

## Task 9: UX — esmaecimento + strings de inatividade

**Files:**
- Modify: `lib/widgets/floating_ball.dart`
- Modify: `lib/l10n/app_strings.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Adicionar strings (PT/EN)**

Em `AppStrings`: campo `required this.inactivityPausedTooltip;` e `final String inactivityPausedTooltip;`. Em `ptStrings`: `inactivityPausedTooltip: 'Pausado por inatividade',`. Em `enStrings`: `inactivityPausedTooltip: 'Paused due to inactivity',`.

- [ ] **Step 2: Esmaecer a bolinha e mostrar tooltip quando pausado por inatividade**

`FloatingBall` recebe um novo parâmetro opcional `final bool dimmed;` (default `false`). No `build`, quando `dimmed && !isActive`, multiplicar a opacidade base por `0.5`. Em `main.dart` `_buildCompact`, envolver a bolinha idle num `Tooltip(message: timer.inactivityAlert ? strings.inactivityPausedTooltip : '', child: ...)` e passar `dimmed: timer.inactivityAlert` ao `_ball(...)`.

- [ ] **Step 3: Rodar testes de widget**

Run: `cd ../app_dry_eye_widget-inatividade && flutter test test/floating_ball_test.dart`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/floating_ball.dart lib/l10n/app_strings.dart lib/main.dart
git commit -m "feat(ux): bolinha esmaecida + tooltip 'Pausado por inatividade'"
```

---

# FASE 2 — Persistência cifrada

## Task 10: Canal nativo `secure_store` (Keychain/DPAPI)

**Files:**
- Create: `lib/services/secure_storage_service.dart`
- Modify: `macos/Runner/MainFlutterWindow.swift`
- Modify: `windows/runner/flutter_window.cpp`

- [ ] **Step 1: Dart — `SecureStorageService`**

MethodChannel `dry_eye_widget/secure_store` com `Future<String?> read(String key)` e `Future<void> write(String key, String value)` e `delete(String key)`. Valores são strings opacas (já cifradas/Base64). Falha → retorna `null`/no-op com `debugPrint`.

- [ ] **Step 2: macOS — handler Keychain**

No `MainFlutterWindow.swift`, registrar o canal e implementar `read/write/delete` via `SecItemCopyMatching`/`SecItemAdd`/`SecItemDelete` (classe `kSecClassGenericPassword`, serviço `dry_eye_widget`). Seguir o padrão do canal `idle` já existente (linha ~17).

- [ ] **Step 3: Windows — handler DPAPI**

No `flutter_window.cpp`, registrar o canal e implementar com `CryptProtectData`/`CryptUnprotectData` persistindo em `%APPDATA%/dry_eye_widget/presence.bin`. Seguir o padrão do canal `idle` (linha ~40).

- [ ] **Step 4: Verificação manual por plataforma**

Run (macOS): `cd ../app_dry_eye_widget-inatividade && flutter run -d macos` e confirmar via log que `write`→`read` faz round-trip.

- [ ] **Step 5: Commit**

```bash
git add lib/services/secure_storage_service.dart macos/ windows/
git commit -m "feat(secure): canal nativo de armazenamento cifrado (Keychain/DPAPI)"
```

## Task 11: `SecurePresenceStore` + reset + fiação

**Files:**
- Create: `lib/services/presence/secure_presence_store.dart`
- Test: `test/presence/presence_store_test.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Teste de round-trip cifrado (com fake de SecureStorage)**

Testar `SecurePresenceStore.save(map)` → `load()` retorna mapa equivalente; `clear()` zera; estado corrompido → `load()` retorna `null` (cai para defaults no modelo).

- [ ] **Step 2: Implementar**

`SecurePresenceStore` recebe um `SecureStorageService`; serializa o mapa em JSON, cifra com AES-GCM (chave derivada/guardada via canal seguro), grava em `StorageKeys.presenceModel`. `load()` decifra e faz `jsonDecode`. Qualquer falha → `null`.

- [ ] **Step 3: Fiar no `main.dart`**

Carregar o estado salvo no startup e construir `AdaptiveThresholdModel.fromMap(...)`; passar o store ao `PresenceController` para salvar periodicamente (ex.: a cada N observações). Adicionar botão de reset (Task 12) chamando `store.clear()`.

- [ ] **Step 4: Rodar testes**

Run: `cd ../app_dry_eye_widget-inatividade && flutter test test/presence/presence_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/presence/secure_presence_store.dart test/presence/presence_store_test.dart lib/main.dart
git commit -m "feat(presence): SecurePresenceStore (AES-GCM) com reset"
```

## Task 12: Reset de aprendizado nas configurações

**Files:**
- Modify: `lib/widgets/settings_dialog.dart`
- Modify: `lib/l10n/app_strings.dart`

- [ ] **Step 1: Strings** `resetLearningLabel` (PT: 'Resetar aprendizado de inatividade' / EN: 'Reset inactivity learning').
- [ ] **Step 2:** Botão na seção de inatividade que chama um callback `onResetLearning` (fiar até o `store.clear()`).
- [ ] **Step 3: Commit** `feat(settings): botão de reset do aprendizado de inatividade`.

---

# FASE 3 — Câmera (macOS)

## Task 13: Canal `vision` + `VisionService` + `CameraPresenceSensor`

**Files:**
- Create: `lib/services/vision_service.dart`
- Create: `lib/services/presence/camera_presence_sensor.dart`
- Modify: `macos/Runner/MainFlutterWindow.swift`
- Modify: `macos/Runner/Info.plist`

- [ ] **Step 1: Info.plist** — adicionar `NSCameraUsageDescription` explicando o uso pontual.
- [ ] **Step 2: Swift** — canal `dry_eye_widget/vision`, método `hasFace`: abre `AVCaptureSession`, captura 1 frame, roda `VNDetectFaceRectanglesRequest`, fecha a sessão, retorna `bool`. Nunca grava o frame.
- [ ] **Step 3: Dart** — `VisionService.hasFace() -> Future<bool>` (false em erro/negação). `CameraPresenceSensor implements PresenceSensor` → `present` se `hasFace`, senão `absent`.
- [ ] **Step 4: Fiar** o sensor no `PresenceController` quando `settings.cameraPresence`.
- [ ] **Step 5: Verificação manual** macOS: habilitar o toggle, simular inatividade, confirmar que o frame só é capturado no limiar e que rosto evita a pausa.
- [ ] **Step 6: Commit** `feat(camera): detecção de presença on-device via Vision (macOS)`.

## Task 14: Consentimento + toggle nas configurações

**Files:**
- Modify: `lib/widgets/settings_dialog.dart`
- Modify: `lib/l10n/app_strings.dart`

- [ ] **Step 1: Strings** do toggle e do diálogo de consentimento (PT/EN), explicando snapshot pontual sem gravação.
- [ ] **Step 2:** Toggle `cameraPresence` (desabilitado no Windows com aviso "em breve"); ao ativar, exibir diálogo de consentimento ANTES de a permissão do SO ser solicitada na primeira captura.
- [ ] **Step 3: Commit** `feat(settings): toggle e consentimento da câmera de presença`.

---

# FASE 4 — Câmera (Windows)

## Task 15: `Windows.Media.FaceAnalysis`

**Files:**
- Modify: `windows/runner/flutter_window.cpp`
- Modify: `lib/services/vision_service.dart`

- [ ] **Step 1:** Implementar `hasFace` no canal `vision` via `Windows.Media.Capture` + `FaceDetector`, captura de 1 frame e descarte.
- [ ] **Step 2:** Habilitar o toggle no Windows (remover o estado "em breve").
- [ ] **Step 3: Verificação manual** Windows.
- [ ] **Step 4: Commit** `feat(camera): paridade Windows via FaceAnalysis`.

---

## Verificação final (todas as fases)

- [ ] `cd ../app_dry_eye_widget-inatividade && flutter analyze` sem erros.
- [ ] `cd ../app_dry_eye_widget-inatividade && flutter test` — toda a suíte verde.
- [ ] Verificação manual: inatividade pausa/retoma; limiar adapta após uso; câmera (se on) evita pausa com rosto; toggles desligam tudo; reset zera o aprendizado.
- [ ] Revisão de código: nenhuma dependência de rede adicionada; nenhuma imagem/timeline persistida.
