# Análise de UI/UX e Engajamento — Dry Eye Widget

> Versão analisada: **1.16.0+50** · Plataformas: macOS + Windows (desktop-only)
> Stack: Flutter · Provider + ChangeNotifier · 100% local, sem telemetria

## Contexto

O Dry Eye Widget é uma ferramenta profilática que implementa a regra 20-20-20 para mitigar
CVS (Computer Vision Syndrome) e DED (Dry Eye Disease). É tecnicamente sólido e clinicamente
embasado (OSDI, 7 checklists de triagem, relatório PDF). O gargalo **não é capacidade** — é
**descoberta e retenção**: a riqueza clínica está escondida atrás de uma bolinha flutuante e
de um menu linear de 14 itens, sem onboarding e sem reforço de hábito.

Esta análise prioriza intervenções por **impacto × esforço** e define um roadmap executável.

---

## Diagnóstico

### 🔴 Gargalos de maior impacto

1. **Ausência de onboarding** — usuário novo vê apenas a bolinha; toda a riqueza clínica
   (OSDI, dashboard, checklists, relatórios) é invisível. Sem splash, tour ou pedido
   contextual de permissões. Maior furo de adoção (D1).
2. **Acessibilidade fraca** — sem escala de fonte (`textScaler`), sem navegação completa por
   teclado, sem alto contraste. Contraditório num app de **saúde ocular**, cujo público tem
   fadiga/desconforto visual.
3. **Engajamento passivo** — sem streaks, sem reforço positivo, sem insights proativos. A
   retenção depende só de força de vontade. Dados ricos já coletados (`BreakStatsData`,
   histórico OSDI), mas sem narrativa que os devolva ao usuário.

### 🟡 Médio impacto

| Área | Problema | Oportunidade |
|------|----------|-------------|
| Menu | 14 itens lineares = sobrecarga | Agrupar em Ações / Saúde / Sistema |
| Descoberta | Features clínicas invisíveis | Dica contextual ("já fez seu OSDI este mês?") |
| Insights | Dados ricos sem síntese | "Suas pausas elevaram a adesão para 82%" |
| Light mode | Só dark | Avaliar — design glass é inerentemente escuro (baixa prioridade) |
| Loading states | `_isBusy` genérico no PDF | Progresso real / skeleton |

### 🟢 Baixo impacto / técnico
- i18n manual sem ARB (limita escalar idiomas além de PT/EN)
- Sem testes de widget/UI
- Janelas com tamanho fixo (sem responsividade interna)

### ✅ Pontos fortes a preservar
- Design "liquid glass" coeso e moderno (`liquid_glass.dart`)
- Máquina de estados limpa (IDLE → ALERTA → FASE1 → CONCLUSAO)
- Privacidade total (sem telemetria) — diferencial de confiança
- Base clínica séria (OSDI 12Q, 7 checklists, referências científicas)

---

## Roadmap faseado

> Princípio: **engajamento sem dark patterns**. Reforço positivo, nunca punição por quebra
> de streak; nenhum paywall; foco educativo-clínico mantido.

### Fase 1 — Acessibilidade: escala de UI configurável  ·  *alto valor / baixo risco*
Aplicar `MediaQuery.textScaler` global a partir de um novo setting `uiScale` (0.8×–1.6×).
Como afeta o `MaterialApp` inteiro via `MediaQuery`, não exige refatorar as cores hardcoded.
- **Arquivos**: `lib/models/widget_settings.dart` (campo `uiScale` + json/clamp/copyWith),
  `lib/utils/constants.dart` (`AppDefaults.uiScale`), `lib/main.dart` (wrap com
  `MediaQuery` aplicando `TextScaler.linear`), `lib/widgets/settings_dialog.dart` (slider),
  `lib/l10n/app_strings.dart` (label + hint PT/EN).

### Fase 2 — Engajamento: tela "Meu Progresso"  ·  *alto valor / baixo acoplamento (aditivo)*
Novo widget que devolve ao usuário a narrativa dos dados já coletados:
- **Streak respeitoso**: dias consecutivos com adesão ≥ 60% (configurável internamente),
  derivado de `BreakStatsData`. Mostra streak atual + recorde, sem punir quebras.
- **Cartões**: total de pausas concluídas, taxa de adesão (7/30 dias), evolução OSDI.
- **1 insight proativo** gerado dos próprios dados.
- **Arquivos**: novo `lib/widgets/progress/progress_screen.dart`; helper de streak em
  `BreakStatsData` (método `currentStreak`/`bestStreak`); item no `floating_menu.dart` +
  janela no `main.dart`; strings PT/EN.

### Fase 3 — Polish: menu agrupado  ·  *médio valor / baixo risco*
Reorganizar os 14 itens do `FloatingMenu` em seções com rótulos discretos e separador
de vidro: **Ações** (Iniciar/Resetar/Pausar) · **Saúde** (Orientações/OSDI/Checklists/
Progresso/Tempo de tela/Dashboard/Relatórios) · **Sistema** (Atualizar/GitHub/Sobre/
Config/Sair). Apenas `floating_menu.dart` + strings dos cabeçalhos.

### Fase 4 — Onboarding de primeira execução  ·  *alto valor / médio acoplamento*
Wizard de 3 passos disparado quando `onboardingComplete == false`:
1. Boas-vindas + o que é a regra 20-20-20 (reusa textos de `GuidanceDialog`).
2. Permissões: ativar notificações; explicar câmera (opt-in, macOS).
3. Preferências rápidas: idioma, tamanho da bolinha, ciclo.
- **Arquivos**: novo `lib/widgets/onboarding/onboarding_flow.dart`; flag
  `onboardingComplete` em `WidgetSettings`; disparo no `main.dart`; strings PT/EN.

### Futuro (fora deste ciclo)
- Insight semanal proativo (notificação opt-in)
- Exportação HealthKit / "tempo de recuperação ativa"
- i18n com ARB + pluralização
- Testes de widget para os fluxos novos

---

## Verificação

Após cada fase:
```bash
flutter analyze            # zero issues novos
flutter test               # suíte existente verde
flutter run -d macos       # validar visualmente o fluxo alterado
```
