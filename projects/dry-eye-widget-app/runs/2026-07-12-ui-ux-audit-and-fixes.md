# Auditoria e melhorias de UI/UX — 2026-07-12

## Escopo e objetivo

Fluxos avaliados: menu rápido principal, menu Sistema e Resumo do dia. Objetivo
do usuário: iniciar ou ajustar pausas rapidamente, chegar ao acompanhamento de
saúde visual e entender qual é a próxima ação sem depender de tentativa e erro.

## Evidência visual

Capturas aceitas antes da mudança:

1. `../artifacts/ui-ux-audit-2026-07-12/before/01-menu-principal.png`
2. `../artifacts/ui-ux-audit-2026-07-12/before/02-menu-sistema.png`
3. `../artifacts/ui-ux-audit-2026-07-12/before/03-resumo-diario.png`

Capturas equivalentes depois da mudança:

1. `../artifacts/ui-ux-audit-2026-07-12/after/01-menu-principal.png`
2. `../artifacts/ui-ux-audit-2026-07-12/after/02-menu-sistema.png`
3. `../artifacts/ui-ux-audit-2026-07-12/after/03-resumo-diario.png`

## Etapas e saúde

1. Menu principal — saudável após correção. As quatro ações de pausa têm ícone,
   rótulo curto, tooltip, semântica, foco visível e ativação por Enter/Espaço.
2. Menu Sistema — saudável após correção. A navegação de retorno permanece
   explícita e “Sair” ganhou tratamento destrutivo discreto.
3. Resumo do dia — saudável após correção. O cartão DVRS comunica ação por
   chevron e é clicável/acionável por teclado; textos secundários têm contraste
   maior; falhas ao adiar o lembrete liberam o botão e exibem feedback.

## Achados e correções

- P1: ações rápidas dependiam de ícones e tooltip, com baixa descoberta e sem
  ativação direta por teclado. Corrigido com rótulos PT/EN e controles focáveis.
- P1: exceção ao persistir “Lembrar depois” mantinha `_snoozing` ativo. Corrigido
  com `try/catch/finally`, snackbar localizado e liberação garantida do estado.
- P2: foco visual de teclado era ausente nas linhas e ações rápidas. Corrigido
  com borda de foco de alto contraste e suporte explícito a Enter/Espaço.
- P2: “Saúde visual” aparecia como seção e item consecutivos. A seção passou a
  “Acompanhar”/“Track”, preservando o item principal.
- P2: o cartão DVRS parecia informativo apesar de representar uma próxima ação.
  Corrigido com `InkWell`, semântica de botão e chevron.
- P2: textos auxiliares do resumo usavam opacidade baixa. Ajustados para maior
  legibilidade sem alterar a hierarquia visual.
- P2: transições do menu ignoravam reduzir movimento. O switch e os efeitos de
  foco/hover agora usam duração zero quando essa preferência está ativa.

## Verificação automatizada

- Teclado: primeira ação rápida recebe foco e é acionada por Enter.
- Escala: menu sem overflow com texto a 160%.
- Movimento: `AnimatedSwitcher` usa `Duration.zero` em reduzir movimento.
- DVRS: cartão aciona o fluxo correto.
- Persistência: falha ao adiar mostra feedback e permite nova tentativa.
- Captura visual: três estados pós-correção renderizados no mesmo viewport dos
  estados anteriores.

## Limites

As capturas são determinísticas e renderizadas pelo harness Flutter. Elas não
substituem inspeção de frame pacing, foco nativo e comportamento real do
gerenciador de janelas no Windows. O harness de menu usa carregamento explícito
de fontes; pequenas linhas de baseline são artefato do renderer de testes, não
decoração presente no app de produção.

## Próximas melhorias candidatas

- Medir frame pacing do menu e da bolinha em hardware Windows de entrada.
- Adicionar teste de integração nativo para foco e posição real da janela.
- Consolidar strings recentes em ARB quando a migração de i18n avançar.
