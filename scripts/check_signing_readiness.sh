#!/usr/bin/env bash
# Verifica se o ambiente (local ou CI) tem o necessário para assinar builds.
# Não executa assinatura — só reporta readiness (melhoria M1 / ROADMAP #1).
set -euo pipefail

echo "== Dry Eye Widget — signing readiness =="
echo

ok=0
warn=0

check_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    echo "[ok]   $f"
  else
    echo "[MISS] $f"
    ok=1
  fi
}

check_file "scripts/macos_import_cert.sh"
check_file "scripts/macos_sign_and_notarize.sh"
check_file "scripts/make_dmg.sh"
check_file "docs/CODE_SIGNING.md"
check_file "win_version/CODE_SIGNING.md"
check_file ".github/workflows/macos-build.yml"
check_file ".github/workflows/windows-build.yml"

echo
echo "-- macOS secrets (present if non-empty in env) --"
for s in MACOS_CERTIFICATE_BASE64 MACOS_CERTIFICATE_PASSWORD; do
  if [[ -n "${!s:-}" ]]; then
    echo "[ok]   $s is set"
  else
    echo "[need] $s  (GitHub Secret)"
    warn=1
  fi
done

if [[ -n "${APPLE_API_KEY_BASE64:-}" || -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  echo "[ok]   notarization credentials present (API key or app password)"
else
  echo "[need] APPLE_API_KEY_* or APPLE_ID + APPLE_APP_SPECIFIC_PASSWORD"
  warn=1
fi

echo
echo "-- Windows SignPath --"
if [[ -n "${SIGNPATH_API_TOKEN:-}" ]]; then
  echo "[ok]   SIGNPATH_API_TOKEN is set"
else
  echo "[need] SIGNPATH_API_TOKEN (GitHub Secret) + SignPath org vars"
  warn=1
fi

echo
if [[ $ok -ne 0 ]]; then
  echo "RESULT: pipeline scripts incomplete (unexpected)."
  exit 2
fi
if [[ $warn -ne 0 ]]; then
  echo "RESULT: pipeline READY — credentials still missing (unsigned releases OK)."
  echo "See docs/CODE_SIGNING.md to activate paid signing."
  exit 0
fi
echo "RESULT: READY TO SIGN (credentials detected)."
exit 0
