# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui.
O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/) e o
versionamento é [SemVer](https://semver.org/lang/pt-BR/).

## [1.15.1] - 2026-06-21

### Alterado
- **Checklist de ergonomia visual** com especificações detalhadas: cada pergunta
  agora traz valores de referência (distância ~50–70 cm; topo da tela na linha
  dos olhos ou até ~5 cm abaixo, centro 15–20° abaixo da horizontal; brilho
  equiparado ao ambiente; tela perpendicular às janelas; suporte + teclado/mouse
  externos para notebook; regra 20-20-20), exibidos abaixo de cada item.
- Feedbacks de ergonomia (baixo/atenção/risco aumentado) enriquecidos com as
  mesmas referências de ajuste do posto de trabalho. Conteúdo educativo, não
  prescritivo.

## [1.15.0] - 2026-06-21

### Adicionado
- **Área "Checklists" de saúde visual digital** — educativa e de triagem (não
  diagnóstica), com 7 módulos:
  - Ergonomia visual, Ambiente de tela, Sintomas visuais, Sinais de alerta e
    Pausas e hábitos: questionários com pontuação, classificação de risco e
    feedback educativo.
  - Triagem oftalmológica: combina OSDI, tempo de tela, adesão a pausas e os
    demais checklists para orientar quando considerar avaliação.
  - Resumo de risco visual: panorama consolidado por indicador.
- Histórico longitudinal por checklist (comparação último × anterior) com
  opção de excluir registros.
- Inclusão dos resultados no **relatório PDF** (seção "Checklists de saúde
  visual digital", com tabela Checklist | Data | Resultado | Recomendação).

### Privacidade
- Resultados armazenados localmente; exclusão pelo usuário; sem compartilhamento
  automático; linguagem de triagem/educativa, nunca diagnóstica.

## [1.14.0] - 2026-06-21

### Adicionado
- **Checklist ambiental** opcional na tela de Relatórios: distância da tela,
  altura do monitor, brilho, contraste, iluminação, reflexo, ar-condicionado,
  umidade, múltiplos monitores, home office e ventilador no rosto, com
  classificação automática (adequado / atenção / risco aumentado) incluída no PDF.
- **Excluir PDF salvo** diretamente pela tela de Relatórios.
- **Fonte Unicode embutida** (DejaVuSans) como *fallback* no PDF, garantindo a
  renderização de símbolos fora do Latin-1 (travessões, aspas curvas, etc.) que
  o usuário possa colar nas observações.

### Removido
- **Dashboard de saúde e integração com HealthKit**: removidos o painel de saúde,
  o serviço/modelo associados e a ponte nativa do macOS. O HealthKit não está
  disponível no macOS nativo e o entitlement correspondente impedia a compilação
  local (assinatura ad-hoc), além de exigir descrição de uso desnecessária.

### Corrigido
- **Build local do macOS**: removido o entitlement `com.apple.developer.healthkit`
  que exigia certificado/perfil de desenvolvimento e impedia a abertura do app
  em builds ad-hoc.

## [1.13.0] - 2026-06-21

### Adicionado
- **Relatório de Saúde Visual Digital em PDF**: nova tela "Relatórios" que
  exporta um documento clínico-educativo (triagem, não diagnóstico) com:
  - Resumo executivo e indicação geral (acompanhar / reforçar pausas /
    considerar avaliação oftalmológica).
  - Evolução do escore OSDI com gráfico de barras por severidade.
  - Sintomas derivados das respostas OSDI (frequência, intensidade e tendência).
  - Tempo de tela: média diária, total, dia de pico e comparação entre dias
    úteis e fins de semana.
  - Adesão às pausas visuais, com rastreamento persistido a cada ciclo.
  - Seção "Quando procurar avaliação oftalmológica" com gatilhos educativos.
- Períodos de 7, 30 e 90 dias e intervalo personalizado, com prévia do relatório.
- Ações separadas de salvar, compartilhar e cancelar, com confirmação de
  privacidade (LGPD) antes de qualquer compartilhamento.

### Privacidade
- O PDF é gerado integralmente no dispositivo (pacote `pdf`), sem envio a
  servidores ou terceiros sem ação explícita do usuário.

## [1.11.5] - 2026-06-18

### Alterado
- **Aviso de pausa suave**: remove o olho piscando do cartão de aviso e troca o
  visual por um painel liquid glass mais moderno, com rótulo 20-20-20,
  tipografia refinada e cronômetro circular com brilho.
- **Texto da pausa**: melhora a orientação para focar a cerca de 6 metros e
  piscar de forma lenta e completa até o cronômetro zerar.

## [1.11.4] - 2026-06-18

### Corrigido
- **Botão "Sobre" no macOS**: o item do menu da bolinha volta a abrir uma
  janela interna ampla, sem depender de diálogo modal depois que a janela é
  reduzida para o tamanho compacto.

### Alterado
- **Configurações**: remove o controle "Velocidade do piscar" para deixar o
  menu mais limpo. O valor interno continua preservado para compatibilidade com
  preferências já salvas.

## [1.10.2] - 2026-06-13

### Corrigido
- **Botão "Sobre"**: ao clicar em "Sobre" no menu da bolinha, nada aparecia. A
  janela era encolhida para o tamanho da bolinha antes de abrir o diálogo, que
  então não tinha espaço para renderizar. O "Sobre" passa a ser um painel
  interno (mesmo padrão de "Orientações"/OSDI), exibido numa janela ampla.

### Alterado
- **Janela "Sobre"**: agora traz uma breve descrição do app, a versão atual e a
  autoria — Dr. Philipe Saraiva Cruz, médico oftalmologista (RQE 71.903 ·
  CRM-MG 69.870 · CRM-SP 204.923).

## [1.10.1] - 2026-06-13

### Corrigido
- **Build Windows**: corrige a falha de compilação no novo `windows-latest`
  (VS 2026 / MSVC 14.51), que passou a tratar `<experimental/coroutine>` como
  erro fatal (STL1011) ao compilar o plugin `audioplayers_windows`. O define
  `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` agora é aplicado a
  todos os alvos via `windows/CMakeLists.txt`, restaurando a geração do
  instalador `.exe` na release.

## [1.10.0] - 2026-06-13

### Adicionado
- **Tempo de tela**: nova coleta local do tempo de uso ativo de tela por dia,
  descartando a inatividade do sistema (reaproveita o sinal de ociosidade e as
  pausas por inatividade). Os dados ficam apenas no computador do usuário.
- **Janela de visualização de tempo de tela**: destaque do total de hoje e
  gráfico de barras com os períodos semanal, mensal e anual, além de total e
  média diária do período. Acessível pelo menu flutuante e pelas configurações;
  permite limpar o histórico. Implementada sem dependências de gráficos.
- **Bloquear a tela na pausa**: nova opção que força o aviso em tela cheia
  durante a pausa mesmo com as notificações suaves ligadas, para reforçar o
  descanso (precedência sobre o modo suave).

### Alterado
- **Configurações**: nova seção "Tempo de tela" (ativar coleta + atalho para a
  janela) e sub-opção de bloqueio de tela dentro de "Durante a pausa". A opção
  "Ativar notificações" do sistema permanece em "Geral".

## [1.9.2] - 2026-06-11

### Corrigido
- **Menu flutuante**: o item "Sair" deixava de aparecer porque a janela do menu
  tinha altura fixa (450 px) e o conteúdo (cabeçalho + 10 itens) era cortado pela
  borda inferior. A janela passa a ser dimensionada dinamicamente em função do
  tamanho da bolinha, garantindo que todos os itens fiquem visíveis no Windows e
  no macOS.

## [1.9.1] - 2026-06-11

### Adicionado
- **Tela cheia**: o widget agora permanece visível sobre apps em tela cheia.
  No macOS, a janela entra nos Spaces de tela cheia de outros apps
  (`canJoinAllSpaces` + `fullScreenAuxiliary`, reafirmados a cada mudança de
  layout). No Windows, o runner reafirma `HWND_TOPMOST` periodicamente sem
  roubar o foco (`SWP_NOACTIVATE`), cobrindo apps borderless em tela cheia;
  tela cheia exclusiva (DirectX) segue fora do alcance de qualquer janela.

## [1.9.0] - 2026-06-11

### Alterado
- **Nome do app**: o aplicativo gerado passa a se chamar "Dry Eye Widget"
  (antes `dry_eye_widget`) no bundle macOS e no título da janela.

## [1.8.10] - 2026-06-10

### Corrigido
- **Build**: corrige erros de compilação introduzidos na 1.8.9 — constante
  `AppColors.surface` ausente (fundo do diálogo Sobre), teste do menu flutuante
  sem os callbacks `onGitHub`/`onAbout` e variáveis não usadas na bolinha.

## [1.8.9] - 2026-06-09

### Adicionado
- **Menu flutuante**: link para o repositório no GitHub e diálogo "Sobre".

## [1.8.8] - 2026-06-09

### Alterado
- **Visual**: design minimalista 3D moderno e anel de progresso na borda da
  bolinha.

## [1.8.7] - 2026-06-09

### Alterado
- **Efeito dinâmico**: passa a ficar desligado por padrão em novas instalações,
  preservando o controle nas Configurações para ativação manual.

## [1.8.6] - 2026-06-09

### Corrigido
- **Instalador Windows**: a versão do Inno Setup agora é injetada pelo workflow
  a partir do `pubspec.yaml`, com validação contra `AppInfo.version`, evitando
  instaladores de releases novas com metadados de versão antigos.

## [1.8.5] - 2026-06-09

### Adicionado
- **Bolinha dinâmica em estilo assistente visual**: efeito luminoso com fitas
  internas em tons frios (azul, ciano, verde e branco), sem rosa.
- **Interação por hover**: ao passar o mouse, a bolinha amplia levemente e
  intensifica brilho/movimento sem quebrar cliques ou menu.
- **Controles nas Configurações** para ativar/desativar o efeito dinâmico,
  ativar/desativar a reação ao mouse e ajustar a intensidade visual.

## [1.8.1] - 2026-06-09

### Corrigido
- **Instalador Windows**: hardening dos metadados do Inno Setup (publisher,
  AppId estável, version info), version resource no executável (`Runner.rc`) e
  `PrivilegesRequired` ajustado — reduz alertas do SmartScreen/Defender e
  bloqueios de instalação. Adicionado `win_version/CODE_SIGNING.md` documentando
  o passo (opcional) de assinatura de código por certificado, que é o que
  elimina por completo o aviso do SmartScreen. (#5)

## [1.8.0] - 2026-06-09

### Adicionado
- **Presença pela câmera (opcional, opt-in, desligada por padrão)**: quando o
  input fica ocioso no limiar de inatividade, um **snapshot pontual** confirma
  presença via detecção de rosto on-device (macOS/Vision), evitando pausas
  indevidas enquanto o usuário está lendo a tela. A imagem é processada e
  descartada na hora — nada é gravado nem enviado.
- **Consentimento explícito**: ao ativar a câmera nas Configurações, um diálogo
  explica exatamente o que ela faz antes de o sistema pedir a permissão.
- Entitlement de câmera (macOS) + `NSCameraUsageDescription`. No Windows o
  toggle aparece desabilitado (detecção de rosto fica para um follow-up).

## [1.7.0] - 2026-06-09

### Adicionado
- **Limiar de inatividade adaptativo**: o tempo até pausar deixa de ser fixo
  (2 min) e passa a ser **aprendido continuamente** a partir dos padrões do
  usuário, por faixa horária (estatística online leve, on-device).
- **Presença pela câmera (opcional, opt-in, desligada por padrão)**: quando o
  input fica ocioso no limiar, um snapshot pontual confirma presença via
  detecção de rosto on-device (macOS/Vision), evitando pausas indevidas
  enquanto o usuário está lendo a tela.
- **Persistência cifrada do aprendizado**: o estado agregado do modelo é
  guardado cifrado em repouso pelo SO (Keychain no macOS, DPAPI no Windows),
  sem histórico de eventos nem acesso remoto; botão para **resetar o
  aprendizado** nas Configurações.

### Alterado
- O motor de pausa por inatividade passou a ser o `PresenceController`
  (sensores plugáveis + modelo adaptativo), preservando o cartão de aviso,
  a histerese de retomada e a retomada manual já existentes.

## [1.6.4] - 2026-06-09

### Adicionado
- **Módulo de detecção de inatividade** completo: além de pausar o ciclo quando o
  sistema fica ocioso (≥ 2 min), agora mostra um **aviso compacto** no canto
  superior direito ("Timer pausado") com botão **Retomar**, retomada automática
  ao voltar a usar (com histerese para evitar oscilação) e toggle nas
  Configurações ("Pausar por inatividade").

### Alterado
- Tamanho padrão da bolinha ajustado para **24 px**.
- Maior opacidade/contraste do menu de configurações (LiquidGlass).

## [1.6.3] - 2026-06-08

### Notas de build
- Primeira release publicada com **artefatos macOS e Windows juntos**, via CI:
  `DryEyeWidget.dmg`, `DryEyeWidget-Setup-x64.exe` e `DryEyeWidget-windows-x64.zip`.
  A partir daqui, os links de download apontam para a release mais recente em
  ambas as plataformas.
- Sem alterações funcionais em relação à 1.6.2.

## [1.6.2] - 2026-06-08

### Alterado
- **Atualização de dependências**: `window_manager` ^0.5.1, `screen_retriever`
  ^0.2.0, `audioplayers` ^6.7.1, `google_fonts` ^8.1.0, `flutter_lints` ^6.0.0;
  SDK `>=3.12.0`, Flutter `>=3.44.0`.
- `SettingsProvider.update` normaliza as configurações antes de persistir.

### Corrigido
- **TimerProvider**: cancela os timers de alerta/conclusão e checa `_disposed`
  para não notificar após o `dispose` (evita vazamentos/erros ao fechar); o
  estado de som e notificações passa a acompanhar as configurações em tempo
  real.

### Qualidade
- Testes novos/ampliados (`timer_provider_test`, `widget_settings_test`).
- CI `windows-build` passa a rodar `flutter analyze` e `flutter test`.

## [1.6.1] - 2026-06-08

### Corrigido
- **Windows — ícone da bandeja invisível**: o `tray_manager` carrega o ícone
  com `LoadImage(IMAGE_ICON, LR_LOADFROMFILE)`, que só aceita `.ico`; o app
  gerava `.png` (HICON nulo → sem ícone). Agora o ícone é gerado em `.ico`
  (DIB 32bpp) no Windows.

### Alterado
- **Anel de progresso ao redor da bolinha** passa a vir **ativado por padrão**
  (mostra o avanço até a próxima pausa); ainda pode ser desligado nas
  Configurações.

### Notas de build
- Adicionado workflow `windows-build.yml` (GitHub Actions) que compila e anexa
  o ZIP portátil e o instalador Windows às releases em tags `v*`.

## [1.6.0] - 2026-06-07

### Adicionado
- **Animação de olho piscando** durante a pausa de 20s, reforçando o lembrete
  de piscar enquanto se olha para ~6 metros.
- **Lembrete de colírio**: opção nas Configurações para ativar/desativar e
  escolher o intervalo (a cada **4h** ou **6h**). Um timer oculto dispara, ao
  completar, uma **notificação** e um aviso com **animação de frasco pingando
  uma gota** e a mensagem "Hora do colírio".
- **Verificar atualizações** no menu: compara a versão atual com a última
  release do GitHub e avisa se o app está atualizado ou se há uma nova versão
  para baixar (com botão que abre a página de download).

### Alterado
- Entitlements do macOS: adicionada permissão de cliente de rede (necessária
  para a verificação de atualização no app sandbox).

## [1.5.0] - 2026-06-07

### Adicionado
- **Internacionalização (PT-BR / English)**: todo o app traduzido para inglês
  (menu, configurações, orientações, notificações, pausas e barra de menu).
- **Seletor de idioma** nas Configurações, com bandeiras do Brasil e dos EUA
  (desenhadas no app, sem dependências externas). A troca atualiza o painel na
  hora e persiste.
- **README em inglês** (`README.en.md`) com seletor de idioma 🇧🇷/🇺🇸 no topo de
  ambos os READMEs.

## [1.4.1] - 2026-06-07

### Melhorado
- Ícone da barra de menu: o **olho ficou mais alto e aberto** (e a íris um pouco
  maior), deixando o desenho mais legível.

## [1.4.0] - 2026-06-07

### Adicionado
- **Design liquid glass** em todo o app (menu, configurações, orientações,
  cartão de pausa e overlay): desfoque, preenchimento em gradiente, brilho
  superior (reflexo) e borda luminosa, via novo widget `LiquidGlass`.
- **Efeito de hover no menu**: realce em gradiente, barra lateral colorida,
  ícone que muda de cor e cresce, e leve deslize ao passar o mouse.
- **Bolinha 3D com cor gradiente**: gradiente radial com luz no topo, reflexo
  especular e sombra de profundidade, dando aparência de esfera.

## [1.3.1] - 2026-06-06

### Corrigido
- **Clique com o botão direito na bolinha** não abria o menu de opções —
  faltava o handler `onSecondaryTap`. Agora o botão direito abre o menu (o
  esquerdo continua alternando). Coberto por teste de widget.

## [1.3.0] - 2026-06-06

### Adicionado
- Seção **"O que dizem os estudos"** na janela de Orientações, com dados
  estatísticos e **referências científicas** (prevalência de olho seco em
  usuários de tela, impacto na produtividade e na velocidade de leitura).
- Referências em formato RIS (`docs/referencias.ris`) e citações no README.

### Corrigido
- Estatísticas conferidas na literatura via PubMed: prevalência ~49,5%
  (meta-análise, não 60%); impacto na produtividade descrito como ~30% de
  redução de desempenho (presenteísmo), não "15 min/dia"; leitura até 14% mais
  lenta (confirmado).

## [1.2.0] - 2026-06-06

### Adicionado
- **Modo de notificações suaves (não intrusivo)**: durante a pausa, em vez do
  overlay em tela cheia, mostra apenas um cartão pequeno no canto superior
  direito com a mensagem da pausa e o cronômetro — sem bloquear a tela.

## [1.1.0] - 2026-06-06

### Adicionado
- **Item na barra de menu** (ícone de olho desenhado dinamicamente) com barra
  de progresso até a próxima pausa; menu para desabilitar/reabilitar o widget,
  iniciar pausa, abrir configurações e sair.
- **Opções de visibilidade** mutuamente exclusivas: "desabilitar item da barra
  de menu" e "desabilitar widget flutuante".
- Configuração **"Ocultar ícone do Dock"**.
- Item **"Orientações"** no menu: janela educativa sobre Síndrome da Visão de
  Computador, olho seco, regra 20-20-20 e produtividade.
- **Ícone do app** (macOS .icns + Windows .ico) a partir de `icon.png`.
- **Build universal** macOS (Apple Silicon + Intel) explícito.
- Empacotamento em `.dmg` (`scripts/make_dmg.sh`) e distribuição via Releases.

### Corrigido
- Barra de progresso do ícone da barra de menu não atualizava (inicialização do
  serviço passou a concluir assim que o ícone aparece).

## [1.0.0] - 2026-06-06

### Adicionado
- Bolinha flutuante always-on-top (azul/normal, vermelha/pausa), arrastável e
  com posição persistida.
- Ciclo da regra 20-20-20: a cada 20 min, pausa única de 20 s ("olhe a 6 m e
  pisque"), com overlay de vidro e cronômetro regressivo.
- Anel de progresso opcional ao redor da bolinha.
- Configurações: duração do ciclo e da pausa, tamanho, cores, opacidade,
  velocidade do piscar, som, notificações, canto padrão, iniciar com o sistema,
  opacidade/blur do overlay, escurecer o fundo.
- Transparência real da janela no macOS (`flutter_acrylic`).
- Persistência via `SharedPreferences`.

[1.6.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.6.0
[1.5.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.5.0
[1.4.1]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.4.1
[1.4.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.4.0
[1.3.1]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.3.1
[1.3.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.3.0
[1.2.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.2.0
[1.1.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.1.0
[1.0.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.0.0
