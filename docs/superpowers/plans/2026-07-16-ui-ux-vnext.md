# UI/UX vNext — Dry Eye Widget

Data: 2026-07-16
Status: recortes automatizáveis implementados e verificados; validação humana e Windows pendentes
Escopo: aplicativo Flutter desktop para macOS e Windows

## Síntese executiva

O app já resolveu os problemas básicos de apresentação: possui design system,
onboarding, menu progressivo, Hub de Saúde, resumo diário, navegação por teclado,
escala de interface, redução de movimento e testes visuais. O próximo salto não
deve ser um novo redesign cosmético. Deve simplificar a arquitetura de informação
e fazer cada tela responder rapidamente a três perguntas:

1. Como estou agora?
2. O que devo fazer em seguida?
3. Onde encontro uma configuração ou histórico específico?

A tese vNext é: preservar a identidade liquid-glass e a bolinha como superfície
principal, reduzir navegação e cartões aninhados, oferecer uma única ação dominante
por contexto e validar a experiência com tarefas reais em macOS e Windows.

## Baseline observado

- A bolinha comunica estado e progresso do ciclo e oferece ações rápidas.
- O menu principal já separa ações frequentes de manutenção em uma página Sistema.
- O Hub reúne Hoje, Evolução, DVRS e Relatórios.
- Evolução contém Hábitos e Indicadores; Indicadores abre outro conjunto com Resumo,
  Tela e DVRS. Essa navegação aninhada é hoje o maior risco de desorientação.
- O Resumo do dia oferece métricas, DVRS, insight e quatro CTAs, mas compete com a
  própria navegação do Hub.
- Configurações concentram oito grupos em uma janela rolável de 460 x 700 px.
- O onboarding tem cinco telas explicativas, mas quase não conclui configuração.
- O DVRS usa uma página única com 16 perguntas, rascunho e progresso por respostas.
- O projeto é local-first, sem conta e sem telemetria. Métricas de UX precisam ser
  coletadas por testes locais, QA e sessões moderadas, não por rastreamento oculto.

## Brainstorm organizado

### 1. Compreensão imediata

- Transformar o Resumo do dia em uma resposta curta: estado, tendência e próxima
  ação recomendada.
- Mostrar comparações legíveis, como “2 pausas a mais que ontem”, evitando depender
  apenas de porcentagens.
- Diferenciar claramente ausência de dados, dados insuficientes e situação estável.
- Usar linguagem educativa consistente com o reposicionamento recente do DVRS,
  sem sugerir diagnóstico ou risco clínico validado.

### 2. Navegação e arquitetura de informação

- Manter quatro destinos primários no Hub: Hoje, Tendências, DVRS e Relatórios.
- Eliminar o terceiro nível Evolução > Indicadores > Resumo/Tela/DVRS.
- Consolidar hábitos, tempo de tela e autorregistros em uma tela de Tendências com
  seções progressivas e filtros temporais comuns.
- Preservar aba, rolagem e filtro ao voltar de detalhes.
- Garantir retorno previsível: Escape volta um nível; fechar encerra o Hub.

### 3. Ação e feedback

- Definir uma ação principal contextual no Resumo: iniciar pausa, retomar ciclo,
  registrar DVRS ou revisar dados, conforme o estado.
- Deixar ações secundárias como links compactos, sem quatro botões concorrentes.
- Confirmar imediatamente pausar, retomar, reiniciar e estender o ciclo por texto,
  mudança visual e anúncio semântico.
- Mostrar duração e efeito antes de ações ambíguas, por exemplo “Estender +1 h”.
- Considerar atalhos locais e seguros: Escape para voltar/fechar e Ctrl/Cmd + , para
  configurações. Atalhos globais ficam fora do primeiro recorte.

### 4. Configurações por intenção

- Reagrupar em Geral, Lembretes, Aparência e Privacidade/Acessibilidade.
- Usar navegação interna compacta e persistente em vez de uma lista única longa.
- Exibir uma prévia viva da bolinha ao ajustar tamanho, opacidade, cor e movimento.
- Revelar controles dependentes apenas quando ativados, como som e presença.
- Explicar impacto e privacidade ao lado da opção, sem depender de diálogo posterior.
- Adicionar busca somente se quatro grupos ainda não forem suficientes após teste.

### 5. Onboarding orientado a ativação

- Reduzir de cinco páginas informativas para três etapas práticas.
- Etapa 1: propósito e escolha rápida do ciclo de trabalho/pausa.
- Etapa 2: prévia da bolinha, tamanho e posição preferida.
- Etapa 3: notificações e recursos opcionais, pedidos somente no momento de uso.
- Encerrar com uma pausa de demonstração ou abertura do Resumo do dia.
- Transferir explicações extensas para Orientações e dicas contextuais dispensáveis.

### 6. DVRS com menor esforço

- Preservar o formato de página única já escolhido.
- Agrupar visualmente as perguntas por domínio sem criar etapas obrigatórias.
- Manter progresso fixo e oferecer “ir para a primeira não respondida”.
- Ao tentar calcular incompleto, explicar quantas faltam e mover o foco para a
  pendência, em vez de deixar apenas o botão desabilitado.
- Após concluir, destacar padrões por domínio e próximos cuidados educativos; não
  restaurar gauge, total ou rótulos antigos de risco clínico.
- Manter rascunho automático, histórico, exportação e exclusão confirmada.

### 7. Visual e acessibilidade

- Reservar vidro para a bolinha, menu e moldura principal; reduzir cards dentro de
  cards no conteúdo.
- Usar azul para ação/seleção e cores semânticas apenas para estados reais.
- Ampliar a escala tipográfica por função e reduzir textos em caixa alta decorativa.
- Validar contraste, foco, ordem de tabulação, leitores de tela e expansão de texto.
- Elevar o gate automatizado de escala de 160% para 200% nas telas principais.
- Validar Windows em 125%, 150% e 200% de escala e macOS com movimento reduzido.
- Manter zero animação contínua nova durante o estado ocioso.

### 8. Confiança e privacidade

- Mostrar “dados somente neste dispositivo” em Configurações e Meus Dados.
- Explicar por que cada permissão é útil antes de solicitá-la.
- Tornar exportar, revisar e apagar dados encontráveis sem promover exclusão acidental.
- Manter qualquer aprendizado de presença local, reversível e explicitamente opcional.

### 9. Ideias para depois do vNext

- Perfis locais de rotina, como Foco, Reunião e Leitura, se testes demonstrarem valor.
- Resumo semanal opt-in, gerado localmente.
- Alto contraste dedicado, se o modo do sistema não for suficiente.
- Personalização de densidade além da escala atual.
- Testes de usabilidade recorrentes antes de releases maiores.

## Priorização

| Prioridade | Iniciativa | Impacto | Esforço | Risco |
|---|---|---:|---:|---:|
| P0 | Simplificar Hub e remover navegação aninhada | Alto | Médio | Médio |
| P0 | Reduzir o Resumo a estado + próxima ação | Alto | Médio | Baixo |
| P0 | Gate DVRS de linguagem educativa e fluxo incompleto | Alto | Baixo | Baixo |
| P1 | Reorganizar Configurações por intenção | Alto | Médio | Médio |
| P1 | Onboarding prático em três etapas | Alto | Médio | Médio |
| P1 | Contraste, foco, Escape e escala de 200% | Alto | Médio | Baixo |
| P1 | Feedback claro nas ações rápidas | Médio | Baixo | Baixo |
| P2 | Prévia viva nas configurações | Médio | Médio | Baixo |
| P2 | Tendências com comparações narrativas | Médio | Médio | Médio |
| P3 | Perfis de rotina e resumo semanal | Incerto | Alto | Médio |

## Experiência-alvo

### Primeiro minuto

O usuário escolhe ciclo e aparência da bolinha, entende que os dados ficam locais
e conclui uma demonstração curta. Nenhuma permissão opcional é requisito para usar
o timer.

### Uso diário

Ao abrir o menu, a ação mais provável está visível. Ao entrar no Hub, Hoje informa
o estado e oferece uma única próxima ação. Tendências explica mudanças sem exigir
que o usuário entenda a estrutura interna de métricas.

### Revisão periódica

O usuário encontra DVRS e histórico como autorregistro educativo, entende dados
insuficientes e consegue gerar um relatório sem perder o contexto do Hub.

## Plano executável

### Marco 0 — Baseline de tarefas e segurança semântica

Objetivo: congelar uma linha de base confiável antes de mudar a navegação.

Tarefas:

- UX-01: capturar menu, Hoje, Tendências, DVRS, Relatórios, Configurações e
  onboarding em PT-BR e EN.
- UX-02: executar cinco tarefas cronometradas no macOS e registrar cliques, erros,
  hesitações e foco; repetir no Windows quando o ambiente estiver disponível.
- UX-03: criar uma checagem automática de termos proibidos/obsoletos do DVRS no app
  e na landing.
- UX-04: mapear ordem de foco, Escape e retorno de todas as superfícies principais.

Definição de pronto:

- Evidência visual versionada.
- Tempos e caminhos atuais registrados.
- Nenhum texto novo contradiz o caráter educativo e não diagnóstico.

### Marco 1 — Hub e Resumo do dia

Dependências: UX-01 a UX-04.

Tarefas:

- UX-10: aprovar a taxonomia Hoje, Tendências, DVRS e Relatórios.
- UX-11: retirar a navegação aninhada do Dashboard e consolidar tendências.
- UX-12: criar um cartão de próxima ação baseado no estado local.
- UX-13: reduzir CTAs duplicados e preservar caminhos secundários.
- UX-14: preservar aba, filtro e posição de rolagem.
- UX-15: adicionar feedback e anúncio semântico às ações de ciclo.

Definição de pronto:

- Nenhuma tarefa principal exige compreender navegação em três níveis.
- O usuário identifica a próxima ação em até cinco segundos no teste moderado.
- Começar uma pausa continua disponível com um clique após abrir o menu.
- Testes de widget, Semantics, foco, escala de 200% e goldens passam.

### Marco 2 — Configurações e onboarding

Dependência: taxonomia do Marco 1 estável.

Tarefas:

- UX-20: dividir Configurações em quatro grupos por intenção.
- UX-21: aplicar divulgação progressiva a som, câmera/presença e visibilidade.
- UX-22: adicionar prévia viva de tamanho, cor, opacidade e movimento.
- UX-23: reduzir onboarding a três etapas práticas.
- UX-24: solicitar permissões somente no contexto que as utiliza.
- UX-25: garantir que pular preserve defaults seguros e permita reabrir o tour.

Definição de pronto:

- Encontrar e alterar qualquer configuração prioritária leva no máximo três ações.
- O onboarding termina com uma configuração aplicada e uma ação concreta.
- Recusar permissões não bloqueia timer, menu nem Hub.
- Persistência, cancelamento, restauração de padrões e PT/EN passam nos testes.

### Marco 3 — DVRS, acessibilidade e polimento visual

Dependências: Marcos 1 e 2.

Tarefas:

- UX-30: agrupar perguntas por domínio e manter progresso fixo.
- UX-31: implementar recuperação da primeira pergunta não respondida.
- UX-32: alinhar resultado, histórico, dashboard, PDF e landing à linguagem atual.
- UX-33: reduzir aninhamento de cards e consolidar tokens de superfície/tipografia.
- UX-34: validar teclado completo, leitor de tela, contraste e texto a 200%.
- UX-35: validar movimento reduzido e ausência de novo trabalho contínuo em idle.

Definição de pronto:

- Fluxo DVRS nunca termina em um botão inerte sem orientação.
- Nenhuma superfície volta a exibir total ou classificação clínica obsoleta.
- Zero overflow nas telas-alvo a 200%.
- Todas as ações essenciais são alcançáveis por teclado e possuem nome acessível.

### Marco 4 — Validação de produto e release

Dependências: Marcos 1 a 3.

Tarefas:

- UX-40: repetir as tarefas do baseline e comparar tempo, erros e cliques.
- UX-41: realizar cinco sessões curtas com usuários que trabalham várias horas em
  computador, incluindo ao menos uma pessoa com necessidade de acessibilidade.
- UX-42: executar análise, suíte completa, goldens e builds macOS/Windows.
- UX-43: verificar frame pacing e comportamento de janela em hardware real.
- UX-44: reconciliar screenshots, README, landing, ajuda e textos legais.

Definição de pronto:

- Melhoria mensurável em pelo menos quatro das cinco tarefas do baseline.
- Nenhuma regressão crítica de acessibilidade, privacidade ou desempenho.
- Evidência por plataforma anexada ao run de release.

## Tarefas de referência para o baseline

1. Iniciar uma pausa imediatamente.
2. Descobrir quantas pausas foram concluídas hoje.
3. Encontrar a evolução do tempo de tela dos últimos sete dias.
4. Alterar frequência do lembrete de piscar e confirmar que foi salva.
5. Retomar um DVRS incompleto e localizar a primeira pergunta pendente.

## Métricas de sucesso

- Iniciar pausa: um clique após abrir o menu; até cinco segundos.
- Entender a próxima ação em Hoje: até cinco segundos.
- Encontrar uma configuração prioritária: até 20 segundos e três ações.
- Tarefas principais concluídas por teclado: 100%.
- Telas principais sem overflow a 200%: 100%.
- Contraste crítico abaixo do requisito: zero ocorrências.
- Regressões na suíte: zero.
- Novo consumo contínuo em idle: zero.
- Participantes que concluem cada tarefa sem ajuda: alvo mínimo de 80%.

## Contrato de verificação

- Testes de widget para navegação, estado, persistência, foco e Semantics.
- Goldens nas larguras compacta e padrão, PT-BR/EN e escala 100%/200%.
- Auditoria manual com teclado e leitor de tela disponível em cada plataforma.
- Capturas antes/depois com o mesmo viewport.
- `flutter analyze` e `flutter test` completos a cada marco.
- Build macOS e Windows antes de release; QA real do gerenciador de janelas.
- Registro de resultados em `projects/dry-eye-widget-app/runs/` e evidências em
  `projects/dry-eye-widget-app/artifacts/`.

## Não objetivos do primeiro ciclo

- Tema claro completo.
- Conta, nuvem, sincronização ou telemetria.
- Novos questionários ou expansão clínica.
- Reescrita do motor de timers, armazenamento ou HealthKit.
- Atalhos globais do sistema operacional.
- Redesign da landing page.
- Nova dependência de UI sem necessidade comprovada.

## Riscos e controles

- Simplificar e esconder funções: manter inventário de paridade antes/depois.
- Alterar linguagem clínica durante redesign: usar gate automatizado de claims.
- Regressão em janelas pequenas: testar tamanhos reais e texto a 200%.
- Configurações perderem valores ao mudar de grupo: cobrir rascunho, salvar e
  cancelar com testes de persistência.
- Onboarding aumentar atrito: permitir pular, usar defaults seguros e medir tempo.
- Tendências parecerem diagnóstico: separar observação, inferência e orientação.
- Expansão visual aumentar CPU: manter perfil de frame e idle como gate.

## Próxima ação recomendada

Começar pelo Marco 0. Ele produz o baseline mensurável e o gate semântico do DVRS,
permitindo que a simplificação do Hub seja implementada sem perder funções nem
reintroduzir claims já removidas.
