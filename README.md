# Dry Eye Widget 👁️💧

Widget flutuante de desktop (**macOS** e **Windows**), feito em **Flutter**, que
aplica a **regra 20-20-20** para conforto ocular e alívio do olho seco: a cada
ciclo de trabalho (padrão 20 minutos), ele lembra você de fazer uma pausa,
descansar os olhos e olhar para uma distância de ~6 metros por 20 segundos.

Uma pequena bolinha azul fica sempre visível (always-on-top) num canto da tela.
Quando chega a hora da pausa, ela fica vermelha e piscando, toca um alerta e
exibe um overlay de **"vidro líquido"** (blur + transparência) centralizado, com
um cronômetro regressivo guiando a pausa.

## Funcionalidades

- **Bolinha flutuante** always-on-top: azul no estado normal, vermelha piscando
  durante a pausa. Arrastável por toda a tela, com **posição persistida** entre
  sessões.
- **Máquina de estados** com uma única fase de pausa:
  `IDLE → ALERTA → FASE (pausa única de 20s) → CONCLUSÃO → IDLE`.
- **Overlay de vidro líquido** (blur + transparência) centralizado, com
  **cronômetro regressivo MM:SS** durante a pausa.
- Texto da fase de pausa:
  - **"Olhe para uma distância de 6 metros"**
  - **"Lembre-se de piscar ao olhar a uma distância de 6 m e mantenha o olhar
    até o cronômetro zerar"**
- Tela de **conclusão** ("Parabéns!") antes de retornar ao estado normal.
- **Som** (alerta, tique-taque, sucesso) e **notificações nativas**, ambos
  ativáveis/desativáveis.
- **Anel de progresso** opcional: arco branco horário ao redor da bolinha
  mostrando o tempo até a próxima pausa.
- **Iniciar com o sistema** (login item) e botão **"Restaurar padrões"**.
- **Persistência** via `SharedPreferences` (posição da bolinha, tempo decorrido
  e todas as preferências serializadas em JSON).

## Configurações

As preferências ficam num painel de configurações e são agrupadas assim:

### Geral / temporização
- Duração do ciclo (minutos até a próxima pausa).
- Duração da fase (segundos de pausa).
- Som ligado/desligado.
- Notificações ligadas/desligadas.
- Canto padrão da bolinha (superior esq./dir., inferior esq./dir., centro).
- **Iniciar com o sistema** (login item via `launch_at_startup`).
- Botão **"Restaurar padrões"**.

### Aparência
- Tamanho da bolinha.
- Cor no estado normal (via paleta).
- Cor de alerta (via paleta).
- Opacidade no estado normal (deixa a bolinha mais discreta).
- Velocidade do piscar.
- Anel de progresso (arco branco horário ao redor da bolinha).

### Durante a pausa
- Escurecer o fundo da tela + intensidade do escurecimento.
- Opacidade do overlay de vidro.
- Desfoque (blur) do overlay de vidro.

## Arquitetura

```
lib/
├── main.dart                       # Entry point: config da janela + layout dinâmico
├── models/
│   ├── app_state.dart              # Estados (IDLE, ALERTA, FASE1, CONCLUSAO) + cantos
│   └── widget_settings.dart        # Preferências imutáveis, copyWith + JSON
├── providers/
│   ├── settings_provider.dart      # Estado das configurações (ChangeNotifier)
│   └── timer_provider.dart         # Cronômetros + máquina de estados
├── services/
│   ├── audio_service.dart          # audioplayers + fallback de som do sistema
│   ├── notification_service.dart   # local_notifier
│   ├── startup_service.dart        # launch_at_startup (iniciar com o sistema)
│   └── storage_service.dart        # SharedPreferences
├── widgets/
│   ├── floating_ball.dart          # Bolinha azul/vermelha + piscar + anel de progresso
│   ├── glass_overlay.dart          # Overlay de vidro líquido
│   ├── timer_display.dart          # Cronômetro regressivo MM:SS
│   ├── floating_menu.dart          # Menu flutuante (clique na bolinha)
│   └── settings_dialog.dart        # Painel de configurações
└── utils/
    ├── constants.dart              # Cores, paleta, durações, textos, chaves de storage
    └── animations.dart             # Curvas e helpers de animação

assets/
└── sounds/                         # alert.wav, tick.wav, success.wav
```

> **Janela**: o app usa uma janela frameless e transparente, gerenciada por
> `window_manager`. No macOS a transparência real é obtida via
> `flutter_acrylic` (`makeWindowFullyTransparent`). No estado normal a janela
> tem o tamanho da bolinha e é movida nativamente ao arrastar — assim o resto
> da tela continua clicável. Durante a pausa ela ocupa a tela toda para exibir o
> overlay centralizado.

## Stack / dependências

- **Flutter 3.16+** (testado com 3.44.1).
- `window_manager`, `screen_retriever`, `flutter_acrylic` — janela
  frameless/transparente always-on-top.
- `audioplayers` — sons; `local_notifier` — notificações nativas.
- `launch_at_startup` — iniciar com o sistema.
- `shared_preferences` — persistência; `provider` — gerência de estado.
- `google_fonts` — tipografia.

## Pré-requisitos

- **Flutter 3.16+** (testado com 3.44.1).
- **macOS**: **Xcode completo** (App Store) — não basta o Command Line Tools.
  Após instalar, registre-o:
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  ```
- **Windows**: **Visual Studio 2022** com o workload
  **"Desktop development with C++"**. Builds Windows só podem ser gerados **em
  uma máquina Windows** — o Flutter não faz cross-compile de macOS para Windows.

## Como rodar (desenvolvimento)

```bash
flutter pub get
flutter run -d macos      # no macOS
flutter run -d windows    # no Windows
```

## Como compilar (release)

```bash
# macOS  → build/macos/Build/Products/Release/dry_eye_widget.app
flutter build macos --release

# Windows → build/windows/x64/runner/Release/dry_eye_widget.exe
flutter build windows --release
```

> O build macOS compila e roda (exige Xcode). O `.exe` de Windows fica pendente
> até ser gerado numa máquina Windows com o Visual Studio 2022.

## Qualidade

```bash
flutter analyze   # estático: sem issues
flutter test      # 10/10 testes passando (máquina de estados + settings)
```

## Sons

Os arquivos em `assets/sounds/` (`alert.wav`, `tick.wav`, `success.wav`) são
beeps **sintéticos** gerados localmente. Substitua-os por sons de sua
preferência mantendo os mesmos nomes. Se um arquivo faltar, o app cai para o
som de alerta do sistema automaticamente.

## Licença

Uso interno — Saraiva Vision Care.
