#!/usr/bin/env bash

set -euo pipefail

fail() {
  echo "RELEASE_LATEST_RECONCILE_FAILED: $*" >&2
  exit 1
}

command -v gh >/dev/null || fail "gh CLI não encontrado"
command -v jq >/dev/null || fail "jq não encontrado"

semver_gt() {
  local left="${1#v}"
  local right="${2#v}"
  local left_major left_minor left_patch right_major right_minor right_patch
  IFS=. read -r left_major left_minor left_patch <<<"$left"
  IFS=. read -r right_major right_minor right_patch <<<"$right"
  ((10#$left_major > 10#$right_major)) ||
    { ((10#$left_major == 10#$right_major)) &&
      { ((10#$left_minor > 10#$right_minor)) ||
        { ((10#$left_minor == 10#$right_minor)) &&
          ((10#$left_patch > 10#$right_patch)); }; }; }
}

highest_published_semver() {
  local releases_json
  local candidate
  local highest=""
  releases_json="$(
    gh release list \
      --limit 1000 \
      --json tagName,isDraft,isPrerelease,publishedAt
  )"
  while IFS= read -r candidate; do
    [[ "$candidate" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
    if [[ -z "$highest" ]] || semver_gt "$candidate" "$highest"; then
      highest="$candidate"
    fi
  done < <(
    jq -r \
      '.[] |
       select(.isDraft == false and .isPrerelease == false) |
       select((.publishedAt // "") != "") |
       .tagName' \
      <<<"$releases_json"
  )
  printf '%s\n' "$highest"
}

for attempt in 1 2 3; do
  highest="$(highest_published_semver)"
  [[ -n "$highest" ]] || fail "nenhuma release SemVer publicada foi encontrada"

  current="$(
    gh release view --json tagName --jq .tagName 2>/dev/null || true
  )"
  if [[ "$current" != "$highest" ]]; then
    echo "Reconciliando latest para a maior SemVer publicada: $highest"
    gh release edit "$highest" --latest
  fi

  verified_highest="$(highest_published_semver)"
  verified_latest="$(
    gh release view --json tagName --jq .tagName 2>/dev/null || true
  )"
  if [[ "$verified_latest" == "$verified_highest" &&
    "$verified_highest" == "$highest" ]]; then
    echo "Latest reconciliada: $verified_latest"
    exit 0
  fi

  echo "Latest mudou durante a reconciliação; repetindo ($attempt/3)."
done

fail "latest não convergiu para a maior SemVer publicada após três tentativas"
