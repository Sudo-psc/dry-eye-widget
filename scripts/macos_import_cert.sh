#!/usr/bin/env bash
# Importa certificado Developer ID Application no keychain temporário do CI.
#
# Variáveis obrigatórias:
#   MACOS_CERTIFICATE_BASE64  — .p12 em base64
#   MACOS_CERTIFICATE_PASSWORD
#
# Opcionais:
#   KEYCHAIN_PASSWORD  — senha do keychain temporário (default: gerada)
#   KEYCHAIN_PATH      — default: $RUNNER_TEMP/build.keychain-db
#
# Saídas (GITHUB_ENV se disponível):
#   KEYCHAIN_PATH, MACOS_IDENTITY (se detectada)
set -euo pipefail

if [[ -z "${MACOS_CERTIFICATE_BASE64:-}" ]]; then
  echo "MACOS_CERTIFICATE_BASE64 ausente — pulando import."
  exit 0
fi
if [[ -z "${MACOS_CERTIFICATE_PASSWORD:-}" ]]; then
  echo "MACOS_CERTIFICATE_PASSWORD é obrigatório quando o certificado está presente." >&2
  exit 1
fi

KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(openssl rand -base64 24)}"
KEYCHAIN_PATH="${KEYCHAIN_PATH:-${RUNNER_TEMP:-/tmp}/build.keychain-db}"
CERT_PATH="${RUNNER_TEMP:-/tmp}/developer_id.p12"

echo "$MACOS_CERTIFICATE_BASE64" | base64 --decode > "$CERT_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

security import "$CERT_PATH" \
  -P "$MACOS_CERTIFICATE_PASSWORD" \
  -A \
  -t cert \
  -f pkcs12 \
  -k "$KEYCHAIN_PATH"

security list-keychain -d user -s "$KEYCHAIN_PATH" $(security list-keychain -d user | tr -d '"')
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

# Detecta identidade Developer ID Application se não fornecida.
if [[ -z "${MACOS_IDENTITY:-}" ]]; then
  MACOS_IDENTITY="$(
    security find-identity -v -p codesigning "$KEYCHAIN_PATH" \
      | grep -E 'Developer ID Application' \
      | head -1 \
      | sed -E 's/.*"([^"]+)".*/\1/' || true
  )"
fi

if [[ -z "${MACOS_IDENTITY:-}" ]]; then
  echo "Nenhuma identidade 'Developer ID Application' encontrada no keychain." >&2
  security find-identity -v -p codesigning "$KEYCHAIN_PATH" || true
  exit 1
fi

echo "Identidade de assinatura: $MACOS_IDENTITY"
rm -f "$CERT_PATH"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  {
    echo "KEYCHAIN_PATH=$KEYCHAIN_PATH"
    echo "KEYCHAIN_PASSWORD=$KEYCHAIN_PASSWORD"
    echo "MACOS_IDENTITY=$MACOS_IDENTITY"
    echo "MACOS_SIGNING_ENABLED=true"
  } >> "$GITHUB_ENV"
fi

echo "Certificado importado em $KEYCHAIN_PATH"
