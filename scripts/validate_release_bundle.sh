#!/usr/bin/env bash

set -euo pipefail

fail() {
  echo "RELEASE_BUNDLE_INVALID: $*" >&2
  exit 1
}

if [[ $# -ne 3 ]]; then
  echo "Uso: $0 vX.Y.Z source-sha diretório-dos-artefatos" >&2
  exit 64
fi

tag="$1"
source_sha="$2"
artifact_dir="$3"
version="${tag#v}"

[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  fail "tag inválida: $tag"
[[ "$source_sha" =~ ^[0-9a-fA-F]{40}$ ]] ||
  fail "source SHA inválido: $source_sha"
[[ -d "$artifact_dir" ]] ||
  fail "diretório inexistente: $artifact_dir"
command -v jq >/dev/null || fail "jq não encontrado"

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

expected_files="$(
  printf '%s\n' "${required_assets[@]}" "${required_manifests[@]}" |
    LC_ALL=C sort
)"
actual_files="$(
  find "$artifact_dir" -maxdepth 1 -type f -exec basename {} \; |
    LC_ALL=C sort
)"
[[ "$actual_files" == "$expected_files" ]] ||
  fail "o bundle deve conter somente os quatro artefatos e três manifestos esperados"

for file in "${required_assets[@]}" "${required_manifests[@]}"; do
  [[ -s "$artifact_dir/$file" ]] ||
    fail "arquivo ausente ou vazio: $artifact_dir/$file"
done

manifest_paths=()
for manifest in "${required_manifests[@]}"; do
  manifest_paths+=("$artifact_dir/$manifest")
done
manifest_json="$(jq -s '.' "${manifest_paths[@]}")" ||
  fail "não foi possível ler os manifestos"

jq -e \
  --arg tag "$tag" \
  --arg sourceSha "${source_sha,,}" \
  --arg version "$version" \
  '
    length == 3 and
    (map(.platform) | sort) == ["macos", "windows", "windows-msix"] and
    all(.[];
      .schemaVersion == 1 and
      .tag == $tag and
      (.sourceSha | ascii_downcase) == $sourceSha and
      .version == $version and
      (.files | type == "array") and
      all(.files[];
        (.name | type == "string") and
        (.size | type == "number") and
        .size > 0 and
        (.sha256 | test("^[0-9a-f]{64}$"))
      )
    ) and
    ([.[].files[]] | length) == 4 and
    ([.[].files[].name] | sort) == [
      "DryEyeWidget-Setup-x64.exe",
      "DryEyeWidget-windows-x64.zip",
      "DryEyeWidget.dmg",
      "dry_eye_widget.msix"
    ]
  ' <<<"$manifest_json" >/dev/null ||
  fail "manifestos não correspondem à mesma tag, versão, source SHA e contrato"

sha256_file() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

for asset in "${required_assets[@]}"; do
  record_count="$(
    jq --arg name "$asset" \
      '[.[].files[] | select(.name == $name)] | length' \
      <<<"$manifest_json"
  )"
  [[ "$record_count" -eq 1 ]] ||
    fail "$asset deve aparecer exatamente uma vez nos manifestos"

  expected_size="$(
    jq -r --arg name "$asset" \
      '[.[].files[] | select(.name == $name) | .size] | first' \
      <<<"$manifest_json"
  )"
  expected_sha="$(
    jq -r --arg name "$asset" \
      '[.[].files[] | select(.name == $name) | .sha256] | first' \
      <<<"$manifest_json"
  )"
  actual_size="$(wc -c <"$artifact_dir/$asset" | tr -d '[:space:]')"
  actual_sha="$(sha256_file "$artifact_dir/$asset")"
  [[ "$actual_size" == "$expected_size" ]] ||
    fail "tamanho de $asset diverge do manifesto"
  [[ "$actual_sha" == "$expected_sha" ]] ||
    fail "SHA-256 de $asset diverge do manifesto"
done

echo "release bundle: ready ($tag, $source_sha, 4 artefatos, 3 manifestos)"
