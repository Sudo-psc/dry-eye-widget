# i18n ARB (migração gradual)

Base ARB para `flutter gen-l10n` (melhoria 1.23 / ROADMAP #8).

**Estado atual:** o app ainda usa `lib/l10n/app_strings.dart` +
`feature_strings.dart` em runtime. Os arquivos `.arb` deste diretório
documentam as strings novas e servem de ponto de partida para a migração.

## Ativar gen-l10n (quando for a hora)

1. Em `pubspec.yaml`:

```yaml
flutter:
  generate: true
```

2. Criar `l10n.yaml` na raiz:

```yaml
arb-dir: lib/l10n/arb
template-arb-file: app_pt.arb
output-localization-file: app_localizations.dart
```

3. `flutter gen-l10n` e ir substituindo `AppStrings` / `FeatureStrings`.

Até lá, **não** habilite `generate: true` sem migrar o `MaterialApp`.
