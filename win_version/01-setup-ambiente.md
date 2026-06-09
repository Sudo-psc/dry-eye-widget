# 01 — Preparar o ambiente Windows

Objetivo: ter uma máquina Windows capaz de compilar Flutter desktop.

## Requisitos

- **Windows 10 (1809+) ou Windows 11**, 64 bits.
- **Flutter SDK** estável **3.44.x ou superior**. O CI está fixado em
  `3.44.1`, que também é a versão validada localmente.
- **Visual Studio 2022** (não o VS Code) com o workload
  **"Desktop development with C++"** — inclui o MSVC, o Windows 10/11 SDK e o
  CMake. Sem isso, `flutter build windows` falha.
- **Git** para Windows.
- (Opcional) **Inno Setup 6** para gerar o instalador — ver `04-empacotamento.md`.

## Passo a passo

### 1. Instalar o Flutter

Baixe de https://docs.flutter.dev/get-started/install/windows e extraia para,
por exemplo, `C:\src\flutter`. Adicione `C:\src\flutter\bin` ao `PATH`.

```powershell
flutter --version
```

### 2. Instalar o Visual Studio 2022 + C++

No instalador do Visual Studio, marque o workload **"Desktop development with C++"**.
Componentes essenciais (normalmente já vêm no workload):

- MSVC v143 — VS 2022 C++ x64/x86 build tools
- C++ CMake tools for Windows
- Windows 11 SDK (ou Windows 10 SDK)

### 3. Habilitar desktop e validar o ambiente

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
```

`flutter doctor` deve mostrar **Visual Studio - develop for Windows** com check
verde. Resolva qualquer ❌ antes de prosseguir (a causa mais comum é o workload
C++ ausente).

### 4. Clonar e preparar o projeto

```powershell
git clone https://github.com/Sudo-psc/dry-eye-widget.git
cd dry-eye-widget
flutter pub get
```

### 5. Gerar os ícones (gera o `.ico` do app a partir de `icon.png`)

O `pubspec.yaml` já configura `flutter_launcher_icons` para Windows
(`icon_size: 256`). Gere:

```powershell
dart run flutter_launcher_icons
```

Isso atualiza `windows/runner/resources/app_icon.ico`. Confirme que o arquivo
foi regenerado.

### 6. Sanidade rápida (debug)

```powershell
flutter run -d windows
```

A janela da bolinha deve abrir. Use isto só para um primeiro "liga/desliga"; a
validação séria de transparência/bandeja é feita em **Release** (ver
`02-build.md` e `03-notas-plataforma.md`), pois alguns efeitos diferem entre
debug e release.

## Problemas comuns

| Sintoma | Causa provável | Solução |
|---------|----------------|---------|
| `Unable to find suitable Visual Studio` | Workload C++ ausente | Instalar "Desktop development with C++" |
| `cmake` não encontrado | Componente CMake do VS ausente | Adicionar "C++ CMake tools for Windows" |
| Build falha em plugin nativo | SDK do Windows ausente | Instalar Windows 10/11 SDK |
| `flutter doctor` ok mas build trava | Cache antigo | `flutter clean` e repetir |
