# UX Refresh v1.20.0 — Design system + DVRS + Pausa + Dashboard

Data: 2026-07-04 · Status: aprovado pelo usuário · Escopo: refinamento forte
(mantém identidade vidro escuro + azul e todos os fluxos existentes).

## Objetivo

Elevar a qualidade visual e de experiência do app inteiro sem mudar fluxos:
tipografia unificada, componentes compartilhados, animações sutis e telas-chave
(DVRS, pausa 20-20-20, dashboard, menu) mais ricas. Zero regressão funcional:
os 156 testes atuais continuam verdes.

## Não-objetivos

- Novo tema claro, nova paleta ou navegação reestruturada (redesign ousado).
- Mudança de textos médico-legais, fluxos do DVRS ou modelo de dados.
- Novas dependências de UI (forui/shadcn etc.).

## 1. Fundações — `lib/ui/` (design system)

Nova pasta com componentes puros de apresentação, sem I/O:

| Arquivo | Conteúdo |
|---|---|
| `lib/ui/app_theme.dart` | `buildAppTheme()` → `ThemeData` central: dark M3 seed azul (`AppColors.idleBall`), `fontFamily: 'Inter'`, escala tipográfica nomeada, radius padronizados (12/16/24) via `CardTheme`/`FilledButtonTheme`/`OutlinedButtonTheme`/`SegmentedButtonTheme`, alturas de botão consistentes. Extensão `AppSemanticColors` (ThemeExtension) com sucesso/atenção/risco/erro alinhados às faixas do DVRS. |
| `lib/ui/glass_card.dart` | `GlassCard` — card padrão translúcido (surface α0.4, borda α0.08, radius 16, padding 16). Substitui os `_card()` duplicados em `dvrs_result_view`, `dvrs_history_view`, `dashboard_screen`, `report_dialog`. |
| `lib/ui/section_header.dart` | `SectionHeader` — título de seção padronizado (14/w600 + espaçamento). |
| `lib/ui/stat_tile.dart` | `StatTile` — KPI: valor grande + rótulo + opcional `ProgressRing` (anel CustomPainter, animado 0→valor via `TweenAnimationBuilder`, ≤800ms). |
| `lib/ui/animated_gauge.dart` | `ScoreGauge` — gauge semicircular 0–100 (CustomPainter) com arco em gradiente das faixas, ponteiro/valor central animado 0→score (~800ms, `Curves.easeOutCubic`), rótulo da classificação. Cores nunca são o único indicador (valor + rótulo sempre presentes). |
| `lib/ui/trend_line_chart.dart` | `TrendLineChart` — evolução do gráfico atual do DVRS: linha + **área preenchida em gradiente**, pontos, **último ponto destacado com valor**, labels de data nas extremidades. Escala e grid configuráveis (`minY`/`maxY`/`showGrid`): DVRS usa 0–100 com grid; sparkline de tempo de tela usa escala automática sem grid. Substitui `_DvrsLineChartPainter` (que sai de `dvrs_history_view`). |

### Tipografia offline (LGPD/offline-first)

- Embutir **Inter** (Regular/Medium/SemiBold/Bold) e **RobotoMono**
  (Regular/Bold) em `assets/fonts/` (licença OFL), declaradas no `pubspec.yaml`.
- `Inter` vira a família padrão do tema; `RobotoMono` usada por nome nos
  números do timer.
- Remover a dependência `google_fonts` (hoje usada só em `timer_display.dart` e
  `gentle_break_card.dart`, com fetch em runtime — indesejado num app offline).

## 2. DVRS mais rico

- **`dvrs_screen.dart` (perguntas)**: transição entre perguntas com
  `AnimatedSwitcher` (slide horizontal + fade, 220ms, direção conforme
  avançar/voltar); chip do domínio atual (ícone + cor + nome, via
  `kDvrsDomainLabels`) acima do título; opção selecionada com animação de
  escala/realce (AnimatedContainer já existe — refinar).
- **`dvrs_result_view.dart`**: `ScoreGauge` substitui o número seco + riskBar;
  barras de domínio animam 0→valor (600ms, stagger 80ms); migra cards para
  `GlassCard`.
- **Salvar**: feedback de sucesso com ícone check animado no botão (estado
  "Salvo ✓"), sem diálogo extra.
- **`dvrs_history_view.dart`**: usa `TrendLineChart`; cards migram para
  `GlassCard`; seletor de domínio mantém ChoiceChips.

## 3. Pausa 20-20-20

- **Overlay de pausa** (`glass_overlay.dart` + `timer_display.dart`):
  countdown envolvido por **anel de progresso circular** (progresso da fase);
  atrás, **círculo de respiração** pulsante (expande/contrai em ciclo ~4s,
  opacidade baixa) guiando piscadas — anima **somente** nos estados de pausa
  (`fase1`), nunca em idle.
- **`gentle_break_card.dart`**: migra para `GlassCard` + barra de progresso
  linear da fase + tipografia do tema (remove GoogleFonts runtime).
- **Conclusão** (`AppState.conclusao`): check animado (scale-in) + linha de
  streak atual (ex.: "🔥 5 dias seguidos"), **reusando o cálculo de streak já
  existente na tela "Meu Progresso"** (extraí-lo para função pura compartilhada
  se hoje estiver embutido no widget); se streak = 0/1, mensagem neutra de
  incentivo.

## 4. Dashboard e menu

- **`dashboard_screen.dart` — aba Resumo**: substitui os cards atuais por
  3 `StatTile`: (1) anel de adesão às pausas (7 dias), (2) tempo de tela hoje
  + sparkline dos últimos 7 dias (mini `TrendLineChart`), (3) DVRS mais
  recente com mini-gauge + tendência. Aba DVRS e aba Tela mantêm conteúdo,
  migrando cards para `GlassCard`.
- **`floating_menu.dart`**: ícones com cor de destaque por grupo (pausas =
  azul, saúde = verde-água, sistema = neutro); item DVRS com realce accent
  (ícone preenchido + cor primária); espaçamento vertical revisto. Altura do
  painel recalculada se necessário (`_menuPanelHeight` em `main.dart` — teste
  de altura existente é o guarda).

## Restrições transversais

- Animações ≤300ms (exceções: gauge/barras ~600–800ms one-shot; respiração em
  loop apenas durante a pausa). Nada anima em idle (bolinha intocada).
- Acessibilidade: `Semantics` preservados; cor nunca é o único indicador;
  `uiScale` (textScaler) continua valendo — componentes novos usam unidades
  relativas ao tema.
- Compatível com janelas pequenas (painéis 700×790 e cartões compactos).

## Testes

- Suíte atual (156) permanece verde — textos e fluxos não mudam.
- Novos testes de widget: `GlassCard`/`StatTile`/`SectionHeader` renderizam;
  `ScoreGauge` mostra valor/rótulo corretos por faixa; `TrendLineChart`
  renderiza com 0/1/N pontos; menu continua ≤660px de altura.

## Entrega

- Versão **1.20.0+55** (pubspec, msix, AppInfo, CHANGELOG).
- Ordem de implementação: fundações → DVRS → pausa → dashboard/menu → testes →
  release (tag dispara CI multiplataforma).
