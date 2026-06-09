# Assinatura de código (Windows) — SmartScreen, Defender e bloqueios

Este documento explica **por que** o instalador do Dry Eye Widget pode disparar
alertas de segurança no Windows e **o que** já foi feito para reduzi-los — além
do que **só** um certificado de assinatura de código resolve.

## TL;DR

| Medida | Reduz alertas? | Elimina o SmartScreen? | Custo |
|--------|:--:|:--:|:--:|
| Metadados completos no `.iss` (publisher, version info, AppId) | ✅ | ❌ | grátis (já feito) |
| Version info no `.exe` (`Runner.rc`) | ✅ | ❌ | grátis (já feito) |
| Config Inno Setup sem flags exóticas | ✅ | ❌ | grátis (já feito) |
| **Assinatura Authenticode (OV)** | ✅✅ | ⚠️ parcial (reputação) | pago |
| **Assinatura Authenticode (EV)** | ✅✅ | ✅ (reputação imediata) | pago, mais caro |

> **Honestidade técnica:** sem um certificado de assinatura de código, **não há
> como eliminar 100%** o aviso "O Windows protegeu o seu PC" (SmartScreen) na
> primeira execução de um instalador novo/pouco baixado. As melhorias deste
> repositório reduzem heurísticas de antivírus e a aparência de "binário
> anônimo", mas o SmartScreen é baseado em **reputação + assinatura**.

---

## Por que aparecem alertas e bloqueios?

1. **Executável/instalador não assinado** → SmartScreen mostra "Editor
   desconhecido" e Defender pode atrasar/bloquear a execução.
2. **Reputação baixa** → mesmo assinado com certificado **OV**, um binário novo
   tem pouca reputação e pode aparecer alerta até acumular downloads. Com
   certificado **EV**, a reputação é concedida na hora.
3. **Metadados ausentes** (publisher, descrição, version info) → aumentam a
   chance de o antivírus marcar o arquivo como suspeito por heurística.
4. **Flags de empacotamento incomuns** (compressão exótica, auto-extração
   atípica) → também alimentam heurísticas de AV.

## O que já foi corrigido neste repositório (sem certificado)

- **`win_version/templates/dry-eye-widget.iss`**
  - `AppId` GUID estável (não trocar — ver comentário no arquivo);
  - `VersionInfoVersion/Company/Description/ProductName/ProductVersion/Copyright`
    embutidos no **próprio instalador**;
  - `AppPublisher`, `AppPublisherURL`, `AppCopyright`, `AppVerName`,
    `UninstallDisplayName`, `UninstallDisplayIcon`;
  - `MinVersion=10.0.17763` (Windows 10 1809+);
  - `WizardStyle=modern`, `Compression=lzma2`/`SolidCompression` (padrão — sem
    flags que disparam AV);
  - `CloseApplications=yes` para upgrades limpos.
- **`windows/runner/Runner.rc`** — `CompanyName`, `FileDescription`,
  `ProductName` e `LegalCopyright` legíveis (antes eram `dry_eye_widget` /
  `com.saraivavision`, genéricos demais). A versão numérica continua vindo dos
  macros do Flutter (`FLUTTER_VERSION_*`), ou seja, casa com o `pubspec.yaml`.

## O que **só** o certificado resolve

- Remover o rótulo "Editor desconhecido" (passa a exibir "Saraiva Vision Care").
- Encurtar/eliminar o aviso do SmartScreen na primeira execução (EV: imediato;
  OV: conforme reputação acumula).
- Reduzir falsos-positivos de antivírus de forma consistente.

---

## Como assinar (quando houver certificado)

O workflow `.github/workflows/windows-build.yml` **já tem os passos prontos**,
desativados até existirem os secrets. Eles assinam **tanto** o `dry_eye_widget.exe`
**quanto** o instalador final.

### 1. Obter o certificado

- Compre um **Code Signing Certificate** (OV ou, idealmente, **EV**) de uma CA
  (DigiCert, Sectigo, GlobalSign, SSL.com, etc.).
- Exporte como `.pfx` (PKCS#12) com a chave privada e uma senha.
  - Obs.: certificados **EV** modernos exigem token de hardware (HSM/USB) ou
    serviço de assinatura em nuvem; nesse caso o passo do CI muda para usar o
    provedor do token em vez de um `.pfx` local. Os passos abaixo cobrem o caso
    **`.pfx` (OV)**, que é o mais simples de automatizar.

### 2. Cadastrar os secrets no GitHub

Em **Settings → Secrets and variables → Actions → New repository secret**:

```
WINDOWS_CERT_BASE64    # conteúdo do .pfx em base64
WINDOWS_CERT_PASSWORD  # senha do .pfx
```

Para gerar o base64 a partir do `.pfx`:

```powershell
# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.pfx")) | Set-Clipboard
```

```bash
# macOS/Linux
base64 -i cert.pfx | pbcopy   # macOS
base64 -w0 cert.pfx           # Linux
```

### 3. Pronto

Com os secrets presentes, os passos `Assinar executável (se houver certificado)`
e `Assinar instalador (se houver certificado)` passam a rodar automaticamente
(a condição `if: ${{ secrets.WINDOWS_CERT_BASE64 != '' }}` os ativa). Sem os
secrets, eles são pulados e o build continua igual (não assinado).

### Assinatura manual (local)

```powershell
signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 `
  /f cert.pfx /p <senha> `
  build\windows\x64\runner\Release\dry_eye_widget.exe

signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 `
  /f cert.pfx /p <senha> dist\DryEyeWidget-Setup-x64.exe
```

> Sempre use **timestamp** (`/tr`): garante que a assinatura continue válida
> após o certificado expirar.

---

## Enquanto não há certificado — orientação ao usuário final

Documente na release/README que, na primeira execução, o usuário deve:

1. Clicar em **"Mais informações"** na tela do SmartScreen.
2. Clicar em **"Executar assim mesmo"**.

Isso é esperado para apps de editor independente sem certificado e **não** indica
que o instalador esteja comprometido.
