# Assinatura de código (Windows) — SmartScreen, Defender e bloqueios

> Visão unificada macOS + Windows: **[`docs/CODE_SIGNING.md`](../docs/CODE_SIGNING.md)**.

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

## Como assinar via SignPath (caminho escolhido — grátis para open source)

O [SignPath Foundation](https://signpath.org/) assina projetos **open-source**
de graça, com certificado e HSM gerenciados por eles. A assinatura roda **nos
servidores do SignPath**: o CI sobe o instalador como artefato, o SignPath assina
e devolve o arquivo assinado. O `.github/workflows/windows-build.yml` **já tem os
passos prontos** — eles ativam quando os valores abaixo existirem.

> **Escopo atual:** o workflow assina o **instalador** (`DryEyeWidget-Setup-x64.exe`),
> que é o arquivo que o usuário baixa e o que o SmartScreen avalia. Assinar
> também o `dry_eye_widget.exe` interno é um follow-up opcional (exigiria uma
> segunda submissão antes de gerar o ZIP/instalador).

### 1. Inscrever o projeto no SignPath Foundation

1. Acesse https://signpath.org/ e solicite a inscrição como projeto open-source
   (o repositório precisa ser público — o `dry-eye-widget` é).
2. Após a aprovação, você terá uma **organização** em `app.signpath.io`.

### 2. Configurar a organização no SignPath

No painel (`app.signpath.io`), crie/anote:

- **Organization ID** — GUID da organização (em *Settings*).
- **Project** — um projeto (ex.: slug `dry-eye-widget`).
- **Artifact configuration** — tipo "Authenticode" para `.exe`.
- **Signing policy** — uma política (ex.: slug `release-signing`).
- **CI user + API token** — crie um usuário de CI e gere um **API token**.

> Siga o wizard "GitHub Actions" do próprio SignPath: ele conecta o token ao seu
> repositório e valida a origem do build (trusted build).

### 3. Cadastrar o secret + as variables no GitHub

Em **Settings → Secrets and variables → Actions**:

- **Secret** (aba *Secrets*):
  ```
  SIGNPATH_API_TOKEN        # token do usuário de CI do SignPath
  ```
- **Variables** (aba *Variables* — não são segredos):
  ```
  SIGNPATH_ORGANIZATION_ID  # GUID da organização
  SIGNPATH_PROJECT_SLUG     # ex.: dry-eye-widget
  SIGNPATH_POLICY_SLUG      # ex.: release-signing
  ```

### 4. Pronto

Com `SIGNPATH_API_TOKEN` presente, os passos `Subir instalador`,
`Assinar instalador (SignPath)` e `Aplicar instalador assinado` rodam
automaticamente em cada tag `v*` (a condição `if: ${{ env.SIGN_SIGNPATH == 'true' }}`
os ativa). Sem o token, são pulados e o build segue não assinado.

> **Reputação:** o certificado do SignPath Foundation é **OV** — remove o "Editor
> desconhecido" e reduz alertas, mas o SmartScreen ainda constrói reputação ao
> longo dos downloads. Reputação **imediata** só com um certificado **EV** próprio.

### Alternativas (não escolhidas)

- **Azure Trusted Signing** (~US$ 10/mês) — assinatura em nuvem da Microsoft.
- **Certum Open Source** (~€30/ano) — certificado OV barato para OSS.
- **EV próprio** (DigiCert/SSL.com/Sectigo, ~US$ 250+/ano) — reputação imediata.

---

## Enquanto não há certificado — orientação ao usuário final

Documente na release/README que, na primeira execução, o usuário deve:

1. Clicar em **"Mais informações"** na tela do SmartScreen.
2. Clicar em **"Executar assim mesmo"**.

Isso é esperado para apps de editor independente sem certificado e **não** indica
que o instalador esteja comprometido.
