#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  echo "RELEASE_PUBLISH_FAILED: $*" >&2
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Uso: $0 vX.Y.Z [diretório-dos-artefatos]" >&2
  exit 64
fi

tag="$1"
artifact_dir="${2:-dist/release}"
required_assets=(
  DryEyeWidget.dmg
  DryEyeWidget-Setup-x64.exe
  DryEyeWidget-windows-x64.zip
  dry_eye_widget.msix
)
required_manifests=(
  release-manifest-macos.json
  release-manifest-windows.json
  release-manifest-msix.json
)

sha256_file() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

canonical_bundle_digest() {
  local name
  {
    for name in "${required_assets[@]}" "${required_manifests[@]}"; do
      printf '%s\n' "$name"
    done
  } | LC_ALL=C sort | while IFS= read -r name; do
    printf '%s  %s\n' "$(sha256_file "$artifact_dir/$name")" "$name"
  done | if command -v sha256sum >/dev/null; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

command -v gh >/dev/null || fail "gh CLI não encontrado"
command -v jq >/dev/null || fail "jq não encontrado"

tag_commit="$(git rev-list -n 1 "$tag")"
[[ -n "$tag_commit" ]] || fail "tag local não encontrada: $tag"

# Tudo até a aprovação é estritamente local. O marcador humano fica vinculado
# tanto ao source quanto aos bytes exatos dos quatro artefatos e três manifests.
bash scripts/validate_release_bundle.sh "$tag" "$tag_commit" "$artifact_dir"
bundle_digest="$(canonical_bundle_digest)"
expected_approval="publish:$tag@$tag_commit#$bundle_digest"
[[ "${RELEASE_MANUAL_APPROVAL:-}" == "$expected_approval" ]] ||
  fail "publicação manual exige aprovação explícita do snapshot: export RELEASE_MANUAL_APPROVAL='$expected_approval'"

remote_tag="$(
  git ls-remote origin "refs/tags/$tag^{}" | awk 'NR == 1 {print $1}'
)"
[[ -n "$remote_tag" ]] || fail "tag anotada $tag não está publicada em origin"
[[ "$remote_tag" == "$tag_commit" ]] ||
  fail "a tag remota $tag aponta para um commit inesperado"

bash scripts/validate_release_source.sh "$tag_commit"

manifest_json="$(
  jq -s '.' \
    "$artifact_dir/release-manifest-macos.json" \
    "$artifact_dir/release-manifest-windows.json" \
    "$artifact_dir/release-manifest-msix.json"
)"

release_assets=()
for asset in "${required_assets[@]}"; do
  release_assets+=("$artifact_dir/$asset")
done

validate_remote_assets() {
  local release_json="$1"
  [[ "$(jq '.assets | length' <<<"$release_json")" -eq 4 ]] ||
    fail "a release não contém exatamente quatro artefatos"

  for asset in "${required_assets[@]}"; do
    local local_size
    local expected_sha
    local remote_size
    local remote_digest
    local_size="$(wc -c <"$artifact_dir/$asset" | tr -d '[:space:]')"
    expected_sha="$(
      jq -r --arg name "$asset" \
        '[.[].files[] | select(.name == $name) | .sha256] | first' \
        <<<"$manifest_json"
    )"
    remote_size="$(
      jq --arg name "$asset" \
        '[.assets[] | select(.name == $name) | .size] | first // 0' \
        <<<"$release_json"
    )"
    remote_digest="$(
      jq -r --arg name "$asset" \
        '[.assets[] | select(.name == $name) | .digest] | first // empty' \
        <<<"$release_json"
    )"
    [[ "$remote_size" -eq "$local_size" ]] ||
      fail "tamanho remoto de $asset diverge do artefato validado"
    [[ "$remote_digest" == "sha256:$expected_sha" ]] ||
      fail "digest remoto de $asset diverge do manifesto"
  done
}

is_required_asset() {
  local candidate="$1"
  local required
  for required in "${required_assets[@]}"; do
    [[ "$candidate" == "$required" ]] && return 0
  done
  return 1
}

clean_draft_extras() {
  local release_json="$1"
  local asset
  [[ "$(jq -r '.isDraft' <<<"$release_json")" == "true" ]] ||
    fail "recuperação de assets extras só é permitida em rascunho"
  while IFS= read -r asset; do
    [[ -n "$asset" ]] || continue
    if ! is_required_asset "$asset"; then
      echo "Removendo asset extra do rascunho: $asset"
      gh release delete-asset "$tag" "$asset" --yes
    fi
  done < <(jq -r '.assets[].name' <<<"$release_json")
}

existing_json=""
if existing_json="$(
  gh release view "$tag" \
    --json tagName,isDraft,isPrerelease,publishedAt,assets 2>/dev/null
)"; then
  if [[ "$(jq -r '.isDraft' <<<"$existing_json")" == "false" ]]; then
    [[ "$(jq -r '.isPrerelease' <<<"$existing_json")" == "false" ]] ||
      fail "a release publicada $tag está marcada como pré-release"
    validate_remote_assets "$existing_json"
    bash scripts/check_release_readiness.sh --published "$tag"
    bash scripts/reconcile_release_latest.sh
    echo "Release $tag já publicada e idêntica aos manifests; nada a fazer."
    exit 0
  fi
  echo "Retomando o rascunho recuperável de $tag..."
else
  echo "Criando rascunho recuperável de $tag..."
  if ! gh release create "$tag" \
    --draft \
    --generate-notes \
    --title "Dry Eye Widget $tag" \
    --verify-tag; then
    existing_json="$(
      gh release view "$tag" \
        --json tagName,isDraft,isPrerelease,publishedAt,assets 2>/dev/null
    )" || fail "não foi possível criar nem retomar a release $tag"
    [[ "$(jq -r '.isDraft' <<<"$existing_json")" == "true" ]] ||
      fail "a release $tag surgiu publicada durante a criação; execute novamente para reconciliar"
  fi
fi

existing_json="$(
  gh release view "$tag" \
    --json tagName,isDraft,isPrerelease,publishedAt,assets
)"
[[ "$(jq -r '.tagName' <<<"$existing_json")" == "$tag" ]] ||
  fail "rascunho retornou tag inesperada"
clean_draft_extras "$existing_json"

echo "Reconciliando os quatro artefatos no rascunho..."
gh release upload "$tag" "${release_assets[@]}" --clobber

release_json="$(
  gh release view "$tag" \
    --json tagName,isDraft,isPrerelease,publishedAt,assets
)"
[[ "$(jq -r '.isDraft' <<<"$release_json")" == "true" ]] ||
  fail "a release validada não está em rascunho"
validate_remote_assets "$release_json"

echo "Rascunho validado; publicando release..."
gh release edit "$tag" --draft=false
bash scripts/reconcile_release_latest.sh
bash scripts/check_release_readiness.sh --published "$tag"
