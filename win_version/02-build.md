# 02 — Compilar a versão Windows

## Build de Release

```powershell
flutter clean
flutter pub get
dart run flutter_launcher_icons
flutter build windows --release
```

Saída:

```
build\windows\x64\runner\Release\
├── dry_eye_widget.exe        <- executável principal
├── flutter_windows.dll
├── *.dll                     <- DLLs dos plugins (audioplayers, etc.)
└── data\                     <- assets, ícones, fontes, app.so equivalente
```

> **Importante:** o app **não é** um único `.exe`. Para distribuir, leve a pasta
> `Release\` inteira (ou empacote com instalador/ZIP — ver `04-empacotamento.md`).
> Rodar o `.exe` fora dessa pasta, sem as DLLs e a pasta `data\`, **não funciona**.

## Verificar a build localmente

```powershell
cd build\windows\x64\runner\Release
.\dry_eye_widget.exe
```

Confirme rapidamente (validação completa em `03-notas-plataforma.md`):

- a janela abre **sem janela de console** preta;
- a bolinha aparece com **fundo transparente** (sem retângulo opaco);
- a bolinha fica **acima das outras janelas** (always-on-top);
- aparece o **ícone na bandeja** do sistema.

## Versão / metadados do `.exe`

O `windows/runner/Runner.rc` deriva a versão dos defines `FLUTTER_VERSION_*`,
que o Flutter preenche a partir do `version:` do `pubspec.yaml` (`1.6.0+9`).
Para personalizar nome de produto / empresa que aparecem em
**Propriedades → Detalhes** do `.exe`, edite os blocos `StringFileInfo` em
`windows/runner/Runner.rc` (ex.: `CompanyName`, `ProductName`,
`FileDescription`, `LegalCopyright`). Sugestão de valores:

- `CompanyName`: `Saraiva Vision Care`
- `ProductName`: `Dry Eye Widget`
- `FileDescription`: `Lembrete da regra 20-20-20 para saúde ocular`

Mantenha o `BINARY_NAME` como `dry_eye_widget` (já definido em
`windows/CMakeLists.txt`) salvo decisão explícita do contrário — mudar afeta o
caminho de saída, o `launch_at_startup` e o instalador.

## Build de 32 bits?

Não é necessário. O Flutter desktop no Windows tem como alvo **x64**. Distribua
apenas x64.

## Reprodutibilidade

- Sempre rode `flutter clean` antes de uma build de release oficial.
- Fixe a versão do Flutter no CI (ver `05-ci-github-actions.md`) para builds
  determinísticas.
