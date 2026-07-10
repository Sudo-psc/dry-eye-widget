#!/usr/bin/env bash
# Assina o .app (Developer ID + hardened runtime), reempacota o .dmg e
# opcionalmente notariza com notarytool.
#
# Pré-requisito: flutter build macos --release
#                e (no CI) scripts/macos_import_cert.sh
#
# Variáveis:
#   MACOS_IDENTITY              — "Developer ID Application: Nome (TEAMID)"
#   MACOS_SIGNING_ENABLED=true  — se não true, só imprime status e sai 0
#   APP_PATH                    — default: build/macos/Build/Products/Release/Dry Eye Widget.app
#   ENTITLEMENTS                — default: macos/Runner/Release.entitlements
#
# Notarização (opcional — qualquer um dos dois métodos):
#   A) App-specific password:
#        APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD
#   B) API Key:
#        APPLE_API_KEY_PATH (arquivo .p8), APPLE_API_KEY_ID, APPLE_API_ISSUER
#
# Uso:
#   ./scripts/macos_sign_and_notarize.sh [versão]
set -euo pipefail

VERSION="${1:-}"
APP_PATH="${APP_PATH:-build/macos/Build/Products/Release/Dry Eye Widget.app}"
ENTITLEMENTS="${ENTITLEMENTS:-macos/Runner/Release.entitlements}"
OUT_DMG="${OUT_DMG:-dist/DryEyeWidget.dmg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if [[ "${MACOS_SIGNING_ENABLED:-}" != "true" ]]; then
  echo "MACOS_SIGNING_ENABLED!=true — build sem assinatura Developer ID."
  echo "status=unsigned" >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "### macOS signing" >> "$GITHUB_STEP_SUMMARY"
    echo "Não configurado (secrets ausentes). DMG segue sem notarização." >> "$GITHUB_STEP_SUMMARY"
  fi
  exit 0
fi

if [[ -z "${MACOS_IDENTITY:-}" ]]; then
  echo "MACOS_IDENTITY é obrigatório quando a assinatura está habilitada." >&2
  exit 1
fi
if [[ ! -d "$APP_PATH" ]]; then
  echo "App não encontrado: $APP_PATH" >&2
  exit 1
fi
if [[ ! -f "$ENTITLEMENTS" ]]; then
  echo "Entitlements não encontrados: $ENTITLEMENTS" >&2
  exit 1
fi

echo "==> codesign --deep (hardened runtime)"
# Assina frameworks/dylibs de dentro para fora, depois o .app.
find "$APP_PATH/Contents" -type f \( -name "*.dylib" -o -name "*.so" -o -perm -111 \) 2>/dev/null \
  | while read -r bin; do
      # Pula scripts e stubs sem macho
      file "$bin" | grep -q 'Mach-O' || continue
      codesign --force --options runtime --timestamp \
        --sign "$MACOS_IDENTITY" "$bin" 2>/dev/null || true
    done

# Frameworks e helpers
find "$APP_PATH/Contents" -type d \( -name "*.framework" -o -name "*.app" \) 2>/dev/null \
  | sort -r \
  | while read -r bundle; do
      codesign --force --options runtime --timestamp \
        --sign "$MACOS_IDENTITY" \
        --entitlements "$ENTITLEMENTS" \
        "$bundle" 2>/dev/null || \
      codesign --force --options runtime --timestamp \
        --sign "$MACOS_IDENTITY" "$bundle" 2>/dev/null || true
    done

codesign --force --deep --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$MACOS_IDENTITY" \
  "$APP_PATH"

echo "==> Verificar assinatura do .app"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
spctl --assess --type execute --verbose=4 "$APP_PATH" 2>&1 || {
  echo "Aviso: spctl assess falhou antes da notarização (esperado). Continuando."
}

echo "==> Gerar DMG assinado"
if [[ -n "$VERSION" ]]; then
  "$SCRIPT_DIR/make_dmg.sh" "$VERSION"
else
  "$SCRIPT_DIR/make_dmg.sh"
fi

echo "==> Assinar o .dmg"
codesign --force --timestamp --sign "$MACOS_IDENTITY" "$OUT_DMG"
codesign --verify --verbose=2 "$OUT_DMG"

NOTARIZE=false
if [[ -n "${APPLE_API_KEY_PATH:-}" && -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER:-}" ]]; then
  NOTARIZE=true
  NOTARY_ARGS=(--key "$APPLE_API_KEY_PATH" --key-id "$APPLE_API_KEY_ID" --issuer "$APPLE_API_ISSUER")
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  NOTARIZE=true
  NOTARY_ARGS=(--apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_SPECIFIC_PASSWORD")
fi

if [[ "$NOTARIZE" == "true" ]]; then
  echo "==> Enviar para notarização (notarytool)"
  xcrun notarytool submit "$OUT_DMG" \
    "${NOTARY_ARGS[@]}" \
    --wait \
    --timeout 30m

  echo "==> Staple + validar"
  xcrun stapler staple "$OUT_DMG"
  xcrun stapler validate "$OUT_DMG"
  spctl --assess --type open --context context:primary-signature --verbose=4 "$OUT_DMG" || true

  STATUS="signed+notarized"
else
  echo "Credenciais de notarização ausentes — app assinado, DMG assinado, sem notarização."
  STATUS="signed"
fi

echo "status=$STATUS"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "status=$STATUS" >> "$GITHUB_OUTPUT"
fi
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### macOS signing"
    echo "- Identity: \`$MACOS_IDENTITY\`"
    echo "- Resultado: **$STATUS**"
    echo "- DMG: \`$OUT_DMG\`"
  } >> "$GITHUB_STEP_SUMMARY"
fi

echo "macOS signing concluído: $STATUS"
