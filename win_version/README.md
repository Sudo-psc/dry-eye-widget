# win_version — Geração da versão Windows do Dry Eye Widget

Esta pasta contém **tudo o que um agente de IA (Claude) precisa** para gerar,
empacotar e publicar a versão Windows do **Dry Eye Widget** a partir do código
Flutter já existente neste repositório.

> O app já é multiplataforma. O código Dart usa `Platform.isWindows` nos pontos
> certos, a pasta `windows/` está presente e o canal nativo de tempo ocioso já
> foi implementado em C++ (`windows/runner/flutter_window.cpp`). O trabalho aqui
> é **compilar, ajustar detalhes específicos do Windows, empacotar e publicar** —
> não reescrever o app.

## Como usar (para o agente Claude)

1. Leia **`AGENT_BRIEF.md`** primeiro — é a missão, o escopo e as regras.
2. Siga os documentos numerados na ordem:
   - `01-setup-ambiente.md` — preparar a máquina Windows + Flutter + Visual Studio
   - `02-build.md` — compilar (`flutter build windows`)
   - `03-notas-plataforma.md` — armadilhas específicas do Windows e como validar
   - `04-empacotamento.md` — gerar instalador (Inno Setup) e/ou ZIP portátil
   - `05-ci-github-actions.md` — automação de build/publish no GitHub Actions
   - `06-checklist-verificacao.md` — checklist final antes de declarar pronto
3. Use os arquivos em **`templates/`** como ponto de partida (Inno Setup e workflow).

## Estado atual do projeto (snapshot)

| Item | Valor |
|------|-------|
| Nome do pacote (pubspec) | `dry_eye_widget` |
| Versão | `1.6.1+10` |
| BINARY_NAME (CMake) | `dry_eye_widget` |
| Repositório | `https://github.com/Sudo-psc/dry-eye-widget` |
| SDK Dart | `>=3.12.0 <4.0.0` |
| Flutter mínimo | `>=3.44.0` |
| Plataformas | macOS (distribuído via `.dmg`) + Windows (a gerar) |

## Dependências relevantes para Windows

Todas já declaradas em `pubspec.yaml` e com suporte oficial a Windows:

- `window_manager` — janela frameless, always-on-top, transparente, arrastável
- `flutter_acrylic` — efeito de transparência/acrylic da janela
- `screen_retriever` — geometria dos monitores (posicionar a bolinha nos cantos)
- `tray_manager` — ícone na bandeja do sistema (system tray)
- `local_notifier` — notificações toast nativas
- `launch_at_startup` — iniciar com o login (entrada no registro `Run`)
- `audioplayers` — som de alerta
- `shared_preferences` — persistência das configurações
- `google_fonts`, `provider` — UI/estado

## Resultado esperado

Ao final, devem existir:

- `build/windows/x64/runner/Release/` com o executável e DLLs funcionando;
- Um **instalador** `DryEyeWidget-Setup-x64.exe` (Inno Setup) **e/ou** um ZIP
  portátil `DryEyeWidget-windows-x64.zip`;
- Um workflow do GitHub Actions que compila e anexa o artefato à Release;
- O `README.md`/`README.en.md` atualizados com o badge/link de download Windows.
