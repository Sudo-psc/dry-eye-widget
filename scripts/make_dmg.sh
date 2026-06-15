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

# Guia de instalação (Gatekeeper): o app não é notarizado, então o macOS pode
# acusar o .dmg como "danificado". Inclui as instruções visíveis no volume.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
README_SRC="$SCRIPT_DIR/dmg/leia-me-macos.txt"
if [ -f "$README_SRC" ]; then
  cp "$README_SRC" "$STAGING/Como abrir no macOS.txt"
else
  echo "Aviso: guia de instalação não encontrado em $README_SRC" >&2
fi

rm -f "$OUT"
hdiutil create \
  -volname "Dry Eye Widget" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$OUT"

echo "DMG gerado: $OUT"
shasum -a 256 "$OUT"
