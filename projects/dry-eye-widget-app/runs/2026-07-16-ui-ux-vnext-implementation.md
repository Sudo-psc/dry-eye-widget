# UI/UX vNext — implementação e evidência

Data: 2026-07-16
Plataforma executada: macOS
Estado: implementação local concluída; validação humana e Windows pendentes

## Contrato

Objetivo: reduzir profundidade de navegação e competição entre ações, tornar
Configurações e onboarding orientados a tarefas e melhorar a recuperação do DVRS
sem reintroduzir claims clínicos.

Não objetivos preservados: tema claro, conta/nuvem, telemetria, novos
questionários, reescrita do timer e redesign completo da landing.

## Mudanças verificadas

- Hub: quatro destinos primários; Tendências usa Hábitos/Tela sem TabBar aninhada.
- Resumo: uma ação primária contextual e caminhos secundários compactos.
- Configurações: Geral, Lembretes, Aparência e Privacidade; prévia viva da bolinha.
- Onboarding: três etapas práticas; ciclo, tamanho e notificações persistem durante
  o fluxo; conteúdo rola com texto ampliado.
- DVRS: perguntas agrupadas por domínio; cálculo incompleto informa a quantidade
  restante e rola para a primeira pergunta ausente.
- Navegação: Escape fecha Hub e Configurações e volta corretamente no DVRS.
- Segurança semântica: teste automático cobre termos obsoletos e avisos educativos
  no app, resultado e landing.

## Evidência visual

- Baseline: `artifacts/ui-ux-vnext-2026-07-16/baseline/` — 16 PNGs.
- Estado final: `artifacts/ui-ux-vnext-2026-07-16/after/` — 16 PNGs.
- Idiomas: PT-BR e EN.
- Superfícies: menu, Resumo, Hub Hoje/Tendências/DVRS/Relatórios,
  Configurações e onboarding.
- Revisão visual: nenhuma quebra aparente nas capturas; o Resumo mostra hierarquia
  de CTA única, Tendências mostra apenas dois níveis e as categorias de
  Configurações permanecem legíveis.

O harness determinístico está em `tool/ui_ux_vnext_capture_test.dart`. O baseline
detalhado, inclusive mapa de foco e caminhos, está em
`runs/2026-07-16-ui-ux-vnext-baseline.md`.

## Verificação executada

- `rtk flutter analyze` — aprovado, zero ocorrências.
- `rtk flutter test` — aprovado, 246 testes.
- Testes focados de Hub, Resumo, Configurações, onboarding, DVRS e claims — 21
  cenários aprovados em conjunto.
- Texto a 200% — Hub, Configurações e onboarding sem overflow nos testes.
- `rtk node site/scripts/smoke-check.mjs` — aprovado.
- Captura baseline e final — dois idiomas aprovados em cada execução.
- `rtk flutter build macos --release -t lib/main.dart` — aprovado;
  `build/macos/Build/Products/Release/Dry Eye Widget.app`, 59,4 MB.
- `rtk git diff --check` — aprovado.

Avisos não bloqueantes já existentes: 26 dependências possuem versões mais novas
fora das constraints; `local_notifier` ainda não suporta Swift Package Manager;
os testes de PDF informam limitações Unicode das fontes Helvetica.

## Limites e próximos gates

- UX-02 e UX-40: baseline e comparação cronometrada exigem execução humana; não
  foram simulados.
- UX-41: cinco sessões moderadas, incluindo acessibilidade, ainda pendentes.
- Leitor de tela, contraste e movimento reduzido precisam de auditoria manual em
  hardware real.
- Build/QA Windows e escalas 125%, 150% e 200% permanecem pendentes.
- Frame pacing e comportamento real da janela permanecem pendentes por plataforma.

## Aprendizado incorporado

O gate de claims e o harness visual tornam duas regressões antes manuais em checks
repetíveis. O cenário de DVRS incompleto virou teste de recuperação, e as três
superfícies mais densas ganharam cenários de texto a 200%. O próximo incremento
de maior valor é expandir o harness visual para a matriz compacta/padrão e
100%/200%, sem substituir os testes moderados.
