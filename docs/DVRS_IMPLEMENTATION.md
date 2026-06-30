# DVRS — Índice de Risco Visual Digital (v1.0)

Substituição do questionário anterior (OSDI / checklists) pelo **DVRS**, agora o
questionário **principal** do Dry Eye Widget. Ferramenta **educativa de triagem e
acompanhamento** — nunca diagnóstico.

## 1. Arquivos criados

| Arquivo | Papel |
|---|---|
| `lib/models/dvrs_assessment.dart` | Modelo: enums (`DvrsDomain`, `DvrsClassification`, `DvrsSafetyAlertLevel`), `DvrsAnswer`, `DvrsDomainScores`, `DvrsResult` (serializável), `DvrsSafetyAlert`, `DvrsTrend`. |
| `lib/models/dvrs_definitions.dart` | Conteúdo: 16 perguntas (`kDvrsQuestions`), mensagens educativas, alertas de segurança, rótulos de domínio, textos médico-legais. |
| `lib/services/dvrs_engine.dart` | Engine **puro** e testável: `calculateDvrsDomainScores`, `calculateDvrsTotalScore`, `classifyDvrs`, `getDvrsEducationalMessage`, `getDvrsSafetyAlert`, `evaluateDvrs`, `compareDvrsTrend`, `prepareDvrsForPdf`. |
| `lib/services/dvrs_storage_service.dart` | Persistência local: `saveDvrsResult`, `getDvrsHistory`, `getLatestDvrsResult`, `deleteDvrsResult`, `clearAll`. |
| `lib/widgets/dvrs/dvrs_ui.dart` | Helpers visuais (cor/ícone/chip de classificação, alerta, tendência, barra de risco, disclaimer). |
| `lib/widgets/dvrs/dvrs_screen.dart` | Tela principal: intro → 16 perguntas (uma por vez, progresso, voltar) → revisão → resultado → histórico. |
| `lib/widgets/dvrs/dvrs_result_view.dart` | Exibição do resultado (score, classificação, barra, domínios, mensagem, alerta). |
| `lib/widgets/dvrs/dvrs_history_view.dart` | Histórico longitudinal + gráfico de evolução do score e por domínio + exclusão. |
| `test/dvrs_*` (6 arquivos) | Cobertura: engine, modelo, definições, storage, fluxo de tela, relatório/PDF. |

## 2. Arquivos modificados

- `lib/utils/constants.dart` — nova chave `StorageKeys.dvrsResults` (`dvrs_results_json`).
- `lib/l10n/app_strings.dart` — `menuDvrs` (PT/EN).
- `lib/widgets/floating_menu.dart` — entrada DVRS no menu; removidas OSDI e Checklists.
- `lib/services/tray_service.dart` — item DVRS na bandeja; removidas OSDI/Checklists (constantes legadas preservadas).
- `lib/main.dart` — provider `DvrsStorageService`, layout/estado `_dvrsOpen`, handlers `_openDvrs/_closeDvrs`, render `DvrsScreen`, wiring do menu/bandeja.
- `lib/widgets/dashboard/dashboard_screen.dart` — 4 → 3 abas (Resumo · Tela · **DVRS**); removido conteúdo OSDI/checklist.
- `lib/models/report_options.dart` — `DvrsReportData`, `ReportData.dvrs`, `ReportOptions.includeDvrs` (OSDI/sintomas/checklists agora **opt-in**).
- `lib/services/report_builder.dart` — parâmetro `dvrsHistory`, popula `data.dvrs`.
- `lib/services/pdf_report_service.dart` — seção DVRS (`_buildDvrsSection`) com aviso médico-legal.
- `lib/widgets/report_dialog.dart` — alimenta o PDF com o histórico DVRS; prévia mostra o DVRS.

## 3. Migração do questionário anterior

- **Sem perda de dados.** As chaves antigas (`osdi_history_json`, `checklist_results_json`,
  `environment_checklist_json`) **não foram tocadas**. O DVRS grava numa chave nova e
  independente (`dvrs_results_json`) — nada é misturado nos gráficos.
- **Código legado preservado.** Modelos/serviços/widgets de OSDI e checklists continuam
  no projeto, apenas **desligados da interface** (menu, bandeja, dashboard e PDF). Podem
  ser reativados no futuro.
- **PDF:** OSDI, sintomas e checklists viraram `false` por padrão em `ReportOptions`;
  o DVRS é incluído por padrão.

## 4. Fórmula de cálculo

1. **Por domínio** (normalizado 0–100): `soma_respostas / (nº_perguntas × 4) × 100`.
   - Sintomas (Q1–Q6, máx 24) · Funcional (Q7–Q9, máx 12) · Exposição (Q10–Q12, máx 12)
     · Ambiente (Q13–Q15, máx 12) · Alerta (Q16, máx 4).
2. **Score final** (pesos): `0,35·Sint + 0,25·Func + 0,20·Expo + 0,15·Amb + 0,05·Alerta`,
   arredondado para inteiro, limitado a 0–100.
3. **Classificação:** 0–19 baixo · 20–39 atenção leve · 40–59 moderado · 60–79 elevado ·
   80–100 muito elevado.
4. **Alerta de segurança (Q16, independe do score):** 0–1 nenhum · 2 atenção · 3 avaliação
   médica · 4 avaliação prioritária.

## 5. Como testar

```bash
flutter test                 # 210 testes (53 específicos do DVRS)
flutter analyze              # sem issues
flutter test test/dvrs_engine_test.dart   # núcleo de cálculo isolado
```

Cobertura DVRS: cálculo de domínios/score/faixas, alertas Q16, serialização,
storage (CRUD + retenção), fluxo da tela (intro→16 perguntas→resultado, bloqueio
sem respostas), inclusão no relatório/PDF, ausência de linguagem diagnóstica.

## 6. Limitações atuais

- Gráficos de evolução são custom-painters simples (sem tooltips/interação).
- A tela de perguntas é uma-por-vez; não há "salvar rascunho" parcial entre sessões.
- O botão "Exportar no PDF" do DVRS leva à tela de Relatórios (que gera o PDF com a seção
  DVRS); não há export de PDF em um único toque dentro da tela do resultado.
- O dashboard reusa `DvrsHistoryView` na aba DVRS (sem KPIs adicionais).

## 7. Sugestões para a próxima versão

- "DVRS v1.1": tooltips nos gráficos e comparação lado a lado de domínios entre datas.
- Lembrete agendado para refazer o DVRS (semanal/mensal) integrado às notificações.
- Export direto do resultado em PDF/imagem a partir da própria tela do resultado.
- Modo corporativo **apenas agregado/anonimizado** (sem risco individual), se desejado.

## 8. Privacidade e uso não diagnóstico

- Dados **somente locais** (`SharedPreferences`); nada é enviado a servidores.
- Exclusão disponível por item (histórico) e `clearAll`.
- Antes de compartilhar o PDF, há aviso de privacidade; o PDF traz o aviso médico-legal
  obrigatório do DVRS.
- Toda a interface usa linguagem de **triagem/educação**; testes bloqueiam termos
  diagnósticos. O DVRS organiza sinais de risco visual digital — **não substitui o médico**.
