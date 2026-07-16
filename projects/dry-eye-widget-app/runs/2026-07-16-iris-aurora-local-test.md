# Íris aurora e teste local — 2026-07-16

## Objetivo

Validar a versão 1.24.2+72 como aplicativo macOS Release e aprimorar o efeito
interno da bolinha sem aumentar o custo contínuo de um widget permanente.

## Implementação

- O efeito interno passou a usar uma “íris aurora”: duas fitas em paralaxe,
  halo de íris, núcleo de lente, reflexo cáustico e gota luminosa orbital.
- Hover e alerta aumentam a presença visual sem alterar interações, progresso ou
  semântica.
- Reduzir movimento mantém a composição estática.
- O `AnimationController` contínuo da íris foi substituído por relógio discreto:
  10 Hz em repouso e aproximadamente 17 Hz no alerta.
- O efeito recebeu uma chave verificável e dois testes de regressão: ativação
  condicional e ausência de ticker contínuo.

## Verificação

- `flutter analyze`: sem ocorrências.
- Suíte completa após a mudança de temporização: 251 testes aprovados.
- Teste final focado da bolinha, incluindo o novo guardrail: 12 aprovados.
- `flutter build macos --release`: aprovado; app de 59,4 MB.
- O bundle Release foi aberto como aplicativo real. Processo, janela, menu,
  docking e renderização da bolinha foram observados.
- A bolinha foi inspecionada visualmente nos estados encaixado e solto. A
  posição, borda e preferências originais foram restauradas após a captura.
- O último `flutter build macos --release` deixou o selo externo ad hoc defasado
  em relação ao `App.framework`, embora o framework fosse válido isoladamente.
  O bundle foi selado novamente preservando identificador, entitlements e flags;
  `codesign --verify --deep --strict` passou depois da correção.

## Amostra de desempenho

No mesmo host e com o mesmo perfil local, o controlador anterior apresentou
amostras estabilizadas de 11,9% a 19,7% de CPU. Com o relógio discreto, as quatro
amostras estabilizadas ficaram entre 2,3% e 3,6%, com aproximadamente 44–45 MB
de memória. É uma amostra operacional em máquina sob carga, não um benchmark
laboratorial, mas demonstra que o repaint contínuo deixou de dominar o processo.

## Limites e próximo passo

O teste de runtime foi feito no macOS. O mesmo frame pacing ainda deve ser
medido em hardware Windows de entrada. O plugin `local_notifier` continua
emitindo aviso de futura incompatibilidade com Swift Package Manager, sem
impedir análise, testes ou build atual.

Se o selo externo defasado reaparecer em builds limpos, o reparo ad hoc deve ser
incorporado ao empacotamento local com um gate obrigatório de `codesign`, sem
alterar o fluxo Developer ID existente.
