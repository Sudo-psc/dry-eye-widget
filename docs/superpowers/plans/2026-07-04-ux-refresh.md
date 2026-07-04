# UX Refresh v1.20.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refinamento visual/UX do app inteiro: design system em `lib/ui/`, fontes locais Inter/RobotoMono, DVRS com gauge e transições, pausa com anel + respiração + streak, dashboard com KPIs e menu com cores por grupo.

**Architecture:** Camada `lib/ui/` de componentes puros de apresentação (tema, cards, anéis, gauge, gráfico) criada primeiro com TDD; telas existentes migram para esses componentes em tarefas independentes. Nenhum fluxo, texto médico-legal ou modelo de dados muda.

**Tech Stack:** Flutter desktop (macOS/Windows), Material 3 dark, CustomPainter para gauge/anéis/gráfico, fontes locais em assets (sem fetch em runtime).

**Spec:** `docs/superpowers/specs/2026-07-04-ux-refresh-design.md`

## Global Constraints

- Suíte atual (156 testes) permanece verde em TODAS as tarefas; `flutter analyze` sem issues ao fim de cada tarefa.
- Linguagem sempre de triagem/educativa; NENHUM texto médico-legal muda.
- Animações one-shot ≤800ms; loops (respiração) só durante a pausa (`AppState.fase1`); nada anima em idle.
- `Semantics` preservados; cor nunca é o único indicador; `uiScale` (textScaler) continua valendo.
- `lib/ui/` não importa nada de `lib/widgets/` nem de services (apenas Flutter + `utils/constants.dart`).
- Commits: Conventional Commits, um por tarefa, com trailer `Claude-Session: https://claude.ai/code/session_01LkHKjRyEPoKJ8MmA7SGpdF`.
- Versão final: `1.20.0+55` (pubspec `version`), `msix_version: 1.20.0.0`, `AppInfo.version = '1.20.0'`.

---

### Task 1: Fontes locais (Inter + RobotoMono) e remoção do google_fonts

**Files:**
- Create: `assets/fonts/Inter-Regular.ttf`, `assets/fonts/Inter-Medium.ttf`, `assets/fonts/Inter-SemiBold.ttf`, `assets/fonts/Inter-Bold.ttf`, `assets/fonts/RobotoMono-Regular.ttf`, `assets/fonts/RobotoMono-Bold.ttf`
- Modify: `pubspec.yaml` (seção `fonts:`, remover dep `google_fonts`), `lib/widgets/timer_display.dart`, `lib/widgets/gentle_break_card.dart`

**Interfaces:**
- Consumes: —
- Produces: famílias `'Inter'` (pesos 400/500/600/700) e `'RobotoMono'` (400/700) disponíveis por nome em `TextStyle(fontFamily: ...)` para todas as tarefas seguintes.

- [ ] **Step 1: Baixar as fontes (licença OFL/Apache)**

```bash
cd /Users/philipecruz/app_dry_eye_widget
curl -sL -o /tmp/inter.zip https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip
unzip -o -j /tmp/inter.zip "extras/ttf/Inter-Regular.ttf" "extras/ttf/Inter-Medium.ttf" "extras/ttf/Inter-SemiBold.ttf" "extras/ttf/Inter-Bold.ttf" -d assets/fonts/
curl -sL -o assets/fonts/RobotoMono-Regular.ttf "https://github.com/googlefonts/RobotoMono/raw/main/fonts/ttf/RobotoMono-Regular.ttf"
curl -sL -o assets/fonts/RobotoMono-Bold.ttf "https://github.com/googlefonts/RobotoMono/raw/main/fonts/ttf/RobotoMono-Bold.ttf"
file assets/fonts/Inter-*.ttf assets/fonts/RobotoMono-*.ttf
```

Expected: cada arquivo reporta `TrueType Font data`. Se alguma URL falhar (404), localizar o release oficial mais recente do mesmo repositório (`rsms/inter` releases / `googlefonts/RobotoMono` em `fonts/ttf/`) e repetir — NÃO usar fontes de terceiros.

- [ ] **Step 2: Declarar as fontes no pubspec**

Em `pubspec.yaml`, dentro de `flutter:` (após a lista `assets:` existente), adicionar:

```yaml
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
          weight: 400
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
    - family: RobotoMono
      fonts:
        - asset: assets/fonts/RobotoMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/RobotoMono-Bold.ttf
          weight: 700
```

- [ ] **Step 3: Trocar usos runtime do google_fonts por famílias locais**

Em `lib/widgets/timer_display.dart`: remover `import 'package:google_fonts/google_fonts.dart';` e trocar
`GoogleFonts.robotoMono(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1.5)`
por
`const TextStyle(fontFamily: 'RobotoMono', fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1.5)`.

Em `lib/widgets/gentle_break_card.dart`: remover o import do google_fonts e trocar CADA `GoogleFonts.inter(...)` por `TextStyle(fontFamily: 'Inter', ...)` e cada `GoogleFonts.robotoMono(...)` por `TextStyle(fontFamily: 'RobotoMono', ...)`, mantendo os demais parâmetros idênticos.

> Desvio consciente da spec: a spec previa "barra de progresso linear" no
> cartão suave, mas ele JÁ possui um anel de countdown (`_CountdownDial`),
> superior à barra — o layout do cartão fica como está; só a tipografia muda.

- [ ] **Step 4: Remover a dependência**

Em `pubspec.yaml`, apagar a linha `google_fonts: ^8.1.0`. Rodar:

```bash
flutter pub get && grep -rn "google_fonts" lib/ && echo "FALHOU: ainda há uso" || echo OK
```

Expected: `OK`.

- [ ] **Step 5: Verificar suíte e analyze**

Run: `flutter analyze && flutter test`
Expected: `No issues found!` e `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/fonts/ lib/widgets/timer_display.dart lib/widgets/gentle_break_card.dart
git commit -m "feat(ui): embute Inter e RobotoMono como assets e remove google_fonts"
```

---

### Task 2: Tema central (`app_theme.dart`) aplicado ao app

**Files:**
- Create: `lib/ui/app_theme.dart`
- Modify: `lib/main.dart` (classe `DryEyeApp`, ~linha 224)
- Test: `test/ui/app_theme_test.dart`

**Interfaces:**
- Consumes: famílias `Inter`/`RobotoMono` (Task 1); `AppColors.idleBall` de `utils/constants.dart`.
- Produces: `ThemeData buildAppTheme()`; `class AppSemanticColors extends ThemeExtension<AppSemanticColors>` com campos `Color success, caution, risk, danger`; `class AppRadii { static const double sm = 12, md = 16, lg = 24; }`. Acesso: `Theme.of(context).extension<AppSemanticColors>()!`.

- [ ] **Step 1: Escrever o teste que falha**

`test/ui/app_theme_test.dart`:

```dart
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tema usa Inter, dark M3 e scaffold transparente', () {
    final theme = buildAppTheme();
    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
    expect(theme.textTheme.bodyMedium!.fontFamily, 'Inter');
  });

  test('expõe cores semânticas via ThemeExtension', () {
    final theme = buildAppTheme();
    final sem = theme.extension<AppSemanticColors>();
    expect(sem, isNotNull);
    expect(sem!.success, isNot(sem.danger));
  });

  test('botões padronizados: radius 12 e altura mínima 44', () {
    final theme = buildAppTheme();
    final shape = theme.filledButtonTheme.style!.shape!.resolve({})
        as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(AppRadii.sm));
    final minSize = theme.filledButtonTheme.style!.minimumSize!.resolve({})!;
    expect(minSize.height, 44);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/ui/app_theme_test.dart`
Expected: FAIL (arquivo `lib/ui/app_theme.dart` inexistente).

- [ ] **Step 3: Implementar `lib/ui/app_theme.dart`**

```dart
import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Raios de borda padronizados do design system.
class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

/// Cores semânticas (alinhadas às faixas de risco do DVRS).
/// A cor NUNCA é o único indicador — sempre acompanhada de texto/ícone.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.caution,
    required this.risk,
    required this.danger,
  });

  final Color success;
  final Color caution;
  final Color risk;
  final Color danger;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? caution,
    Color? risk,
    Color? danger,
  }) => AppSemanticColors(
        success: success ?? this.success,
        caution: caution ?? this.caution,
        risk: risk ?? this.risk,
        danger: danger ?? this.danger,
      );

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      caution: Color.lerp(caution, other.caution, t)!,
      risk: Color.lerp(risk, other.risk, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

ButtonStyle _buttonStyle() => ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
      ),
    );

/// Tema central do app: dark Material 3, seed azul, Inter local.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.idleBall,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: Colors.transparent,
    filledButtonTheme: FilledButtonThemeData(style: _buttonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle()),
    textButtonTheme: TextButtonThemeData(style: _buttonStyle()),
    extensions: const [
      AppSemanticColors(
        success: Colors.green,
        caution: Colors.orange,
        risk: Colors.deepOrange,
        danger: Colors.red,
      ),
    ],
  );
}
```

- [ ] **Step 4: Aplicar no `main.dart`**

Em `lib/main.dart`, adicionar `import 'ui/app_theme.dart';` e na classe `DryEyeApp` substituir o bloco
`theme: ThemeData.dark(useMaterial3: true).copyWith(scaffoldBackgroundColor: Colors.transparent, colorScheme: ColorScheme.fromSeed(seedColor: AppColors.idleBall, brightness: Brightness.dark)),`
por `theme: buildAppTheme(),`. Se `AppColors`/`constants.dart` ficarem sem uso no import de `main.dart`, NÃO remover — outras partes do arquivo usam.

- [ ] **Step 5: Rodar testes e analyze**

Run: `flutter test test/ui/app_theme_test.dart && flutter analyze && flutter test`
Expected: tudo verde.

- [ ] **Step 6: Commit**

```bash
git add lib/ui/app_theme.dart lib/main.dart test/ui/app_theme_test.dart
git commit -m "feat(ui): tema central com Inter, radius e cores semânticas"
```

---

### Task 3: `GlassCard` + `SectionHeader`

**Files:**
- Create: `lib/ui/glass_card.dart`, `lib/ui/section_header.dart`
- Test: `test/ui/glass_card_test.dart`

**Interfaces:**
- Consumes: `AppRadii` (Task 2).
- Produces: `GlassCard({Key? key, required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16), VoidCallback? onTap})`; `SectionHeader(String title, {Key? key, Widget? trailing})`.

- [ ] **Step 1: Teste que falha** — `test/ui/glass_card_test.dart`:

```dart
import 'package:dry_eye_widget/ui/glass_card.dart';
import 'package:dry_eye_widget/ui/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GlassCard renderiza filho e responde a tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          const GlassCard(child: Text('conteudo')),
          GlassCard(onTap: () => taps++, child: const Text('clicavel')),
          const SectionHeader('Título de seção'),
        ]),
      ),
    ));
    expect(find.text('conteudo'), findsOneWidget);
    expect(find.text('Título de seção'), findsOneWidget);
    await tester.tap(find.text('clicavel'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** — `flutter test test/ui/glass_card_test.dart` → FAIL (import inexistente).

- [ ] **Step 3: Implementar** — `lib/ui/glass_card.dart`:

```dart
import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Card translúcido padrão do app (vidro sobre o LiquidGlass das telas).
/// Substitui os antigos `_card()` duplicados por tela.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
```

`lib/ui/section_header.dart`:

```dart
import 'package:flutter/material.dart';

/// Título de seção padronizado (14/w600) com espaço para ação à direita.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}
```

- [ ] **Step 4: Verificar** — `flutter test test/ui/glass_card_test.dart && flutter analyze` → verde.
- [ ] **Step 5: Commit** — `git add lib/ui/glass_card.dart lib/ui/section_header.dart test/ui/glass_card_test.dart && git commit -m "feat(ui): GlassCard e SectionHeader"`

---

### Task 4: `ProgressRing` + `StatTile`

**Files:**
- Create: `lib/ui/progress_ring.dart`, `lib/ui/stat_tile.dart`
- Test: `test/ui/stat_tile_test.dart`

**Interfaces:**
- Consumes: `GlassCard` (Task 3).
- Produces: `ProgressRing({Key? key, required double value, double size = 56, double strokeWidth = 6, Color? color, Widget? child})` (value 0..1, anima 0→value em 800ms); `StatTile({Key? key, required String label, required String value, double? ringValue, IconData? icon, Color? color, Widget? footer})`.

- [ ] **Step 1: Teste que falha** — `test/ui/stat_tile_test.dart`:

```dart
import 'package:dry_eye_widget/ui/progress_ring.dart';
import 'package:dry_eye_widget/ui/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatTile mostra valor, rótulo e anel', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StatTile(
          label: 'Adesão às pausas',
          value: '80%',
          ringValue: 0.8,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('Adesão às pausas'), findsOneWidget);
    expect(find.byType(ProgressRing), findsOneWidget);
  });

  testWidgets('StatTile com ícone e footer', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StatTile(
          label: 'Tela hoje',
          value: '2h 15min',
          icon: Icons.timer_outlined,
          footer: Text('rodapé'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(find.text('rodapé'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** — FAIL (arquivos inexistentes).

- [ ] **Step 3: Implementar** — `lib/ui/progress_ring.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Anel de progresso animado (0→[value] em 800ms, one-shot).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 56,
    this.strokeWidth = 6,
    this.color,
    this.child,
  });

  /// Progresso 0..1.
  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ringColor = color ?? Theme.of(context).colorScheme.primary;
    final track = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    return Semantics(
      label: 'Progresso: ${(value.clamp(0.0, 1.0) * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
            value: v,
            color: ringColor,
            track: track,
            strokeWidth: strokeWidth,
          ),
          child: SizedBox.square(
            dimension: size,
            child: child == null ? null : Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final double value;
  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final arcRect = rect.deflate(inset);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * value, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color;
}
```

`lib/ui/stat_tile.dart`:

```dart
import 'package:flutter/material.dart';

import 'glass_card.dart';
import 'progress_ring.dart';

/// KPI compacto: valor grande + rótulo, com anel de progresso ou ícone.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.ringValue,
    this.icon,
    this.color,
    this.footer,
  });

  final String label;
  final String value;

  /// Quando definido (0..1), mostra um [ProgressRing] à esquerda.
  final double? ringValue;
  final IconData? icon;
  final Color? color;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (ringValue != null)
                ProgressRing(
                  value: ringValue!,
                  size: 48,
                  strokeWidth: 5,
                  color: accent,
                  child: Icon(icon ?? Icons.check, size: 18, color: accent),
                )
              else if (icon != null)
                Icon(icon, size: 28, color: accent),
              if (ringValue != null || icon != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 10), footer!],
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verificar** — `flutter test test/ui/stat_tile_test.dart && flutter analyze` → verde.
- [ ] **Step 5: Commit** — `git add lib/ui/progress_ring.dart lib/ui/stat_tile.dart test/ui/stat_tile_test.dart && git commit -m "feat(ui): ProgressRing e StatTile"`

---

### Task 5: `ScoreGauge` (gauge semicircular animado)

**Files:**
- Create: `lib/ui/score_gauge.dart`
- Test: `test/ui/score_gauge_test.dart`

**Interfaces:**
- Consumes: —
- Produces: `ScoreGauge({Key? key, required int score, required Color color, List<Color>? segments, double size = 200})` — score 0..100; `segments` (opcional) pinta o trilho de fundo em 5 segmentos iguais (faixas do DVRS); valor central anima 0→score.

- [ ] **Step 1: Teste que falha** — `test/ui/score_gauge_test.dart`:

```dart
import 'package:dry_eye_widget/ui/score_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ScoreGauge mostra o score final e /100', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: ScoreGauge(score: 54, color: Colors.deepOrange)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('54'), findsOneWidget);
    expect(find.text('/100'), findsOneWidget);
  });

  testWidgets('ScoreGauge aceita segmentos de faixa', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ScoreGauge(
          score: 90,
          color: Colors.red,
          segments: [
            Colors.green,
            Colors.orange,
            Colors.deepOrange,
            Colors.red,
            Colors.red,
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('90'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** — FAIL.

- [ ] **Step 3: Implementar** — `lib/ui/score_gauge.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gauge semicircular 0–100 com valor central animado (one-shot ~800ms).
/// O valor numérico e o texto acompanham SEMPRE a cor (cor nunca é o único
/// indicador).
class ScoreGauge extends StatelessWidget {
  const ScoreGauge({
    super.key,
    required this.score,
    required this.color,
    this.segments,
    this.size = 200,
  });

  /// Score final (0..100).
  final int score;

  /// Cor do arco de progresso (classificação atual).
  final Color color;

  /// Cores do trilho de fundo em 5 segmentos iguais (opcional).
  final List<Color>? segments;

  final double size;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: 'Score $score de 100',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score.clamp(0, 100) / 100),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => SizedBox(
          width: size,
          height: size * 0.62,
          child: CustomPaint(
            painter: _GaugePainter(
              value: v,
              color: color,
              segments: segments,
              track: onSurface.withValues(alpha: 0.12),
            ),
            child: Align(
              alignment: const Alignment(0, 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(v * 100).round()}',
                    style: TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.bold,
                      height: 1,
                      color: color,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: size * 0.07,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.value,
    required this.color,
    required this.track,
    this.segments,
  });

  final double value;
  final Color color;
  final Color track;
  final List<Color>? segments;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.07;
    final center = Offset(size.width / 2, size.height * 0.94);
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Trilho: 5 segmentos (faixas) ou trilho único.
    final segs = segments;
    if (segs != null && segs.isNotEmpty) {
      final sweep = math.pi / segs.length;
      for (var i = 0; i < segs.length; i++) {
        final paint = Paint()
          ..color = segs[i].withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke;
        canvas.drawArc(rect, math.pi + i * sweep, sweep * 0.96, false, paint);
      }
    } else {
      final paint = Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawArc(rect, math.pi, math.pi, false, paint);
    }

    // Arco de progresso.
    final progress = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi * value, false, progress);

    // Marcador na ponta do arco.
    final angle = math.pi + math.pi * value;
    final knob = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(knob, stroke * 0.55, Paint()..color = Colors.white);
    canvas.drawCircle(knob, stroke * 0.38, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color;
}
```

- [ ] **Step 4: Verificar** — `flutter test test/ui/score_gauge_test.dart && flutter analyze` → verde.
- [ ] **Step 5: Commit** — `git add lib/ui/score_gauge.dart test/ui/score_gauge_test.dart && git commit -m "feat(ui): ScoreGauge semicircular animado"`

---

### Task 6: `TrendLineChart` (linha + área, escala configurável)

**Files:**
- Create: `lib/ui/trend_line_chart.dart`
- Test: `test/ui/trend_line_chart_test.dart`

**Interfaces:**
- Consumes: —
- Produces: `TrendLineChart({Key? key, required List<(DateTime, double)> points, double? minY, double? maxY, bool showGrid = true, bool dateLabels = true, double height = 160, Color? color, String Function(double)? formatValue})`. DVRS usa `minY: 0, maxY: 100`; sparkline usa defaults (`minY/maxY` nulos → auto-escala, `showGrid: false, dateLabels: false, height: 56`).

- [ ] **Step 1: Teste que falha** — `test/ui/trend_line_chart_test.dart`:

```dart
import 'package:dry_eye_widget/ui/trend_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renderiza com 0, 1 e N pontos sem lançar', (tester) async {
    for (final points in [
      const <(DateTime, double)>[],
      [(DateTime(2026, 7, 1), 42.0)],
      [
        (DateTime(2026, 6, 1), 20.0),
        (DateTime(2026, 6, 8), 55.0),
        (DateTime(2026, 6, 15), 40.0),
      ],
    ]) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TrendLineChart(points: points, minY: 0, maxY: 100),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('modo sparkline (sem grid/labels) renderiza', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TrendLineChart(
          points: [
            (DateTime(2026, 7, 1), 3600.0),
            (DateTime(2026, 7, 2), 7200.0),
          ],
          showGrid: false,
          dateLabels: false,
          height: 56,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** — FAIL.

- [ ] **Step 3: Implementar** — `lib/ui/trend_line_chart.dart` (evolução do `_DvrsLineChartPainter` de `lib/widgets/dvrs/dvrs_history_view.dart`, que será removido na Task 9):

```dart
import 'package:flutter/material.dart';

/// Gráfico de linha com área em gradiente e último ponto destacado.
/// Escala fixa (minY/maxY) ou automática; grid e labels opcionais
/// (modo sparkline: showGrid=false, dateLabels=false, height baixa).
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.points,
    this.minY,
    this.maxY,
    this.showGrid = true,
    this.dateLabels = true,
    this.height = 160,
    this.color,
    this.formatValue,
  });

  final List<(DateTime, double)> points;
  final double? minY;
  final double? maxY;
  final bool showGrid;
  final bool dateLabels;
  final double height;
  final Color? color;

  /// Formata o valor do último ponto (default: inteiro).
  final String Function(double)? formatValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _TrendPainter(
          points: points,
          minY: minY,
          maxY: maxY,
          showGrid: showGrid,
          dateLabels: dateLabels,
          lineColor: color ?? theme.colorScheme.primary,
          axisColor: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          gridColor: theme.colorScheme.onSurface.withValues(alpha: 0.10),
          formatValue: formatValue ?? (v) => v.round().toString(),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.minY,
    required this.maxY,
    required this.showGrid,
    required this.dateLabels,
    required this.lineColor,
    required this.axisColor,
    required this.gridColor,
    required this.formatValue,
  });

  final List<(DateTime, double)> points;
  final double? minY;
  final double? maxY;
  final bool showGrid;
  final bool dateLabels;
  final Color lineColor;
  final Color axisColor;
  final Color gridColor;
  final String Function(double) formatValue;

  static const _leftPad = 28.0;
  static const _bottomPad = 16.0;
  static const _topPad = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final left = showGrid ? _leftPad : 0.0;
    final bottom = dateLabels ? _bottomPad : 2.0;
    final chartW = size.width - left;
    final chartH = size.height - bottom - _topPad;
    if (chartW <= 0 || chartH <= 0) return;

    // Escala.
    var lo = minY ?? 0;
    var hi = maxY ?? 1;
    if (minY == null || maxY == null) {
      if (points.isEmpty) {
        lo = 0;
        hi = 1;
      } else {
        final values = points.map((p) => p.$2);
        lo = values.reduce((a, b) => a < b ? a : b);
        hi = values.reduce((a, b) => a > b ? a : b);
        if (hi - lo < 1e-6) {
          hi = lo + 1;
          lo = lo - 1 < 0 ? 0 : lo - 1;
        }
      }
    }

    double yFor(double v) =>
        _topPad + chartH * (1 - ((v - lo) / (hi - lo)).clamp(0.0, 1.0));

    if (showGrid) {
      final gridPaint = Paint()
        ..color = gridColor
        ..strokeWidth = 0.5;
      final style = TextStyle(color: axisColor, fontSize: 9);
      for (var i = 0; i <= 5; i++) {
        final v = lo + (hi - lo) * i / 5;
        final y = yFor(v);
        canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
        final tp = TextPainter(
          text: TextSpan(text: v.round().toString(), style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(0, y - tp.height / 2));
      }
    }

    if (points.isEmpty) return;

    double xFor(int i) => points.length == 1
        ? left + chartW / 2
        : left + chartW * (i / (points.length - 1));

    // Área em gradiente.
    final line = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(xFor(i), yFor(points[i].$2));
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    if (points.length > 1) {
      final area = Path.from(line)
        ..lineTo(xFor(points.length - 1), _topPad + chartH)
        ..lineTo(xFor(0), _topPad + chartH)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.28),
              lineColor.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromLTWH(left, _topPad, chartW, chartH),
          ),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Pontos + destaque do último.
    final dot = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(xFor(i), yFor(points[i].$2)), 2.5, dot);
    }
    final last = Offset(xFor(points.length - 1), yFor(points.last.$2));
    canvas.drawCircle(last, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(last, 4, dot);
    final valueTp = TextPainter(
      text: TextSpan(
        text: formatValue(points.last.$2),
        style: TextStyle(
          color: lineColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    valueTp.paint(
      canvas,
      Offset(
        (last.dx - valueTp.width / 2).clamp(left, size.width - valueTp.width),
        (last.dy - valueTp.height - 7).clamp(0, size.height),
      ),
    );

    if (dateLabels) {
      String fmt(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
      final style = TextStyle(color: axisColor, fontSize: 9);
      final first = TextPainter(
        text: TextSpan(text: fmt(points.first.$1), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      first.paint(canvas, Offset(left, size.height - first.height));
      if (points.length > 1) {
        final lastTp = TextPainter(
          text: TextSpan(text: fmt(points.last.$1), style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        lastTp.paint(
          canvas,
          Offset(size.width - lastTp.width, size.height - lastTp.height),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points || old.lineColor != lineColor;
}
```

- [ ] **Step 4: Verificar** — `flutter test test/ui/trend_line_chart_test.dart && flutter analyze` → verde.
- [ ] **Step 5: Commit** — `git add lib/ui/trend_line_chart.dart test/ui/trend_line_chart_test.dart && git commit -m "feat(ui): TrendLineChart com área e escala configurável"`

---

### Task 7: Resultado do DVRS com gauge e barras animadas

**Files:**
- Modify: `lib/widgets/dvrs/dvrs_result_view.dart`, `lib/widgets/dvrs/dvrs_ui.dart`

**Interfaces:**
- Consumes: `ScoreGauge` (Task 5), `GlassCard`/`SectionHeader` (Task 3).
- Produces: `DvrsUi.classificationSegments` (`List<Color>` — cores das 5 faixas em ordem) usada também pelo dashboard (Task 12).

- [ ] **Step 1: Adicionar helper de segmentos em `dvrs_ui.dart`**

Dentro de `class DvrsUi`, adicionar:

```dart
  /// Cores das 5 faixas de classificação em ordem (0–19 … 80–100).
  static List<Color> get classificationSegments => [
        for (final c in DvrsClassification.values) classificationColor(c),
      ];
```

- [ ] **Step 2: Reformar `dvrs_result_view.dart`**

Modificações (mantendo TODOS os textos existentes — os testes atuais dependem deles):
1. Importar `../../ui/glass_card.dart`, `../../ui/section_header.dart`, `../../ui/score_gauge.dart`.
2. No primeiro card (score): substituir o bloco `Row` do número `'${result.totalScore}'`/`'/100'` e o `DvrsUi.riskBar(...)` por:

```dart
              Center(
                child: ScoreGauge(
                  score: result.totalScore,
                  color: color,
                  segments: DvrsUi.classificationSegments,
                ),
              ),
              const SizedBox(height: 10),
              Center(child: DvrsUi.classificationChip(result.classification)),
```

3. Substituir o método local `_card(theme, child: ...)` por `GlassCard(child: ...)` em todos os usos e REMOVER o método `_card`.
4. Trocar o `Text('Scores por domínio', ...)` pelo `SectionHeader('Scores por domínio')` (remover o `SizedBox(height: 12)` seguinte — o header já tem espaçamento).
5. Animar as barras de domínio: em `_domainBar`, envolver o `LinearProgressIndicator` num `TweenAnimationBuilder<double>`:

```dart
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct / 100),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor:
                  theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
```

6. `DvrsUi.riskBar` fica sem uso? Verificar com `grep -rn "riskBar" lib/`; se o único uso era aqui e no dashboard (que será atualizado na Task 11), manter o método por ora (a Task 11 remove se ninguém mais usar) — NÃO remover nesta task.

- [ ] **Step 3: Verificar** — `flutter test test/dvrs_screen_test.dart && flutter test && flutter analyze`
Expected: tudo verde (os testes procuram textos como 'Scores por domínio' e 'Baixo risco visual digital', que continuam presentes).

- [ ] **Step 4: Commit** — `git add lib/widgets/dvrs/ && git commit -m "feat(dvrs): resultado com ScoreGauge, GlassCard e barras animadas"`

---

### Task 8: Perguntas do DVRS — transições, chip de domínio e check ao salvar

**Files:**
- Modify: `lib/widgets/dvrs/dvrs_screen.dart`, `lib/widgets/dvrs/dvrs_ui.dart`

**Interfaces:**
- Consumes: `kDvrsDomainLabels` (existente em `dvrs_definitions.dart`).
- Produces: `DvrsUi.domainIcon(DvrsDomain)` e `DvrsUi.domainColor(DvrsDomain)`.

- [ ] **Step 1: Helpers de domínio em `dvrs_ui.dart`**

Adicionar em `class DvrsUi` (import de `dvrs_assessment.dart` já existe):

```dart
  /// Ícone de cada domínio do DVRS.
  static IconData domainIcon(DvrsDomain d) {
    switch (d) {
      case DvrsDomain.symptoms:
        return Icons.visibility_outlined;
      case DvrsDomain.functional:
        return Icons.speed_outlined;
      case DvrsDomain.exposure:
        return Icons.devices_outlined;
      case DvrsDomain.environment:
        return Icons.light_mode_outlined;
      case DvrsDomain.warning:
        return Icons.priority_high;
    }
  }

  /// Cor de apoio de cada domínio (nunca o único indicador).
  static Color domainColor(DvrsDomain d) {
    switch (d) {
      case DvrsDomain.symptoms:
        return Colors.lightBlue;
      case DvrsDomain.functional:
        return Colors.teal;
      case DvrsDomain.exposure:
        return Colors.amber;
      case DvrsDomain.environment:
        return Colors.purpleAccent;
      case DvrsDomain.warning:
        return Colors.redAccent;
    }
  }
```

- [ ] **Step 2: Chip de domínio + transição em `dvrs_screen.dart`**

Em `_DvrsScreenState`:
1. Adicionar campo `bool _navForward = true;` — setar `true` em `_next()` e `false` em `_back()` (antes do `setState`).
2. Em `_questionsView`, envolver o `ListView` (conteúdo da pergunta) num `AnimatedSwitcher`:

```dart
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(_navForward ? 0.08 : -0.08, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: ListView(
              key: ValueKey(_index),
              padding: const EdgeInsets.all(24),
              children: [ /* conteúdo atual da pergunta */ ],
            ),
          ),
        ),
```

3. No topo do conteúdo da pergunta (antes do `Text(q.title, ...)`), inserir o chip do domínio:

```dart
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: DvrsUi.domainColor(q.domain)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(DvrsUi.domainIcon(q.domain),
                            size: 14, color: DvrsUi.domainColor(q.domain)),
                        const SizedBox(width: 6),
                        Text(
                          kDvrsDomainLabels[q.domain] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: DvrsUi.domainColor(q.domain),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
```

(Import de `dvrs_ui.dart` e `dvrs_definitions.dart` já existem no arquivo.)

4. Botão salvar com check: no `_resultScreen`, no `FilledButton.icon` de salvar, trocar `icon: const Icon(Icons.save_alt)` por:

```dart
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                _saved ? Icons.check_circle : Icons.save_alt,
                key: ValueKey(_saved),
              ),
            ),
```

- [ ] **Step 3: Verificar** — `flutter test test/dvrs_screen_test.dart && flutter test && flutter analyze`
Expected: verde. Os testes navegam com `pumpAndSettle`, então a transição de 220ms não quebra.

- [ ] **Step 4: Commit** — `git add lib/widgets/dvrs/ && git commit -m "feat(dvrs): transições entre perguntas, chip de domínio e check ao salvar"`

---

### Task 9: Histórico do DVRS com `TrendLineChart` e `GlassCard`

**Files:**
- Modify: `lib/widgets/dvrs/dvrs_history_view.dart`

**Interfaces:**
- Consumes: `TrendLineChart` (Task 6), `GlassCard`/`SectionHeader` (Task 3).
- Produces: —

- [ ] **Step 1: Migrar o gráfico**

Em `dvrs_history_view.dart`:
1. Importar `../../ui/trend_line_chart.dart`, `../../ui/glass_card.dart`, `../../ui/section_header.dart`.
2. Substituir os DOIS usos de `CustomPaint(painter: _DvrsLineChartPainter(...), child: const SizedBox.expand())` (gráfico de score em `_chartCard` e por domínio em `_domainEvolutionCard`) por:

```dart
          TrendLineChart(
            points: points, // mesma lista já construída no local
            minY: 0,
            maxY: 100,
          ),
```

(no card por domínio, `points` é a lista construída com `domainScores.valueFor(_selectedDomain)`; usar `height: 140` no domínio e `height: 160` no score, como os `SizedBox` atuais).
3. REMOVER a classe `_DvrsLineChartPainter` inteira do arquivo.
4. Substituir o método local `_card(theme, child: ...)` por `GlassCard(child: ...)` em todos os usos e remover `_card`.
5. Trocar os `Text('Evolução do score'/'Evolução por domínio'/'Resultados', ...)` por `SectionHeader(...)` (removendo os `SizedBox(height: 12)` adjacentes).

- [ ] **Step 2: Verificar** — `flutter test && flutter analyze` → verde.
- [ ] **Step 3: Commit** — `git add lib/widgets/dvrs/dvrs_history_view.dart && git commit -m "refactor(dvrs): histórico usa TrendLineChart e GlassCard"`

---

### Task 10: Pausa 20-20-20 — anel no countdown, respiração e streak na conclusão

**Files:**
- Create: `lib/ui/breathing_circle.dart`
- Modify: `lib/widgets/glass_overlay.dart`, `lib/main.dart` (instanciação do `GlassOverlay`, ~linha 1277; `_onStateChanged`)
- Test: `test/ui/breathing_circle_test.dart`

**Interfaces:**
- Consumes: `ProgressRing` (Task 4); `TimerProvider.phaseSeconds` e `phaseRemaining` (existentes); `BreakStatsData.currentStreak(DateTime now)` (existente); `StorageService.loadBreakStats()` (existente).
- Produces: `BreathingCircle({Key? key, double size = 150, Color color = Colors.white})`; `GlassOverlay` ganha params `required int phaseTotalSeconds` e `int currentStreak` (default 0).

- [ ] **Step 1: Teste que falha** — `test/ui/breathing_circle_test.dart`:

```dart
import 'package:dry_eye_widget/ui/breathing_circle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BreathingCircle monta e anima em loop sem lançar', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: BreathingCircle())),
    ));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
    // Desmonta sem vazar o controller.
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar** — FAIL.

- [ ] **Step 3: Implementar `lib/ui/breathing_circle.dart`**

```dart
import 'package:flutter/material.dart';

/// Círculo de "respiração": expande e contrai suavemente (~4s por ciclo)
/// para guiar piscadas/respiração durante a pausa. Use APENAS em estados
/// de pausa — o loop roda enquanto o widget estiver montado.
class BreathingCircle extends StatefulWidget {
  const BreathingCircle({super.key, this.size = 150, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  State<BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<BreathingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  ).drive(Tween(begin: 0.82, end: 1.12));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.08),
            border: Border.all(color: widget.color.withValues(alpha: 0.22)),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verificar o componente** — `flutter test test/ui/breathing_circle_test.dart` → PASS.

- [ ] **Step 5: Integrar no `glass_overlay.dart`**

1. Novos params no construtor: `required this.phaseTotalSeconds` e `this.currentStreak = 0`; campos `final int phaseTotalSeconds; final int currentStreak;`.
2. Imports: `../ui/breathing_circle.dart`, `../ui/progress_ring.dart`.
3. No `_buildContent()`, substituir o bloco do countdown:

De:
```dart
          if (state.showsCountdown) ...[
            const BlinkingEye(size: 96),
            const SizedBox(height: 16),
          ],
```
Para:
```dart
          if (state.showsCountdown) ...[
            Stack(
              alignment: Alignment.center,
              children: const [
                BreathingCircle(size: 150),
                BlinkingEye(size: 96),
              ],
            ),
            const SizedBox(height: 16),
          ],
```

E o `TimerDisplay` no fim:

De:
```dart
          if (state.showsCountdown) ...[
            const SizedBox(height: 24),
            TimerDisplay(secondsRemaining: secondsRemaining),
          ],
```
Para:
```dart
          if (state.showsCountdown) ...[
            const SizedBox(height: 24),
            ProgressRing(
              value: phaseTotalSeconds <= 0
                  ? 0
                  : 1 - secondsRemaining / phaseTotalSeconds,
              size: 118,
              strokeWidth: 5,
              color: Colors.white,
              child: TimerDisplay(secondsRemaining: secondsRemaining),
            ),
          ],
```

4. Conclusão com check + streak — logo APÓS o `Text(strings.stateSubtitle(state), ...)`, adicionar:

```dart
          if (state == AppState.conclusao) ...[
            const SizedBox(height: 16),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: const Icon(Icons.check_circle,
                  size: 44, color: AppColors.textPrimary),
            ),
            if (currentStreak >= 2) ...[
              const SizedBox(height: 10),
              Text(
                // Localizado: reusa o helper existente do "Meu Progresso"
                // (ex.: "5 dias" / "5 days").
                '🔥 ${strings.progressDaysCount(currentStreak)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ],
```

Import de `AppState` já existe no arquivo (`models/app_state.dart`).

- [ ] **Step 6: Alimentar os novos params no `main.dart`**

1. Em `_HomePageState`, adicionar campo `int _currentStreak = 0;`.
2. Em `_onStateChanged()`, no INÍCIO do método, adicionar:

```dart
    // Streak para a tela de conclusão (calculado só na transição, não a cada tick).
    if (_timer.state == AppState.conclusao && _wasActive) {
      _currentStreak = context
          .read<StorageService>()
          .loadBreakStats()
          .currentStreak(DateTime.now());
    }
```

3. Na instanciação `GlassOverlay(...)` (~linha 1277), adicionar:

```dart
            phaseTotalSeconds: timer.phaseSeconds,
            currentStreak: _currentStreak,
```

- [ ] **Step 7: Verificar** — `flutter test && flutter analyze` → verde (o app_state_test e timer tests não tocam o overlay).
- [ ] **Step 8: Commit** — `git add lib/ui/breathing_circle.dart lib/widgets/glass_overlay.dart lib/main.dart test/ui/breathing_circle_test.dart && git commit -m "feat(pausa): anel de progresso, respiração guiada e streak na conclusão"`

---

### Task 11: Dashboard — aba Resumo com KPIs (StatTile + sparkline + mini gauge)

**Files:**
- Modify: `lib/widgets/dashboard/dashboard_screen.dart` (classe `_OverviewTab`, ~linha 122)

**Interfaces:**
- Consumes: `StatTile` (Task 4), `ScoreGauge` + `DvrsUi.classificationSegments` (Tasks 5/7), `TrendLineChart` (Task 6), `GlassCard`/`SectionHeader` (Task 3); dados já disponíveis na tela (ler o arquivo para ver como `_OverviewTab` obtém DVRS/tela/pausas hoje — o refactor REUSA essas fontes: `DvrsStorageService`, `ScreenTimeService`/`ScreenTimeData`, `StorageService.loadBreakStats()`).
- Produces: —

- [ ] **Step 1: Ler `_OverviewTab` atual** e mapear de onde vêm: último DVRS, tendência, tempo de tela e adesão. NÃO mudar as fontes de dados — só a apresentação.

- [ ] **Step 2: Reformar a apresentação**

Substituir os cards atuais da aba Resumo por (mantendo o `DvrsUi.disclaimerBanner` existente ao final):

```dart
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatTile(
                label: 'Adesão às pausas · 7 dias',
                value: adherence7 == null
                    ? '—'
                    : '${(adherence7 * 100).round()}%',
                ringValue: adherence7 ?? 0,
                icon: Icons.free_breakfast_outlined,
                color: semantic.success, // Theme.of(context).extension<AppSemanticColors>()!
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Tela hoje',
                value: screenTodayLabel, // ex.: '2h 15min' (formatador já existente na tela)
                icon: Icons.desktop_windows_outlined,
                footer: last7.length >= 2
                    ? TrendLineChart(
                        points: last7, // [(dia, segundos)] últimos 7 dias
                        showGrid: false,
                        dateLabels: false,
                        height: 44,
                      )
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('DVRS — Risco Visual Digital'),
              if (latestDvrs == null)
                Text(
                  'Responda o DVRS para acompanhar seu risco visual digital.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
                )
              else ...[
                Center(
                  child: ScoreGauge(
                    score: latestDvrs.totalScore,
                    color: DvrsUi.classificationColor(latestDvrs.classification),
                    segments: DvrsUi.classificationSegments,
                    size: 150,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: DvrsUi.classificationChip(latestDvrs.classification),
                ),
                // manter a linha de tendência (compareDvrsTrend) que a aba já exibe hoje
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // disclaimerBanner existente permanece
      ],
    );
```

Adaptar nomes de variáveis aos que a `_OverviewTab` já usa (ex.: se hoje ela chama `latest`, manter). `adherence7`: usar `loadBreakStats().adherenceForRange(now.subtract(const Duration(days: 6)), now)` se a aba ainda não calcular. `last7`: construir de `ScreenTimeData.dailySeries(hoje, 7)` → `[(p.day, p.seconds.toDouble())]`.

- [ ] **Step 3: Migrar os cards restantes do arquivo** — substituir os `Container(...decoration: BoxDecoration(color: surface α0.4, radius 16, border α0.08)...)` padronizados (ex.: `_statBox`, `_bigCard` se sobrarem usos) por `GlassCard` onde a troca for 1:1; NÃO reestruturar a aba Tempo de tela.

- [ ] **Step 4: Verificar** — `flutter test && flutter analyze` → verde.
- [ ] **Step 5: Commit** — `git add lib/widgets/dashboard/dashboard_screen.dart && git commit -m "feat(dashboard): aba Resumo com KPIs, sparkline e mini gauge do DVRS"`

---

### Task 12: Menu flutuante — cor por grupo e destaque do DVRS

**Files:**
- Modify: `lib/widgets/floating_menu.dart`
- Test: `test/floating_menu_test.dart` (já cobre altura ≤660 e abertura do DVRS — é o guarda)

**Interfaces:**
- Consumes: `AppColors`/`AppPalette` (constants.dart).
- Produces: —

- [ ] **Step 1: Accent por item**

1. Em `_MenuItem`, adicionar campo opcional: `const _MenuItem(this.icon, this.label, this.onTap, {this.accent, this.emphasized = false}); final Color? accent; final bool emphasized;`.
2. Nos `healthItems`, marcar: item DVRS → `accent: AppColors.idleBall, emphasized: true` e ícone `Icons.assignment` (preenchido); demais itens de saúde → `accent: const Color(0xFF1ABC9C)` (turquesa da AppPalette). `pauseItems` → `accent: AppColors.idleBall`. `systemItems` → sem accent (neutro).
3. Propagar para `_MenuRow`/`_CompactActionButton`: adicionar params `Color? accent, bool emphasized = false`; no `Icon(...)`, trocar `color: _hover ? AppColors.idleBall : AppColors.textPrimary` por `color: _hover ? (widget.accent ?? AppColors.idleBall) : (widget.accent ?? AppColors.textPrimary).withValues(alpha: widget.accent == null ? 1.0 : 0.95)`; no `Text` do rótulo, usar `fontWeight: widget.emphasized ? FontWeight.w600 : (_hover ? FontWeight.w600 : FontWeight.w400)`.
4. Atualizar `rowFor`/`_CompactActionRow` para repassar `accent`/`emphasized`.

- [ ] **Step 2: Verificar o guarda de altura e o fluxo**

Run: `flutter test test/floating_menu_test.dart && flutter test && flutter analyze`
Expected: verde (altura ≤660 inalterada — nenhum item novo foi adicionado).

- [ ] **Step 3: Commit** — `git add lib/widgets/floating_menu.dart && git commit -m "feat(menu): cores por grupo e destaque do DVRS"`

---

### Task 13: Versão 1.20.0, CHANGELOG e verificação final

**Files:**
- Modify: `pubspec.yaml`, `lib/utils/constants.dart` (AppInfo.version, ~linha 197), `CHANGELOG.md`

**Interfaces:**
- Consumes: tudo acima.
- Produces: release-ready `main`.

- [ ] **Step 1: Bump de versão**

```bash
cd /Users/philipecruz/app_dry_eye_widget
sed -i '' 's/^version: 1.19.1+54/version: 1.20.0+55/' pubspec.yaml
sed -i '' 's/msix_version: 1.19.1.0/msix_version: 1.20.0.0/' pubspec.yaml
sed -i '' "s/static const String version = '1.19.1';/static const String version = '1.20.0';/" lib/utils/constants.dart
grep -n "1.20.0" pubspec.yaml lib/utils/constants.dart
```

Expected: 3 linhas com `1.20.0`.

- [ ] **Step 2: CHANGELOG**

Inserir no topo de `CHANGELOG.md` (após o cabeçalho, antes de `## [1.19.1]`):

```markdown
## [1.20.0] - <data de hoje AAAA-MM-DD>

### Adicionado
- **Design system**: componentes visuais unificados (cards, anéis de progresso,
  gauge de score, gráfico de tendência com área) e tema central com tipografia
  Inter/RobotoMono embutida no app (sem download de fontes em tempo de execução).
- **DVRS**: gauge semicircular animado no resultado, transições suaves entre as
  16 perguntas com identificação do domínio, barras de domínio animadas e
  confirmação visual ao salvar.
- **Pausa 20-20-20**: anel de progresso ao redor do cronômetro, círculo de
  respiração guiada durante a pausa e sequência (streak) na tela de conclusão.
- **Painel**: aba Resumo com indicadores visuais (adesão às pausas em anel,
  tempo de tela com miniatura de tendência e mini gauge do DVRS).

### Modificado
- Menu flutuante com cores por grupo e o DVRS em destaque.
- Tipografia e espaçamentos consistentes em todas as telas.

### Removido
- Dependência `google_fonts` (fontes agora locais — melhor para uso offline e
  privacidade).
```

- [ ] **Step 3: Verificação final completa**

```bash
flutter analyze && flutter test
```

Expected: `No issues found!` e `All tests passed!` (156 antigos + novos de `test/ui/`).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml lib/utils/constants.dart CHANGELOG.md
git commit -m "chore: v1.20.0 — UX refresh (design system, DVRS, pausa, painel)"
```

Push e tag/release ficam FORA deste plano (exigem confirmação do usuário).
