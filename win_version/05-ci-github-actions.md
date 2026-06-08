# 05 — CI/CD com GitHub Actions (build Windows)

Automatiza a compilação Windows e (em tags de versão) anexa os artefatos à
Release. O workflow pronto está em `templates/windows-build.yml`.

## Instalar

Copie o template para o local que o GitHub espera:

```
.github/workflows/windows-build.yml
```

```powershell
# a partir da raiz do repositório
New-Item -ItemType Directory -Force -Path .github\workflows | Out-Null
Copy-Item win_version\templates\windows-build.yml .github\workflows\windows-build.yml
```

(No macOS/Linux: `mkdir -p .github/workflows && cp win_version/templates/windows-build.yml .github/workflows/`)

## O que o workflow faz

- **Gatilhos:** `push` em tags `v*` (release) e `workflow_dispatch` (manual);
  `pull_request` apenas compila (sem publicar).
- Roda em `windows-latest` (já tem Visual Studio 2022 com C++).
- Instala o Flutter (versão fixada), `flutter pub get`, gera ícones e
  `flutter build windows --release`.
- Gera o **ZIP portátil** sempre.
- Instala o **Inno Setup** e gera o **instalador** quando o `.iss` existe.
- Faz **upload dos artefatos** do build (disponíveis em toda execução).
- Em tags `v*`, **cria/atualiza a Release** anexando instalador e ZIP
  (usando o `GITHUB_TOKEN` — sem segredos extras).

## Permissões

O workflow declara `permissions: contents: write` para poder criar a Release.
Confirme em **Settings → Actions → General → Workflow permissions** que o
repositório permite escrita (ou que o token do workflow já tem `contents: write`,
como declarado no YAML).

## Publicar uma release Windows

```powershell
# alinhe pubspec.yaml (version:) e AppInfo.version, então:
git tag v1.6.0
git push origin v1.6.0
```

O workflow compila e anexa `DryEyeWidget-Setup-x64.exe` e
`DryEyeWidget-windows-x64.zip` à release `v1.6.0`.

## Observações

- **Fixe a versão do Flutter** no workflow para builds reprodutíveis (o template
  usa `subosito/flutter-action` com `flutter-version`).
- Assinatura de código no CI exige guardar o `.pfx` como **secret** e usar
  `signtool` — fora do escopo padrão; adicione só se houver certificado.
- O cache de pub (`~/.pub-cache`) acelera execuções; o template já habilita o
  cache do `flutter-action`.
