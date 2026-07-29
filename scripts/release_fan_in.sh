#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  echo "RELEASE_FAN_IN_FAILED: $*" >&2
  exit 1
}

if [[ $# -ne 2 ]]; then
  echo "Uso: $0 source-sha diretório-de-saída" >&2
  exit 64
fi

source_sha="$1"
bundle_dir="$2"
repo="${GITHUB_REPOSITORY:-}"
[[ "$source_sha" =~ ^[0-9a-fA-F]{40}$ ]] ||
  fail "source SHA inválido: $source_sha"
[[ -n "$repo" ]] || fail "GITHUB_REPOSITORY não definido"
command -v gh >/dev/null || fail "gh CLI não encontrado"
command -v jq >/dev/null || fail "jq não encontrado"

tag="$(bash scripts/validate_release_source.sh "$source_sha" --tag-only)"

find_successful_run() {
  local workflow="$1"
  local response
  response="$(
    gh api -X GET \
      "repos/$repo/actions/workflows/$workflow/runs" \
      -f event=push \
      -f status=completed \
      -f head_sha="$source_sha" \
      -F per_page=100
  )"
  jq -r \
    --arg sha "${source_sha,,}" \
    '
      [
        .workflow_runs[]
        | select(
            (.head_sha | ascii_downcase) == $sha and
            .event == "push" and
            .conclusion == "success"
          )
      ]
      | sort_by(.run_number, .run_attempt, .id)
      | last
      | .id // empty
    ' <<<"$response"
}

macos_run="$(find_successful_run macos-build.yml)"
windows_run="$(find_successful_run windows-build.yml)"
msix_run="$(find_successful_run windows-msix.yml)"

if [[ -z "$macos_run" || -z "$windows_run" || -z "$msix_run" ]]; then
  echo "release fan-in: pending ($tag)"
  echo "macOS=${macos_run:-pending} Windows=${windows_run:-pending} MSIX=${msix_run:-pending}"
  if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
      echo "## Release fan-in pendente"
      echo
      echo "A tag \`$tag\` ainda não possui três builds bem-sucedidos para \`$source_sha\`."
      echo
      echo "| Plataforma | Run |"
      echo "|------------|-----|"
      echo "| macOS | \`${macos_run:-pending}\` |"
      echo "| Windows | \`${windows_run:-pending}\` |"
      echo "| Windows MSIX | \`${msix_run:-pending}\` |"
    } >>"$GITHUB_STEP_SUMMARY"
  fi
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      echo "ready=false"
      echo "tag=$tag"
      echo "source_sha=$source_sha"
    } >>"$GITHUB_OUTPUT"
  fi
  exit 0
fi

work_root="$(mktemp -d "${RUNNER_TEMP:-/tmp}/dry-eye-release-fan-in.XXXXXX")"
trap 'rm -rf "$work_root"' EXIT
mkdir -p "$bundle_dir"
[[ -z "$(find "$bundle_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]] ||
  fail "diretório de saída deve estar vazio: $bundle_dir"

download_artifact() {
  local run_id="$1"
  local artifact_name="$2"
  local target_dir="$3"
  mkdir -p "$target_dir"
  gh run download "$run_id" \
    --repo "$repo" \
    --name "$artifact_name" \
    --dir "$target_dir"
}

download_artifact "$macos_run" dry-eye-widget-macos "$work_root/macos"
download_artifact "$windows_run" dry-eye-widget-windows "$work_root/windows"
download_artifact "$msix_run" dry-eye-widget-msix "$work_root/msix"

copy_unique() {
  local source_dir="$1"
  local name="$2"
  local matches
  matches="$(find "$source_dir" -type f -name "$name" -print)"
  [[ "$(grep -c . <<<"$matches" || true)" -eq 1 ]] ||
    fail "esperado um único $name em $source_dir"
  install -m 0644 "$matches" "$bundle_dir/$name"
}

copy_unique "$work_root/macos" DryEyeWidget.dmg
copy_unique "$work_root/macos" release-manifest-macos.json
copy_unique "$work_root/windows" DryEyeWidget-Setup-x64.exe
copy_unique "$work_root/windows" DryEyeWidget-windows-x64.zip
copy_unique "$work_root/windows" release-manifest-windows.json
copy_unique "$work_root/msix" dry_eye_widget.msix
copy_unique "$work_root/msix" release-manifest-msix.json

bash scripts/validate_release_bundle.sh "$tag" "$source_sha" "$bundle_dir"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "ready=true"
    echo "tag=$tag"
    echo "source_sha=$source_sha"
  } >>"$GITHUB_OUTPUT"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## Release fan-in validado"
    echo
    echo "| Plataforma | Run |"
    echo "|------------|-----|"
    echo "| macOS | \`$macos_run\` |"
    echo "| Windows | \`$windows_run\` |"
    echo "| Windows MSIX | \`$msix_run\` |"
    echo
    echo "Quatro artefatos preparados e reconciliados por tamanho e SHA-256 para \`$tag\`."
  } >>"$GITHUB_STEP_SUMMARY"
fi
