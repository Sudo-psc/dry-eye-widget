#!/bin/bash
# Empacota o app macOS em um .dmg de distribuição (arraste para Applications).
#
# Uso:
#   flutter build macos --release
#   ./scripts/make_dmg.sh [versão]
#
# Saída: dist/DryEyeWidget-<versão>.dmg
set -euo pipefail

VERSION="${1:-1.1.0}"
APP="build/macos/Build/Products/Release/Dry Eye Widget.app"
# Nome fixo do asset: mantém o link de download estável entre versões.
OUT="dist/DryEyeWidget.dmg"

if [ ! -d "$APP" ]; then
  echo "App não encontrado em $APP. Rode antes: flutter build macos --release" >&2
  exit 1
fi

mkdir -p dist
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT

cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

rm -f "$OUT"
hdiutil create \
  -volname "Dry Eye Widget" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$OUT"

echo "DMG gerado: $OUT"
shasum -a 256 "$OUT"
