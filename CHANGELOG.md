# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui.
O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/) e o
versionamento é [SemVer](https://semver.org/lang/pt-BR/).

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

[1.3.1]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.3.1
[1.3.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.3.0
[1.2.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.2.0
[1.1.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.1.0
[1.0.0]: https://github.com/Sudo-psc/dry-eye-widget/releases/tag/v1.0.0
