# 04 — Empacotamento e distribuição (Windows)

A build gera a pasta `build\windows\x64\runner\Release\`. Há duas formas de
distribuir, que **não são exclusivas** (o ideal é oferecer as duas):

1. **Instalador** (`.exe` via Inno Setup) — recomendado, pois cria o atalho no
   Menu Iniciar (necessário para notificações toast confiáveis e para o "iniciar
   com o login" ter caminho estável).
2. **ZIP portátil** — simples, sem instalação, mas com as ressalvas de toast e
   startup descritas em `03-notas-plataforma.md`.

---

## Opção A — Instalador com Inno Setup (recomendado)

### Pré-requisito

Instale o **Inno Setup 6**: https://jrsoftware.org/isdl.php
O compilador de linha de comando é `ISCC.exe` (normalmente em
`C:\Program Files (x86)\Inno Setup 6\ISCC.exe`).

### Script

Use `templates/dry-eye-widget.iss` (já incluído nesta pasta). Ele:

- empacota todo o conteúdo de `build\windows\x64\runner\Release\`;
- instala em `Program Files\Dry Eye Widget`;
- cria atalho no Menu Iniciar e (opcional) na Área de Trabalho;
- registra desinstalador;
- usa o ícone `windows\runner\resources\app_icon.ico`.

Copie o template para a raiz do repositório (ou rode apontando o caminho) e
compile:

```powershell
flutter build windows --release
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" win_version\templates\dry-eye-widget.iss
```

Saída padrão: `dist\DryEyeWidget-Setup-x64.exe`.

> Ajuste `MyAppVersion` no `.iss` para casar com o `pubspec.yaml` antes de
> compilar uma release oficial.

### Testar o instalador

Em um **Windows limpo** (de preferência uma VM/sandbox):

1. Rode `DryEyeWidget-Setup-x64.exe` e instale.
2. Abra pelo atalho do Menu Iniciar.
3. Refaça a validação de **notificações** e **iniciar com o login** (que só são
   confiáveis instalados).
4. Desinstale pelo "Adicionar ou remover programas" e confirme limpeza.

---

## Opção B — ZIP portátil

```powershell
flutter build windows --release
$src = "build\windows\x64\runner\Release"
New-Item -ItemType Directory -Force -Path dist | Out-Null
Compress-Archive -Path "$src\*" -DestinationPath "dist\DryEyeWidget-windows-x64.zip" -Force
```

O usuário extrai e roda `dry_eye_widget.exe`. Inclua um `LEIAME.txt` curto
avisando para **não separar** o `.exe` das DLLs e da pasta `data\`.

---

## Assinatura de código (reduz alertas do SmartScreen)

Sem assinatura, o **Windows SmartScreen** mostrará "Editor desconhecido" na
primeira execução do instalador. O `.iss` e o `Runner.rc` deste repositório já
embutem **metadados completos** (publisher, version info, copyright), o que
reduz heurísticas de antivírus — mas **a eliminação do SmartScreen exige um
certificado de assinatura de código** (pago).

Detalhes completos, incluindo os passos de `signtool` e o scaffolding já pronto
(porém desativado) no workflow do GitHub Actions, estão em
**[`CODE_SIGNING.md`](CODE_SIGNING.md)**.

Se não houver certificado, documente no README que o usuário precisa clicar em
"Mais informações → Executar assim mesmo" na primeira vez.

---

## Versionamento e Releases

- A versão de exibição vem do `pubspec.yaml` (`version: 1.6.1+10`) e de
  `AppInfo.version` em `lib/utils/constants.dart` (`1.6.0`). **Mantenha as duas em
  sincronia** — a checagem de atualização do app compara com a tag do GitHub.
- A release no GitHub deve ter tag no formato `vX.Y.Z` (ex.: `v1.6.0`), pois
  `UpdateService` normaliza tags `v?\d+\.\d+\.\d+`.
- Anexe à Release: o instalador `DryEyeWidget-Setup-x64.exe` e/ou o
  `DryEyeWidget-windows-x64.zip`. Não comite binários no git.

## Nomes de arquivo sugeridos (consistência com o macOS `.dmg`)

| Plataforma | Artefato |
|-----------|----------|
| macOS | `DryEyeWidget.dmg` |
| Windows (instalador) | `DryEyeWidget-Setup-x64.exe` |
| Windows (portátil) | `DryEyeWidget-windows-x64.zip` |
