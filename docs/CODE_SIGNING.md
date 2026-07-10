# Assinatura de código — macOS e Windows

Atualizado: 2026-07-10 · ROADMAP Now #1

Sem assinatura paga, o macOS (Gatekeeper) e o Windows (SmartScreen) avisam
usuários na primeira execução. Este documento descreve o **pipeline pronto no
CI** e o que falta **somente de credenciais/contas** (não de código).

## Status do pipeline

| Plataforma | Artefato | No CI | Ativa quando | Doc detalhada |
|------------|----------|-------|--------------|---------------|
| Windows | `DryEyeWidget-Setup-x64.exe` | SignPath (OSS) | `SIGNPATH_API_TOKEN` + vars | `win_version/CODE_SIGNING.md` |
| Windows | MSIX Store | Store assina | Partner Center | `windows-msix.yml` |
| macOS | `DryEyeWidget.dmg` | codesign + notarytool | certificado + Apple ID/API | este arquivo |



## Checklist de ativação (conta / secrets)

Pipeline de código: **pronto**. Ativação depende só de credenciais.

```bash
./scripts/check_signing_readiness.sh
```

1. Apple Developer Program + certificado **Developer ID Application** (`.p12`)
2. Secrets GitHub: `MACOS_CERTIFICATE_BASE64`, `MACOS_CERTIFICATE_PASSWORD`
3. Notarização: API Key **ou** App-specific password
4. SignPath OSS: `SIGNPATH_API_TOKEN` + variables do projeto
5. Rodar release tag `v*` e confirmar artefato assinado no job summary

Enquanto secrets não existirem, o CI continua publicando builds **unsigned**
com orientação `xattr`/SmartScreen (comportamento esperado).

> Builds **sempre** geram artefatos mesmo sem secrets — a assinatura é
> **condicional**. Releases sem secrets continuam funcionando; o usuário usa
> o fluxo `xattr`/SmartScreen documentado na landing e no DMG.

---

## macOS (Developer ID + notarização)

### O que o CI faz

Workflow: `.github/workflows/macos-build.yml`

1. `flutter build macos --release`
2. Se secrets presentes → `scripts/macos_import_cert.sh`
3. `scripts/macos_sign_and_notarize.sh`  
   - `codesign --deep --options runtime` no `.app`  
   - reempacota DMG  
   - assina o DMG  
   - `notarytool submit --wait` + `stapler staple` (se credenciais de notarização)
4. Anexa `dist/DryEyeWidget.dmg` à release (tags `v*`)

### Secrets e variables (GitHub → Settings → Secrets and variables → Actions)

**Secrets (obrigatórios para assinar):**

| Nome | Conteúdo |
|------|----------|
| `MACOS_CERTIFICATE_BASE64` | Arquivo `.p12` do **Developer ID Application** em base64 (`base64 -i cert.p12 \| pbcopy`) |
| `MACOS_CERTIFICATE_PASSWORD` | Senha do `.p12` |

**Secrets (notarização — escolha um método):**

| Método | Secrets |
|--------|---------|
| App-specific password | `APPLE_ID`, `APPLE_TEAM_ID`, `APPLE_APP_SPECIFIC_PASSWORD` |
| API Key (recomendado em CI) | `APPLE_API_KEY_BASE64` (conteúdo do `.p8`), `APPLE_API_KEY_ID`, `APPLE_API_ISSUER` |

**Variable opcional:**

| Nome | Uso |
|------|-----|
| `MACOS_IDENTITY` | String exata, ex. `Developer ID Application: Saraiva Vision Care LTDA (XXXXXXXXXX)`. Se vazia, o script detecta no keychain. |

### Pré-requisitos na conta Apple

1. [Apple Developer Program](https://developer.apple.com/programs/) (pago, anual)
2. Certificado **Developer ID Application** (não “Apple Development”)
3. Exportar como `.p12` no Keychain Access
4. Para notarização: App-specific password em appleid.apple.com **ou** API Key em App Store Connect → Users and Access → Integrations → Team Keys

### Local (opcional)

```bash
export MACOS_SIGNING_ENABLED=true
export MACOS_IDENTITY="Developer ID Application: Seu Nome (TEAMID)"
flutter build macos --release
./scripts/macos_sign_and_notarize.sh 1.22.7
```

---

## Windows (SignPath OSS)

Já implementado em `.github/workflows/windows-build.yml`.  
Passo a passo de inscrição e secrets: **`win_version/CODE_SIGNING.md`**.

Resumo dos valores:

- Secret: `SIGNPATH_API_TOKEN`
- Vars: `SIGNPATH_ORGANIZATION_ID`, `SIGNPATH_PROJECT_SLUG`, `SIGNPATH_POLICY_SLUG`

---

## Como saber se a release saiu assinada

1. Aba **Summary** do job de build (GitHub Actions) — seção “macOS signing” / “Windows signing”
2. Localmente:

```bash
# macOS
codesign -dv --verbose=4 dist/DryEyeWidget.dmg
spctl -a -vv -t open --context context:primary-signature dist/DryEyeWidget.dmg

# Windows (PowerShell)
Get-AuthenticodeSignature .\dist\DryEyeWidget-Setup-x64.exe
```

---

## Checklist operacional (desbloqueio do ROADMAP #1)

- [ ] Conta Apple Developer ativa
- [ ] Certificado Developer ID Application exportado (`.p12`)
- [ ] Secrets macOS cadastrados no repositório
- [ ] Método de notarização configurado (API Key ou app password)
- [ ] Projeto aprovado no SignPath Foundation
- [ ] Secret + vars SignPath cadastrados
- [ ] Tag `vX.Y.Z` de teste e validação em máquina limpa (sem `xattr`, sem “Executar mesmo assim”)

Até o checklist fechar, a landing e o FAQ continuam orientando o fluxo sem certificado.

---

## Relação com HealthKit

Validação de HealthKit em build assinado (ROADMAP Now #3) **depende** deste
item: entitlements sensíveis exigem assinatura com o Team ID correto. Após o
primeiro DMG notarizado, priorizar o item #3.
