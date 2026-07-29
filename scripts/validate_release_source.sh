#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  echo "RELEASE_SOURCE_UNTRUSTED: $*" >&2
  exit 1
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Uso: $0 source-sha [--tag-only]" >&2
  exit 64
fi

source_sha="${1,,}"
output_mode="${2:-validate}"
default_branch="${RELEASE_DEFAULT_BRANCH:-main}"

[[ "$source_sha" =~ ^[0-9a-f]{40}$ ]] ||
  fail "source SHA inválido: $source_sha"
[[ "$output_mode" == "validate" || "$output_mode" == "--tag-only" ]] || {
  echo "Uso: $0 source-sha [--tag-only]" >&2
  exit 64
}
[[ "$default_branch" =~ ^[A-Za-z0-9._/-]+$ ]] ||
  fail "default branch inválida: $default_branch"

command -v git >/dev/null || fail "git não encontrado"

git fetch --quiet --force --no-tags origin \
  "+refs/heads/$default_branch:refs/remotes/origin/$default_branch"
git fetch --quiet --force origin \
  "+refs/tags/v*:refs/tags/v*"

git cat-file -e "$source_sha^{commit}" 2>/dev/null ||
  fail "source SHA não existe como commit no repositório"
git merge-base --is-ancestor "$source_sha" "origin/$default_branch" ||
  fail "$source_sha não é ancestral de origin/$default_branch"

tags="$(
  git tag --points-at "$source_sha" |
    grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' || true
)"
tag_count="$(grep -c . <<<"$tags" || true)"
[[ "$tag_count" -eq 1 ]] ||
  fail "esperada exatamente uma tag SemVer no source SHA; encontradas: $tag_count"
tag="$tags"
[[ "$(git cat-file -t "refs/tags/$tag")" == "tag" ]] ||
  fail "$tag deve ser uma tag anotada"
[[ "$(git rev-list -n 1 "$tag")" == "$source_sha" ]] ||
  fail "$tag não resolve para $source_sha"

read_source() {
  git show "$source_sha:$1" 2>/dev/null ||
    fail "arquivo obrigatório ausente no source: $1"
}

pubspec="$(read_source pubspec.yaml)"
version="$(
  sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' \
    <<<"$pubspec" | head -1
)"
[[ -n "$version" ]] || fail "versão ausente em pubspec.yaml"
[[ "$tag" == "v$version" ]] ||
  fail "tag $tag não corresponde à versão $version"
grep -Eq \
  "^[[:space:]]*msix_version:[[:space:]]*$version\\.0[[:space:]]*$" \
  <<<"$pubspec" ||
  fail "msix_version não corresponde a $version"

require_source_match() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  grep -Eq "$pattern" <<<"$(read_source "$file")" ||
    fail "$label não está sincronizado com $version em $file"
}

require_source_match \
  lib/utils/constants.dart \
  "static const String version = '$version';" \
  "AppInfo.version"
require_source_match \
  site/index.html \
  "\"softwareVersion\":[[:space:]]*\"$version\"" \
  "softwareVersion"
require_source_match \
  site/index.html \
  "id=\"app-version\">[[:space:]]*$version<" \
  "badge da landing"
require_source_match README.md "Versão $version" "README"
require_source_match README.md "^## Recursos \\($version\\)$" "seção de recursos"
require_source_match README.md "Interface atual v$version" "legenda de interface"
require_source_match README.en.md "Version $version" "README em inglês"
require_source_match README.en.md "^## Features \\($version\\)$" "features em inglês"
require_source_match README.en.md "Current v$version interface" "interface em inglês"
require_source_match site/README.md "Recursos $version:" "README da landing"
require_source_match CHANGELOG.md "^## \\[$version\\]" "CHANGELOG"
require_source_match \
  site/scripts/i18n.js \
  "\"faq\\.6\\.q\":.*$version" \
  "FAQ de versão da landing"

if [[ "$output_mode" == "--tag-only" ]]; then
  printf '%s\n' "$tag"
else
  echo "source: ready ($tag, $source_sha ancestral de origin/$default_branch)"
fi
