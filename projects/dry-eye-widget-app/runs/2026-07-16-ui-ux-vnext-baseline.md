# Baseline UI/UX vNext — 2026-07-16

## Estado técnico

- Branch: `main`, worktree com mudanças DVRS preexistentes preservadas.
- `flutter analyze`: aprovado, zero issues.
- `flutter test`: 238 testes aprovados antes da implementação vNext.
- Gate de claims DVRS adicionado e aprovado em PT-BR/EN, app e landing.
- Harness bilíngue aprovado com 16 capturas determinísticas.

## Evidência visual

Capturas em:

`projects/dry-eye-widget-app/artifacts/ui-ux-vnext-2026-07-16/baseline/`

Superfícies em PT-BR e EN:

- menu rápido;
- Resumo do dia;
- Hub Hoje;
- Hub Evolução;
- Hub DVRS;
- Hub Relatórios;
- Configurações;
- onboarding.

## Caminhos atuais das tarefas de referência

| Tarefa | Caminho atual após abrir a bolinha | Ações mínimas | Achado |
|---|---|---:|---|
| Iniciar pausa | Menu > Iniciar | 1 | Saudável |
| Ver pausas de hoje | Menu > Saúde visual | 1 | Hoje abre como destino padrão |
| Ver tempo de tela em 7 dias | Saúde visual > Evolução > Indicadores > Tela | 3 | Navegação aninhada e taxonomia ambígua |
| Alterar frequência de piscada | Sistema > Configurações > rolar > Frequência | 3 + rolagem | Controle existe, mas está numa lista extensa |
| Retomar DVRS incompleto | Saúde visual > DVRS > Continuar > localizar pendência | 2 + busca manual | Rascunho existe; falta salto para pendência |

Tempos humanos ainda não foram medidos. O baseline mensurável desta execução usa
contagem de ações, profundidade, foco e evidência visual. Sessões moderadas são um
gate externo do Marco 4 e não devem ser simuladas como resultado real.

## Mapa de foco e retorno

| Superfície | Entrada | Retorno atual | Escape explícito | Risco |
|---|---|---|---|---|
| Menu principal | clique na bolinha | fecha ao escolher ação | não testado | baixo |
| Menu Sistema | item Sistema | seta Voltar | não testado | baixo |
| Hub | Saúde visual | botão Fechar | não implementado no widget | médio |
| DVRS incorporado | aba DVRS | aba/intro | não implementado no widget | médio |
| Relatórios incorporado | aba Relatórios | aba/fechar | não implementado no widget | médio |
| Configurações | menu Sistema | botão Fechar | não implementado no widget | médio |
| Onboarding | primeira execução | concluir/pular | não aplicável | baixo |

## Achados priorizados

1. P0: Evolução contém Hábitos/Indicadores e Indicadores contém outra TabBar com
   Resumo/Tela/DVRS. A mesma informação DVRS existe em mais de um nível.
2. P0: Hoje exibe quatro CTAs, um cartão DVRS clicável, um nudge com CTA e um insight;
   a próxima ação compete com caminhos já disponíveis nas abas.
3. P1: Configurações mostra oito seções numa lista única e não oferece visão geral
   por intenção.
4. P1: onboarding explica cinco conceitos, mas não aplica uma preferência.
5. P1: o DVRS desabilita o cálculo incompleto sem oferecer salto para a primeira
   pergunta pendente.
6. P1: Escape e retorno contextual não possuem contrato automatizado comum.

## Guardrails estabelecidos

- `test/dvrs_claims_test.dart` bloqueia o retorno dos claims clínicos antigos.
- `tool/ui_ux_vnext_capture_test.dart` captura a matriz PT-BR/EN e valida a aba
  inicial antes de gerar evidência.
- Mudanças posteriores devem gerar o estágio `after` no mesmo viewport.
- Nenhuma sessão humana, QA Windows ou leitor de tela será marcada como concluída
  sem execução real.

## Próxima fase

Marco 1: simplificar o Hub para Hoje, Tendências, DVRS e Relatórios; remover a
navegação interna duplicada e reduzir Hoje a uma ação principal contextual.
