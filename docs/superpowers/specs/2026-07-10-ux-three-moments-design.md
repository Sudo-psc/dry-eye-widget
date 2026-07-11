# UX em três momentos — acompanhar, agir e entender

Data: 2026-07-10
Status: aprovado para implementação incremental
Branch: `codex/ux-three-moments`

## Entendimento

O Dry Eye Widget deve melhorar sua experiência e sua interface sem ampliar o
escopo clínico. A riqueza funcional atual precisa ficar mais fácil de descobrir,
com menos sobrecarga cognitiva e menos janelas independentes. A identidade
liquid-glass escura, o funcionamento local, a privacidade, PT/EN e o caráter
educativo não diagnóstico permanecem obrigatórios.

## Arquitetura da experiência

A experiência se organiza em três momentos:

1. **Acompanhar:** a bolinha mostra somente estado e progresso do ciclo.
2. **Agir:** o painel rápido concentra pausa, controle do ciclo, modo reunião e
   acesso ao Hub. Ações de manutenção usam divulgação progressiva.
3. **Entender:** o Hub de Saúde concentra Hoje, Evolução, DVRS e Relatórios,
   preservando contexto entre ações.

O primeiro recorte implementa a divulgação progressiva no painel rápido. DVRS e
Relatórios continuam acessíveis pelo Hub; Sistema passa a ser uma segunda página
do painel, com retorno explícito, em vez de competir com as ações diárias.

## Direção visual

O vidro fica reservado à bolinha, ao painel rápido e às superfícies principais.
Conteúdo interno prioriza fundos mais sólidos, contraste previsível e menos cards
aninhados. Uma única ação principal deve dominar cada contexto. Cores de risco
sempre aparecem com ícone e texto. Animações comunicam transições e respeitam
movimento reduzido. Estados de vazio, indisponibilidade, permissão negada, erro e
sucesso devem ser semanticamente distintos.

## Requisitos não funcionais

- Nenhuma nova telemetria, conta ou dependência de rede.
- Baixo consumo ocioso; nenhuma nova animação contínua fora da pausa.
- Alvos de interação de pelo menos 44 px, foco visível e uso por teclado.
- Suporte à escala de interface até 160% e a janelas desktop estreitas.
- Paridade funcional entre macOS e Windows.
- Alterações graduais, verificadas por testes de widget, análise e build quando
  o recorte tocar integração de janela.

## Riscos e controles

- Ocultar demais ações: manter rótulo Sistema explícito e preservar todos os
  caminhos existentes.
- Aumentar cliques para ações frequentes: somente manutenção vai para a segunda
  página; pausa e Hub permanecem no primeiro nível.
- Estourar a janela compacta: usar duas páginas com altura semelhante, em vez de
  expansão vertical.
- Regressão de acessibilidade: testar Semantics, foco, rótulos e alvos.

## Decision Log

1. Foco em UX/UI, sem expansão clínica. Motivo: o app já possui ampla capacidade;
   a lacuna atual é descoberta, hierarquia e fluidez.
2. Preservar a identidade liquid-glass. Alternativa descartada: redesign completo,
   por custo e risco desproporcionais.
3. Adotar a arquitetura acompanhar/agiar/entender. Alternativas: polimento apenas
   visual ou painel central pesado. Motivo: melhora estrutural sem perder leveza.
4. Aplicar divulgação progressiva ao menu. Alternativa descartada: menu linear ou
   expansível verticalmente. Motivo: duas páginas reduzem carga sem aumentar altura.
5. Implementar incrementalmente. Motivo: reduz regressões e permite validar cada
   mudança com evidência.
6. Preservar a pilha de contexto Hub → DVRS → Relatório. Alternativa
   descartada: fechar cada painel para a bolinha. Motivo: o retorno ao contexto
   anterior reduz desorientação e trabalho repetido.
7. Incorporar DVRS e Relatórios ao Hub reutilizando as telas existentes em modo
   embedded. Alternativa descartada: manter transições entre janelas do sistema.
   Motivo: preserva estado, reduz troca de contexto e evita duplicar regras.

## Sequência de implementação

1. Painel rápido com página principal e página Sistema.
2. Hub com navegação e contexto persistentes. Concluído.
3. Consolidação de DVRS e Relatórios dentro do Hub. Concluído.
4. Estados vazios, feedback, contraste e responsividade. Concluído.
5. QA automatizado de responsividade e acessibilidade. Concluído; inspeção
   manual macOS/Windows permanece como gate de release pública.
