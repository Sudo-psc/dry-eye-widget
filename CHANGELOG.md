# Changelog

Todas as mudanças relevantes deste projeto são documentadas aqui.
O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/) e o
versionamento é [SemVer](https://semver.org/lang/pt-BR/).

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
