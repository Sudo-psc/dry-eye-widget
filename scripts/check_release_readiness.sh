#!/usr/bin/env bash

set -euo pipefail

repo_root="${RELEASE_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$repo_root"

mode="metadata"
tag=""

usage() {
  echo "Uso: $0 [--metadata | --tag vX.Y.Z | --published]" >&2
}

fail() {
  echo "RELEASE_NOT_READY: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --metadata)
      mode="metadata"
      shift
      ;;
    --tag)
      [[ $# -ge 2 ]] || {
        usage
        exit 64
      }
      mode="tag"
      tag="$2"
      shift 2
      ;;
    --published)
      mode="published"
      if [[ $# -ge 2 && "$2" != --* ]]; then
        tag="$2"
        shift 2
      else
        shift
      fi
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 64
      ;;
  esac
done

version="$(
  sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' \
    pubspec.yaml | head -1
)"
[[ -n "$version" ]] || fail "não foi possível ler a versão do pubspec.yaml"

require_match() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! grep -Eq "$pattern" "$file"; then
    fail "$label não está sincronizado com $version em $file"
  fi
}

require_match \
  pubspec.yaml \
  "^[[:space:]]*msix_version:[[:space:]]*$version\\.0[[:space:]]*$" \
  "msix_version"
require_match \
  lib/utils/constants.dart \
  "static const String version = '$version';" \
  "AppInfo.version"
require_match \
  site/index.html \
  "\"softwareVersion\":[[:space:]]*\"$version\"" \
  "softwareVersion"
require_match \
  site/index.html \
  "id=\"app-version\">[[:space:]]*$version<" \
  "badge da landing"
require_match README.md "Versão $version" "README"
require_match README.md "^## Recursos \\($version\\)$" "seção de recursos do README"
require_match README.md "Interface atual v$version" "legenda de interface do README"
require_match README.en.md "Version $version" "README em inglês"
require_match README.en.md "^## Features \\($version\\)$" "features do README em inglês"
require_match README.en.md "Current v$version interface" "legenda do README em inglês"
require_match site/README.md "Recursos $version:" "README da landing"
require_match CHANGELOG.md "^## \\[$version\\]" "CHANGELOG"
require_match \
  site/scripts/i18n.js \
  "\"faq\\.6\\.q\":.*$version" \
  "FAQ de versão da landing"

echo "metadata: ready ($version)"

if [[ "$mode" == "tag" ]]; then
  [[ "$tag" == "v$version" ]] ||
    fail "tag $tag não corresponde à versão $version"

  git rev-parse --verify --quiet "refs/tags/$tag" >/dev/null ||
    fail "tag local $tag não existe"

  tag_commit="$(git rev-list -n 1 "$tag")"
  head_commit="$(git rev-parse HEAD)"
  [[ "$tag_commit" == "$head_commit" ]] ||
    fail "tag $tag aponta para $tag_commit, mas HEAD é $head_commit"

  remote_main="$(
    git ls-remote origin refs/heads/main | awk 'NR == 1 {print $1}'
  )"
  [[ -n "$remote_main" ]] ||
    fail "não foi possível resolver origin/main"
  [[ "$tag_commit" == "$remote_main" ]] ||
    fail "tag $tag aponta para $tag_commit, mas origin/main é $remote_main"

  echo "tag: ready ($tag em $head_commit, igual a origin/main)"
fi

if [[ "$mode" == "published" ]]; then
  command -v gh >/dev/null ||
    fail "gh CLI é necessário para conferir a release pública"
  command -v jq >/dev/null ||
    fail "jq é necessário para conferir a release pública"

  release_tag="${tag:-v$version}"
  release_json="$(
    gh release view "$release_tag" \
      --json tagName,isDraft,isPrerelease,publishedAt,assets 2>/dev/null
  )" || fail "release pública $release_tag não existe"
  published_tag="$(jq -r '.tagName' <<<"$release_json")"
  [[ "$published_tag" == "$release_tag" ]] ||
    fail "release pública retornou tag inesperada: $published_tag"
  [[ "$(jq -r '.isDraft' <<<"$release_json")" == "false" ]] ||
    fail "release $release_tag ainda está em rascunho"
  [[ "$(jq -r '.isPrerelease' <<<"$release_json")" == "false" ]] ||
    fail "release $release_tag está marcada como pré-release"
  [[ "$(jq -r '.publishedAt // empty' <<<"$release_json")" != "" ]] ||
    fail "release $release_tag não possui data de publicação"

  assets="$(jq -r '.assets[].name' <<<"$release_json")"
  [[ "$(jq '.assets | length' <<<"$release_json")" -eq 4 ]] ||
    fail "release $release_tag deve conter exatamente quatro artefatos"
  for required in \
    DryEyeWidget.dmg \
    DryEyeWidget-Setup-x64.exe \
    DryEyeWidget-windows-x64.zip \
    dry_eye_widget.msix; do
    grep -Fxq "$required" <<<"$assets" ||
      fail "release $release_tag não contém $required"
    [[ "$(
      jq --arg name "$required" \
        '[.assets[] | select(.name == $name) | .size] | first // 0' \
        <<<"$release_json"
    )" -gt 0 ]] ||
      fail "artefato $required está vazio"
  done

  echo "published: ready ($release_tag com quatro artefatos)"
fi
