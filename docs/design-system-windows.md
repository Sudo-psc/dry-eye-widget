# Dry Eye Widget Design System - Windows

Este documento define a base visual e de interacao do Dry Eye Widget para Windows. Ele tambem registra uma revisao do design atual, para orientar melhorias sem descaracterizar a experiencia existente.

## 1. Direcao de Design

O Dry Eye Widget e uma ferramenta pequena, persistente e utilitaria. No Windows, ele deve parecer leve, discreto e confiavel: mais proximo de um assistente de sistema do que de uma landing page ou app de conteudo.

Principios:

- **Sempre presente, nunca invasivo:** a bolinha e os avisos devem ser percebidos sem disputar atencao com o trabalho principal.
- **Saude ocular sem ansiedade:** alertas devem ser claros, curtos e gentis; evitar linguagem urgente demais.
- **Superficie minima:** cada estado deve usar a menor janela capaz de comunicar a acao.
- **Vidro funcional:** o efeito liquid glass deve ajudar a separar conteudo do fundo, nao virar decoracao pesada.
- **Controles previsiveis do Windows:** clique, clique direito, hover, tray, drag e atalhos visuais devem se comportar como utilitarios desktop.
- **Localizacao desde a origem:** todo texto de UI deve passar por `AppStrings`.

## 2. Revisao do Design Atual

### Pontos Fortes

- A bolinha flutuante tem identidade clara: esfera 3D, cor configuravel e anel de progresso.
- O app ja usa uma linguagem visual consistente baseada em `LiquidGlass`.
- O menu flutuante e denso o suficiente para desktop, com bons icones e hover.
- O modo suave no canto superior direito e um bom padrao para notificacoes nao bloqueantes.
- O overlay de pausa tem foco visual claro e hierarquia simples.
- O tray reforca o modelo mental de utilitario Windows.

### Pontos a Melhorar

- Os tokens visuais ainda estao espalhados em widgets, com muitos numeros locais de padding, radius, blur e fonte.
- `SettingsDialog` esta longo e visualmente denso; precisa de agrupamento mais escaneavel para uso repetido.
- Ha dois estilos de card, escuro e claro, mas eles ainda nao estao formalizados como variantes.
- O aviso de inatividade deve seguir o padrao do `GentleBreakCard`, evitando modal central.
- Os botoes usam padroes Material basicos; falta especificar quando usar `TextButton`, `FilledButton`, `FilledButton.icon` e controles icon-only.
- A paleta atual funciona, mas precisa de papeis semanticos alem de cores fixas.
- Animacoes devem respeitar modo reduzido e nao competir com o trabalho do usuario.

## 3. Tokens de Design

### 3.1 Cores Semanticas

| Papel | Token atual | Valor | Uso |
|---|---|---|---|
| Primary / Idle | `AppColors.idleBall` | `#4A90E2` | bolinha normal, foco, links, hover ativo |
| Alert / Break | `AppColors.alertBall` | `#FF4444` | pausa, alerta, estatisticas criticas |
| Success | novo token sugerido | `#50C878` | atualizacao ok, confirmacoes |
| Warning | novo token sugerido | `#FFD400` | estados de atencao nao criticos |
| Glass fill | `AppColors.glassFill` | `#26FFFFFF` | overlay claro |
| Glass border | `AppColors.glassBorder` | `#4DFFFFFF` | bordas translúcidas |
| Glass shadow | `AppColors.glassShadow` | `#4D000000` | sombra de profundidade |
| Text primary | `AppColors.textPrimary` | `#FFFFFF` | titulos e texto principal |
| Text secondary | `AppColors.textSecondary` | `#CCFFFFFF` | descricoes, disclaimers, metadados |
| Surface dark | novo token sugerido | `#26262C` | base de paineis escuros |
| Surface hover | novo token sugerido | `#24FFFFFF` | hover em linhas e botoes leves |

Regras:

- Usar azul apenas para estado normal, foco e acao principal tranquila.
- Usar vermelho apenas para pausa ocular ou erro real.
- Evitar fundos dominados por azul escuro; o app deve permanecer transparente e contextual.
- Cores customizaveis pelo usuario podem afetar a bolinha, mas nao devem quebrar contraste dos paineis.

### 3.2 Paleta de Personalizacao

Manter as opcoes atuais de `AppPalette`, mas tratar como personalizacao da bolinha, nao como tema global.

Uso permitido:

- `idleColor`
- `alertColor`
- preview da bolinha
- anel ou brilho derivados da bolinha

Uso nao permitido:

- texto principal
- borda de painel
- fundo de configuracoes
- estados de erro/sucesso semanticos

### 3.3 Tipografia

Fonte padrao: Material/Windows system font via Flutter.

Fonte numerica: `Roboto Mono` para cronometros.

Escala:

| Token | Tamanho | Peso | Uso |
|---|---:|---:|---|
| Display timer | 34 | bold | cronometro grande no overlay |
| Compact timer | 22 | bold | cartoes pequenos |
| Dialog title | 19-20 | bold | configuracoes, colirio, orientacoes |
| Section title | 12 | 700 | titulos uppercase de secao |
| Body | 14 | 400 | texto principal em paineis |
| Body small | 13-13.5 | 400 | descricao, orientacoes |
| Caption | 11-12 | 400-600 | referencias, disclaimers, versao |
| Menu item | 14 | 400/600 | linhas do menu |

Regras:

- Usar `letterSpacing: 1` apenas em secoes uppercase e cronometros.
- Evitar texto grande dentro de cards compactos.
- Limitar titulos compactos a 2 linhas com ellipsis.
- Textos longos devem ficar em dialogs rolaveis, nunca em janelas compactas.

### 3.4 Espacamento

Base grid: 4 px.

Tokens:

| Token | Valor | Uso |
|---|---:|---|
| `space-1` | 4 | ajustes finos |
| `space-2` | 8 | gaps internos pequenos |
| `space-3` | 12 | gap padrao entre icone/texto |
| `space-4` | 16 | padding compacto |
| `space-5` | 20 | padding de painel pequeno |
| `space-6` | 24 | padding de dialogs |
| `space-7` | 28 | overlay de pausa |
| `space-8` | 32 | respiro de overlay |

Aplicacao atual:

- Menu: padding vertical 6, row 11/14.
- Settings/guidance: padding 24/20/16.
- Gentle card: padding 16/14.
- Overlay: padding 28/32.

Regra: novos componentes devem usar esses valores em vez de numeros novos.

### 3.5 Radius

| Token | Valor | Uso |
|---|---:|---|
| `radius-sm` | 8 | botoes, inputs, swatches quadradas |
| `radius-md` | 10 | choice buttons, linguagem |
| `radius-lg` | 16 | menu flutuante |
| `radius-xl` | 18 | card pequeno |
| `radius-2xl` | 20-22 | dialogs |
| `radius-overlay` | 24 | overlay principal |
| `radius-full` | 999 | bolinha e color dots |

Nota: para desktop utilitario, evitar radius maior que 24 em paineis retangulares.

### 3.6 Blur, Opacidade e Sombra

`LiquidGlass` e o componente base.

Variantes:

| Variante | Dark | Blur | Fill | Radius | Uso |
|---|---|---:|---:|---:|---|
| Glass menu | true | 24 | 0.80 | 16 | menu da bolinha |
| Glass dialog | true | 24 | 0.80 | 20-22 | settings, update, colirio |
| Glass compact | true | 18 | 0.80 | 18 | gentle break, inatividade |
| Glass overlay | false | 20 | 0.15 | 24 | pausa full-screen |

Sombra padrao:

```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.38),
  blurRadius: 28,
  spreadRadius: -2,
  offset: Offset(0, 12),
)
```

Regras:

- Reduzir blur em cards pequenos para manter legibilidade.
- Evitar multiplas sombras aninhadas.
- Nao colocar cards dentro de cards.

## 4. Componentes

### 4.1 FloatingBall

Arquivo: `lib/widgets/floating_ball.dart`

Responsabilidade:

- Representar o estado sempre-presente do app.
- Exibir progresso do ciclo quando em repouso.
- Piscar em alerta/pausa.
- Permitir clique, clique direito e drag.

Estados:

| Estado | Visual | Interacao |
|---|---|---|
| Idle | cor normal, opacidade configuravel, anel opcional | tap abre menu, drag move |
| Active | cor alerta, piscando, sem anel | sem menu durante pausa |
| Disabled | janela escondida, tray continua | tray reabilita |

Regras:

- Tamanho configuravel: 24 a 80 px.
- Padding da janela compacta: `ballSize + 24`.
- Cursor: `SystemMouseCursors.grab`.
- Anel branco somente quando `!isActive`.

### 4.2 FloatingMenu

Arquivo: `lib/widgets/floating_menu.dart`

Uso:

- Menu contextual da bolinha em `AppState.idle`.
- Deve ser compacto e escaneavel.

Especificacao:

- Largura: 230 px.
- Radius: 16.
- Linha: icone 18 px + label 14 px.
- Hover: fundo translúcido, icone azul, barra esquerda azul.
- Fechar ao escolher qualquer item.

Itens recomendados:

1. Iniciar pausa agora
2. Resetar cronometro
3. Pausar/Retomar cronometro
4. Orientacoes
5. Verificar atualizacoes
6. Configuracoes
7. Sair

### 4.3 SettingsDialog

Arquivo: `lib/widgets/settings_dialog.dart`

Uso:

- Configuracao detalhada, nao para uso frequente a cada minuto.

Especificacao:

- Largura: 400 px dentro de janela 460 px.
- Max height: 640 px.
- Padding: 24 horizontal, 20 top, 16 bottom.
- Conteudo rolavel.
- Rodape fixo com `Restaurar padroes` e `Salvar`.

Regras para proximas melhorias:

- Agrupar secoes por frequencia de uso.
- Colocar "Geral" antes de opcoes avancadas de visibilidade.
- Usar switches para booleanos.
- Usar sliders apenas para valores numericos continuos.
- Usar choice buttons para opcoes fechadas como 4h/6h.
- Nao adicionar texto explicativo longo em cada controle.

### 4.4 GentleBreakCard

Arquivo: `lib/widgets/gentle_break_card.dart`

Uso:

- Notificacao suave de pausa ocular.
- Modelo visual para futuras notificacoes compactas, como inatividade.

Especificacao:

- Posicao: canto superior direito.
- Margem: 12 px no card atual; para Windows preferir 16 px.
- Icone: 26 px.
- Gap icone/texto: 12 px.
- Titulo: 14 px, semibold, max 2 linhas.
- Timer compacto: 22 px, `Roboto Mono`, bold.

### 4.5 InactivityPauseCard

Status: proposto.

Arquivo sugerido: `lib/widgets/inactivity_pause_card.dart`

Uso:

- Aviso pequeno quando o timer pausa por inatividade.

Especificacao:

- Variante: Glass compact.
- Janela: `Size(320, 120)` ou `Size(340, 132)` se o texto em EN estourar.
- Posicao: canto superior direito.
- Icone: `Icons.pause_circle_outline` ou `Icons.hourglass_empty`.
- Titulo: `Timer pausado`.
- Corpo: uma frase curta.
- Botao: `TextButton` pequeno ou `FilledButton.tonal` se disponivel no tema.
- Sem som, sem toast nativa.

Prioridade visual:

1. Pausa ocular ativa.
2. Colirio.
3. Inatividade.
4. Bolinha/menu.

### 4.6 GlassOverlay

Arquivo: `lib/widgets/glass_overlay.dart`

Uso:

- Pausa 20-20-20 em modo bloqueante.

Especificacao:

- Max width: 400 px.
- Min width: 240 px.
- Padding: 28 horizontal, 32 vertical.
- Radius: 24.
- Titulo: 20 semibold.
- Corpo: 16 regular.
- Timer: 34 mono bold.
- Olho animado: 96 px.

Regras:

- Usar somente para pausa ocular ativa, nao para inatividade.
- Dim background deve ser configuravel.
- Nao bloquear input quando invisivel.

### 4.7 EyeDropsReminder

Arquivo: `lib/widgets/eye_drops_reminder.dart`

Uso:

- Lembrete centralizado para colirio.

Especificacao:

- Largura: 360 px.
- Radius: 22.
- Iconografia: animacao de frasco/gota.
- CTA: `FilledButton`.
- Titulo: 19 bold.
- Corpo: 14, line-height 1.4.

### 4.8 UpdateDialog

Arquivo: `lib/widgets/update_dialog.dart`

Uso:

- Resultado de verificacao de atualizacao.

Estados:

- Checking: icone sync azul.
- Up to date: check verde.
- Available: download azul + CTA.
- Error: error vermelho.

Regras:

- Mostrar versao atual como caption.
- Usar `TextButton` para fechar.
- Usar `FilledButton.icon` apenas quando ha download.

## 5. Iconografia

Biblioteca: Material Icons do Flutter.

Tamanhos:

- Menu: 18 px.
- Card compacto: 24-26 px.
- Dialog status: 48 px.
- Header close: IconButton padrao.

Regras:

- Usar icone + texto para linhas de menu.
- Usar icon-only apenas para fechar, tray e controles universalmente reconheciveis.
- Evitar icones decorativos sem funcao em dialogs densos.

## 6. Movimento

Animacoes atuais:

- Bolinha ativa: blink de opacidade.
- Timer: bounce leve a cada segundo.
- Menu: hover com deslocamento e escala.
- Eye: blink a cada ciclo.
- Dropper: gota em loop.
- Overlay: fade/AnimatedSwitcher.

Tokens recomendados:

| Token | Duracao | Uso |
|---|---:|---|
| `motion-fast` | 160 ms | hover, menu row |
| `motion-medium` | 300 ms | timer bounce |
| `motion-fade` | 500 ms | overlay fade |
| `motion-loop-eye` | 3200 ms | blink eye |
| `motion-loop-drop` | 1600 ms | dropper |

Regras:

- Nao animar configuracoes durante scroll.
- Evitar loops simultaneos em cards pequenos.
- Pausa por inatividade nao deve piscar.
- Considerar `MediaQuery.disableAnimations` em uma evolucao futura.

## 7. Layout Windows

Janelas:

| Layout | Tamanho | Posicao |
|---|---:|---|
| Compact ball | `ballSize + 24` | posicao salva ou canto padrao |
| Menu | 250 x 400 | posicao da bolinha, com nudge para tela |
| Settings | 460 x 700 | centro |
| Full break | bounds da tela primaria | tela inteira |
| Gentle break | 340 x 150 | canto superior direito |
| Inactivity | 320 x 120 | canto superior direito |

Regras Windows:

- Sempre aplicar `setAlwaysOnTop(true)` apos mudanca de layout.
- Manter janela frameless.
- Usar `WindowEffect.transparent`.
- Testar em escala 125% e 150%.
- Testar com tray em overflow.
- Evitar janelas maiores que 700 px de altura para configuracoes.

## 8. Acessibilidade

Contraste:

- Texto primario deve ser branco em paineis escuros.
- Texto secundario nao deve ficar abaixo de `#CCFFFFFF`.
- Cores customizadas da bolinha nao devem afetar texto.

Tamanho de alvo:

- Itens de menu: altura minima aproximada 40 px.
- Botoes: altura minima Material padrao.
- Color dots: 28 px atual; alvo aceitavel para desktop, mas ideal futuro 32 px.

Teclado:

- Dialogs devem permitir foco em botoes.
- Fechar com `Esc` e confirmar com `Enter` sao melhorias recomendadas.

Reducao de movimento:

- Futuro: respeitar `MediaQuery.disableAnimations`.
- Futuro: pausar loops decorativos quando janela nao esta visivel.

## 9. Conteudo e Tom

Tom:

- Curto.
- Gentil.
- Sem alarmismo.
- Educativo apenas onde o usuario pediu orientacoes.

Padroes:

- Acoes em verbo no infinitivo ou imperativo curto: `Retomar`, `Salvar`, `Baixar`.
- Mensagens de sistema devem explicar estado + proxima acao.
- Evitar paragrafos longos em cards compactos.
- Referencias cientificas ficam apenas em `GuidanceDialog`.

## 10. Mapeamento para Codigo

Recomendacao de refactor futuro:

- Criar `lib/theme/design_tokens.dart`.
- Migrar cores atuais de `AppColors` para tokens semanticos.
- Criar helpers de espaco/radius/blur.
- Extrair controles compartilhados de settings:
  - `SettingsSectionTitle`
  - `SettingsSwitchRow`
  - `SettingsSliderRow`
  - `SettingsChoiceButton`
  - `ColorSwatch`
- Criar variantes do `LiquidGlass`:
  - `LiquidGlass.menu`
  - `LiquidGlass.dialog`
  - `LiquidGlass.compact`
  - `LiquidGlass.overlay`

## 11. Checklist para Novas Telas

- [ ] A tela usa variante correta de `LiquidGlass`.
- [ ] A janela tem tamanho definido e responsivo ao conteudo.
- [ ] Nenhum texto longo aparece em card compacto.
- [ ] A cor semantica corresponde ao estado.
- [ ] Hover e cursor estao definidos em areas clicaveis.
- [ ] Controles usam padroes familiares: switch, slider, menu, botao.
- [ ] Texto passa por `AppStrings`.
- [ ] O layout funciona com Windows scaling 125%/150%.
- [ ] A tela nao esconde a bolinha/tray sem rota de retorno.
- [ ] `flutter analyze` e `flutter test` passam.

## 12. Prioridades de Design

### Alta

- Criar `InactivityPauseCard` seguindo `Glass compact`.
- Formalizar tokens em codigo para reduzir numeros soltos.
- Melhorar organizacao visual de `SettingsDialog`.

### Media

- Adicionar variantes nomeadas ao `LiquidGlass`.
- Adicionar suporte a `Esc` para fechar dialogs.
- Padronizar botoes e choice controls.

### Baixa

- Adicionar modo de movimento reduzido.
- Criar preview da bolinha dentro das configuracoes.
- Refinar tray icon por DPI se houver relato visual no Windows.
