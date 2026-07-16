# Revisão de performance, build e preparação multiplataforma

Data: 2026-07-16
Branch: `main`
Versão: 1.24.2+72

## Escopo revisado

- reconstruções globais e listeners de providers;
- animações contínuas da bolinha e anel;
- persistência acionada por controles de alta frequência;
- montagem do questionário DVRS durante rolagem;
- build estático da landing/Science;
- pipelines macOS, Windows e Windows MSIX.

Não foram introduzidas novas animações contínuas. Os guardrails existentes da
bolinha e do anel continuam cobertos pela suíte.

## Baseline e otimizações

### Onboarding

Antes, cada evento de slider chamava `SettingsProvider.update`, notificava a
árvore e persistia em `SharedPreferences`. No teste, um único gesto gerou duas
atualizações antes de qualquer confirmação.

Depois, o fluxo mantém `WidgetSettings` como rascunho local e entrega o estado
uma única vez ao concluir ou pular. Resultado do orçamento automatizado: zero
callbacks durante dois gestos de slider e exatamente um callback final.

### Configurações idênticas

`SettingsProvider.update` compara o estado normalizado ao atual. Quando não há
mudança semântica, retorna antes de `notifyListeners` e da persistência. Teste:
zero notificações para update idêntico e uma para mudança real.

### DVRS

Foi adicionado um orçamento de montagem preguiçosa. Tanto no início quanto após
rolar até a pergunta 16, no máximo quatro cartões permanecem montados. A
recuperação da primeira pergunta ausente continua funcional.

## Verificação

- `rtk flutter analyze`: aprovado, zero ocorrências.
- `rtk flutter test`: aprovado, 249 testes.
- `rtk npm run build --prefix web/science`: aprovado; typecheck, client, SSR e
  prerender concluídos.
- `rtk node site/scripts/smoke-check.mjs`: aprovado.
- `rtk flutter test --dart-define=UI_UX_CAPTURE_STAGE=after
  tool/ui_ux_vnext_capture_test.dart`: aprovado em PT-BR e EN.
- `rtk dart run flutter_launcher_icons`: aprovado para macOS e Windows.
- `rtk flutter build macos --release -t lib/main.dart`: aprovado; app 59,4 MB.
- Executável macOS: Mach-O universal x86_64 e arm64.
- `rtk bash scripts/make_dmg.sh 1.24.2`: aprovado.
- `rtk hdiutil verify dist/DryEyeWidget.dmg`: checksum interno válido.
- Montagem read-only do DMG: contém `Dry Eye Widget.app`, atalho
  `Applications` e `Como abrir no macOS.txt`.
- SHA-256 do DMG:
  `e99ac90a31309837704904a93ee4f953f05a477f37e712b68df4f0997b38d4f5`.
- Bundle: 1.24.2, build 72, identificador
  `com.saraivavision.dryEyeWidget`, assinatura ad hoc.
- `rtk git diff --check`: aprovado.

## Limite Windows

`rtk flutter build windows --release` foi executado e o Flutter respondeu que o
target só é suportado em hosts Windows. O repositório mantém dois pipelines reais
em runner `windows-latest`:

- `.github/workflows/windows-build.yml`: análise, testes, release, ZIP e Inno
  Setup, com SignPath opcional;
- `.github/workflows/windows-msix.yml`: análise, testes, release e MSIX Store.

Metadados reconciliados: `pubspec.yaml` 1.24.2+72, `AppInfo.version` 1.24.2 e
`msix_version` 1.24.2.0. A geração dos artefatos Windows requer push/dispatch do
commit ou um host Windows; não foi simulada nem declarada como concluída.

## Avisos não bloqueantes

- 26 dependências têm versões mais novas fora das constraints atuais.
- `local_notifier` ainda não oferece suporte a Swift Package Manager no macOS.
- A geração de PDF mantém avisos conhecidos de cobertura Unicode da Helvetica.
