# Design — interação de vidro líquido e anel de progresso

Data: 2026-07-11
Status: aprovado para implementação

## Resumo de entendimento

- Evoluir a bolinha para uma aparência de vidro líquido magnético, com
  reflexos, profundidade e deformação coerentes com o movimento.
- Responder imediatamente à pressão, preservando clique curto para abrir o
  menu e iniciando arraste após um deslocamento mínimo.
- Reagir à direção e à velocidade durante o movimento, comunicando massa e
  elasticidade sem prejudicar a precisão do ponteiro.
- Aplicar inércia curta e desaceleração contínua ao soltar, seguidas de encaixe
  magnético suave quando a bolinha estiver próxima da borda.
- Evoluir o anel para um arco líquido luminoso com gradiente, ponta brilhante,
  espessura variável e intensificação discreta perto da pausa.
- Preservar desempenho, acessibilidade, portabilidade e configurações atuais.

## Premissas e requisitos não funcionais

- Meta de 60 fps em hardware desktop suportado.
- Suspender animações quando o componente não estiver visível.
- Reduzir sombras e ondulações antes de degradar a resposta ao ponteiro.
- Respeitar a preferência de reduzir movimento do sistema.
- Não introduzir coleta de dados, rede, permissões ou dependências externas.
- Manter compatibilidade com timer, clique secundário, tamanho, cor, opacidade,
  docking, lembrete de piscada e preferências existentes.
- Concentrar a solução em componentes e painters testáveis e manuteníveis.

## Abordagens consideradas

### A — física visual integrada — escolhida

Controlador interno de pressão, posição, velocidade e soltura. Esses valores
alimentam deformação, reflexo, sombra, inércia e anel. Oferece sensação
física forte com comportamento determinístico e sem dependências.

### B — evolução apenas visual

Manteria o arraste atual e acrescentaria somente deformação e brilho. Menor
risco, mas a soltura continuaria pouco física e desconectada da velocidade.

### C — motor físico dedicado

Simulação completa de massa, atrito, mola e colisão. Mais flexível, porém com
complexidade, risco multiplataforma e custo de manutenção desproporcionais.

## Arquitetura

`FloatingBall` passa a representar quatro estados visuais: repouso,
pressionado, arrastando e soltando. Uma camada de movimento reutilizável calcula
velocidade suavizada, projeção curta e desaceleração sem alterar o
`TimerProvider`.

Ao pressionar, a esfera comprime verticalmente e desloca o reflexo. Depois do
limite mínimo de movimento, entra em arraste e passa a alongar na direção da
velocidade, comprimindo no eixo perpendicular. Reflexo, gradiente e sombra usam
valores limitados para evitar tremor ou deformação excessiva.

Ao soltar, a camada de janela recebe direção e velocidade. A posição continua
por uma distância curta e desacelera de forma monotônica, sem quique ou
overshoot. Próximo à borda, o magnetismo assume gradualmente e conclui o
encaixe meia-lua. A área útil da tela limita toda a trajetória.

Nova pressão, mudança de layout, alerta, lembrete ou desmontagem cancelam o
movimento pendente. Com reduzir movimento, inércia e deformação são substituídas
por transições curtas de escala e opacidade.

## Design visual

A esfera usa base radial profunda, reflexo especular elíptico e distorção
líquida sutil. Durante o arraste, o material alonga na direção do movimento; o
reflexo fica levemente atrasado e a sombra avança. Na soltura, as camadas
retornam em tempos diferentes para sugerir massa sem aparência gelatinosa.

O anel usa gradiente angular derivado da cor configurada, trilha translúcida e
ponta luminosa com halo. A espessura varia suavemente ao longo do arco. Até 75%
o comportamento é calmo; entre 75% e 90% o brilho aumenta; acima de 90% a ponta
pulsa com baixa amplitude. O valor permanece exato durante deformações. O anel
continua oculto no modo encaixado.

## Casos extremos e segurança de interação

- Clique abre o menu apenas abaixo do limite de deslocamento.
- Arraste concluído suprime o clique subsequente.
- Clique secundário não inicia pressão ou inércia.
- Velocidade de soltura é limitada e nunca lança a janela fora da área útil.
- Mudanças de monitor recalculam limites usando a geometria atual.
- Docking pode assumir a trajetória sem salto visual.
- Nova pressão interrompe imediatamente a animação de soltura.
- Todos os controladores e callbacks são cancelados no `dispose`.

## Estratégia de testes

- Pressão imediata e transições entre estados.
- Limite entre clique e arraste e supressão de clique após arraste.
- Deformação por direção e intensidade limitada por velocidade.
- Cálculo, limite e cancelamento de velocidade/inércia.
- Inércia controlada e magnetismo nas duas bordas, sem overshoot.
- Clique secundário, modo encaixado e reduzir movimento.
- Painters em tamanhos mínimo, padrão e máximo.
- Testes focados, análise, suíte completa, build macOS release e inspeção real.

## Riscos reconhecidos

- O gerenciador de janelas do Windows pode limitar posições e animações de
  maneira diferente do macOS; a física visual ficará isolada da plataforma.
- Sombras e repaints contínuos podem afetar energia; haverá suspensão fora de
  visibilidade e degradação de efeitos decorativos.
- Inércia excessiva pode reduzir precisão; velocidade, distância e duração
  terão limites conservadores e testados.

## Registro de decisões

- Vidro líquido magnético escolhido em vez de gel orgânico ou visual discreto.
- Soltura refinada para inércia curta e controlada, seguida de encaixe magnético
  suave, substituindo o retorno por mola para aumentar precisão e conforto.
- Anel líquido luminoso escolhido em vez de anel técnico ou minimalista.
- Compressão imediata escolhida em vez de long press ou feedback só ao mover.
- Abordagem de física visual integrada escolhida em vez de painter-only ou
  motor físico dedicado.
- 60 fps, degradação adaptativa e reduzir movimento definidos como requisitos.
