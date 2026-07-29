#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

for script in \
  scripts/check_release_readiness.sh \
  scripts/validate_release_source.sh \
  scripts/validate_release_bundle.sh \
  scripts/publish_github_release.sh \
  scripts/reconcile_release_latest.sh \
  scripts/release_fan_in.sh; do
  bash -n "$script"
done

grep -Fq 'group: release-validation-${{ github.event.workflow_run.head_sha }}' \
  .github/workflows/release-fan-in.yml
grep -Fq 'ref: ${{ github.event.repository.default_branch }}' \
  .github/workflows/release-fan-in.yml
grep -Fq "contents: read" .github/workflows/release-fan-in.yml
grep -Fq "actions/upload-artifact@" .github/workflows/release-fan-in.yml
if grep -Eq 'contents:[[:space:]]*write|environment:[[:space:]]*release|publish_github_release|gh[[:space:]]+release|^[[:space:]]+publish:' \
  .github/workflows/release-fan-in.yml; then
  echo "release pipeline test failed: fan-in ainda possui fronteira privilegiada" >&2
  exit 1
fi
if grep -ERq 'contents:[[:space:]]*write|publish_github_release|gh[[:space:]]+release[[:space:]]+(create|upload|edit|delete)' \
  .github/workflows; then
  echo "release pipeline test failed: Actions ainda pode publicar GitHub Release" >&2
  exit 1
fi
if grep -Eq 'ref:.*workflow_run\.head_sha' \
  .github/workflows/release-fan-in.yml; then
  echo "release pipeline test failed: fan-in faz checkout do source não confiável" >&2
  exit 1
fi
if grep -Eq '\$\{\{[[:space:]]*secrets\.|SIGNPATH_API_TOKEN|MACOS_CERTIFICATE|APPLE_(ID|TEAM|API|APP)' \
  .github/workflows/macos-build.yml \
  .github/workflows/windows-build.yml \
  .github/workflows/windows-msix.yml; then
  echo "release pipeline test failed: workflow de tag ainda expõe secrets" >&2
  exit 1
fi

fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/dry-eye-release-test.XXXXXX")"
trap 'rm -rf "$fixture_root"' EXIT
bundle_dir="$fixture_root/release"
mkdir -p "$bundle_dir"

version="$(
  sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' \
    pubspec.yaml | head -1
)"
tag="v$version"
source_sha="0123456789abcdef0123456789abcdef01234567"

printf 'macOS fixture\n' >"$bundle_dir/DryEyeWidget.dmg"
printf 'Windows installer fixture\n' >"$bundle_dir/DryEyeWidget-Setup-x64.exe"
printf 'Windows portable fixture\n' >"$bundle_dir/DryEyeWidget-windows-x64.zip"
printf 'MSIX fixture\n' >"$bundle_dir/dry_eye_widget.msix"

sha256_file() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

canonical_bundle_digest_for() {
  local directory="$1"
  local name
  printf '%s\n' \
    DryEyeWidget.dmg \
    DryEyeWidget-Setup-x64.exe \
    DryEyeWidget-windows-x64.zip \
    dry_eye_widget.msix \
    release-manifest-macos.json \
    release-manifest-windows.json \
    release-manifest-msix.json |
    LC_ALL=C sort |
    while IFS= read -r name; do
      printf '%s  %s\n' "$(sha256_file "$directory/$name")" "$name"
    done |
    if command -v sha256sum >/dev/null; then
      sha256sum | awk '{print $1}'
    else
      shasum -a 256 | awk '{print $1}'
    fi
}

file_record() {
  local name="$1"
  local path="$bundle_dir/$name"
  jq -n \
    --arg name "$name" \
    --arg sha256 "$(sha256_file "$path")" \
    --argjson size "$(wc -c <"$path" | tr -d '[:space:]')" \
    '{name: $name, size: $size, sha256: $sha256}'
}

mac_record="$(file_record DryEyeWidget.dmg)"
windows_setup_record="$(file_record DryEyeWidget-Setup-x64.exe)"
windows_zip_record="$(file_record DryEyeWidget-windows-x64.zip)"
msix_record="$(file_record dry_eye_widget.msix)"

jq -n \
  --arg tag "$tag" \
  --arg sourceSha "$source_sha" \
  --arg version "$version" \
  --argjson file "$mac_record" \
  '{
    schemaVersion: 1,
    platform: "macos",
    tag: $tag,
    sourceSha: $sourceSha,
    version: $version,
    files: [$file]
  }' >"$bundle_dir/release-manifest-macos.json"

jq -n \
  --arg tag "$tag" \
  --arg sourceSha "$source_sha" \
  --arg version "$version" \
  --argjson setup "$windows_setup_record" \
  --argjson zip "$windows_zip_record" \
  '{
    schemaVersion: 1,
    platform: "windows",
    tag: $tag,
    sourceSha: $sourceSha,
    version: $version,
    files: [$zip, $setup]
  }' >"$bundle_dir/release-manifest-windows.json"

jq -n \
  --arg tag "$tag" \
  --arg sourceSha "$source_sha" \
  --arg version "$version" \
  --argjson file "$msix_record" \
  '{
    schemaVersion: 1,
    platform: "windows-msix",
    tag: $tag,
    sourceSha: $sourceSha,
    version: $version,
    files: [$file]
  }' >"$bundle_dir/release-manifest-msix.json"

bash scripts/validate_release_bundle.sh "$tag" "$source_sha" "$bundle_dir"

printf 'unrelated video fixture\n' \
  >"$bundle_dir/gemini_generated_video_B3916D35.mp4"
if bash scripts/validate_release_bundle.sh \
  "$tag" "$source_sha" "$bundle_dir" >/dev/null 2>&1; then
  echo "release pipeline test failed: arquivo extra não foi rejeitado" >&2
  exit 1
fi
rm "$bundle_dir/gemini_generated_video_B3916D35.mp4"

printf 'tamper\n' >>"$bundle_dir/DryEyeWidget.dmg"
if bash scripts/validate_release_bundle.sh \
  "$tag" "$source_sha" "$bundle_dir" >/dev/null 2>&1; then
  echo "release pipeline test failed: hash divergente não foi rejeitado" >&2
  exit 1
fi

# O gate de metadados deve rejeitar marcadores editoriais antigos mesmo quando
# a versão atual ainda aparece em outros pontos do arquivo.
metadata_root="$fixture_root/metadata"
mkdir -p \
  "$metadata_root/lib/utils" \
  "$metadata_root/site/scripts"
for file in \
  pubspec.yaml \
  README.md \
  README.en.md \
  site/README.md \
  site/index.html \
  site/scripts/i18n.js \
  CHANGELOG.md \
  lib/utils/constants.dart; do
  mkdir -p "$metadata_root/$(dirname "$file")"
  cp "$file" "$metadata_root/$file"
done
RELEASE_REPO_ROOT="$metadata_root" \
  bash scripts/check_release_readiness.sh --metadata >/dev/null
perl -pi -e 's/^## Recursos \(1\.26\.0\)$/## Recursos (1.23)/' \
  "$metadata_root/README.md"
if RELEASE_REPO_ROOT="$metadata_root" \
  bash scripts/check_release_readiness.sh --metadata >/dev/null 2>&1; then
  echo "release pipeline test failed: marcador editorial antigo foi aceito" >&2
  exit 1
fi

# O source de release deve ser uma tag anotada SemVer e ancestral da default
# branch. Uma tag em commit lateral não pode produzir um bundle validado.
source_repo="$fixture_root/source-repo"
source_remote="$fixture_root/source-remote.git"
mkdir -p \
  "$source_repo/scripts" \
  "$source_repo/lib/utils" \
  "$source_repo/site/scripts"
cp scripts/validate_release_source.sh "$source_repo/scripts/"
for file in \
  pubspec.yaml \
  README.md \
  README.en.md \
  site/README.md \
  site/index.html \
  site/scripts/i18n.js \
  CHANGELOG.md \
  lib/utils/constants.dart; do
  mkdir -p "$source_repo/$(dirname "$file")"
  cp "$file" "$source_repo/$file"
done
git -C "$source_repo" init -q
git -C "$source_repo" config user.name "Release Source Test"
git -C "$source_repo" config user.email "release-source@example.invalid"
git -C "$source_repo" add .
git -C "$source_repo" commit -qm "trusted release source"
git -C "$source_repo" branch -M main
trusted_source_sha="$(git -C "$source_repo" rev-parse HEAD)"
git -C "$source_repo" tag -a "$tag" -m "$tag"
git init --bare -q "$source_remote"
git -C "$source_repo" remote add origin "$source_remote"
git -C "$source_repo" push -q origin main "$tag"
(
  cd "$source_repo"
  bash scripts/validate_release_source.sh "$trusted_source_sha" >/dev/null
)

git -C "$source_repo" switch -q -c untrusted
printf 'untrusted side commit\n' >"$source_repo/untrusted.txt"
git -C "$source_repo" add untrusted.txt
git -C "$source_repo" commit -qm "untrusted side commit"
untrusted_source_sha="$(git -C "$source_repo" rev-parse HEAD)"
git -C "$source_repo" tag -a v9.9.9 -m v9.9.9
git -C "$source_repo" push -q origin v9.9.9
if (
  cd "$source_repo"
  bash scripts/validate_release_source.sh "$untrusted_source_sha" >/dev/null 2>&1
); then
  echo "release pipeline test failed: source fora de main foi aceito" >&2
  exit 1
fi
git -C "$source_repo" switch -q main

publisher_root="$fixture_root/publisher-repo"
remote_root="$fixture_root/publisher-remote.git"
publisher_bundle="$fixture_root/publisher-release"
mkdir -p "$publisher_root/scripts" "$publisher_bundle"
cp scripts/publish_github_release.sh "$publisher_root/scripts/"
cp scripts/reconcile_release_latest.sh "$publisher_root/scripts/"
cp scripts/validate_release_bundle.sh "$publisher_root/scripts/"
printf '#!/usr/bin/env bash\nexit 0\n' \
  >"$publisher_root/scripts/validate_release_source.sh"
printf '#!/usr/bin/env bash\nexit 0\n' \
  >"$publisher_root/scripts/check_release_readiness.sh"
chmod +x "$publisher_root/scripts/"*.sh

git -C "$publisher_root" init -q
git -C "$publisher_root" config user.name "Release Pipeline Test"
git -C "$publisher_root" config user.email "release-pipeline@example.invalid"
git -C "$publisher_root" add scripts
git -C "$publisher_root" commit -qm "test fixture"
git -C "$publisher_root" branch -M main
publisher_sha="$(git -C "$publisher_root" rev-parse HEAD)"
git -C "$publisher_root" tag -a "$tag" -m "$tag"
git init --bare -q "$remote_root"
git -C "$publisher_root" remote add origin "$remote_root"
git -C "$publisher_root" push -q origin main "$tag"

bundle_dir="$publisher_bundle"
printf 'macOS fixture\n' >"$bundle_dir/DryEyeWidget.dmg"
printf 'Windows installer fixture\n' >"$bundle_dir/DryEyeWidget-Setup-x64.exe"
printf 'Windows portable fixture\n' >"$bundle_dir/DryEyeWidget-windows-x64.zip"
printf 'MSIX fixture\n' >"$bundle_dir/dry_eye_widget.msix"

write_publisher_manifests() {
  mac_record="$(file_record DryEyeWidget.dmg)"
  windows_setup_record="$(file_record DryEyeWidget-Setup-x64.exe)"
  windows_zip_record="$(file_record DryEyeWidget-windows-x64.zip)"
  msix_record="$(file_record dry_eye_widget.msix)"

  jq -n \
    --arg tag "$tag" \
    --arg sourceSha "$publisher_sha" \
    --arg version "$version" \
    --argjson file "$mac_record" \
    '{
      schemaVersion: 1,
      platform: "macos",
      tag: $tag,
      sourceSha: $sourceSha,
      version: $version,
      files: [$file]
    }' >"$bundle_dir/release-manifest-macos.json"
  jq -n \
    --arg tag "$tag" \
    --arg sourceSha "$publisher_sha" \
    --arg version "$version" \
    --argjson setup "$windows_setup_record" \
    --argjson zip "$windows_zip_record" \
    '{
      schemaVersion: 1,
      platform: "windows",
      tag: $tag,
      sourceSha: $sourceSha,
      version: $version,
      files: [$zip, $setup]
    }' >"$bundle_dir/release-manifest-windows.json"
  jq -n \
    --arg tag "$tag" \
    --arg sourceSha "$publisher_sha" \
    --arg version "$version" \
    --argjson file "$msix_record" \
    '{
      schemaVersion: 1,
      platform: "windows-msix",
      tag: $tag,
      sourceSha: $sourceSha,
      version: $version,
      files: [$file]
    }' >"$bundle_dir/release-manifest-msix.json"
}

write_publisher_manifests
approved_bundle_digest="$(canonical_bundle_digest_for "$publisher_bundle")"
publisher_bundle_backup="$fixture_root/publisher-release-approved"
mkdir -p "$publisher_bundle_backup"
cp "$publisher_bundle"/* "$publisher_bundle_backup/"

fake_release_json="$fixture_root/published-release.json"
jq -n \
  --arg tag "$tag" \
  --argjson mac "$mac_record" \
  --argjson setup "$windows_setup_record" \
  --argjson zip "$windows_zip_record" \
  --argjson msix "$msix_record" \
  '{
    tagName: $tag,
    isDraft: false,
    isPrerelease: false,
    publishedAt: "2026-07-29T00:00:00Z",
    assets: [
      ($mac + {digest: ("sha256:" + $mac.sha256)}),
      ($setup + {digest: ("sha256:" + $setup.sha256)}),
      ($zip + {digest: ("sha256:" + $zip.sha256)}),
      ($msix + {digest: ("sha256:" + $msix.sha256)})
    ]
  }' >"$fake_release_json"

fake_gh_log="$fixture_root/fake-gh.log"
gh() {
  printf '%s\n' "$*" >>"$FAKE_GH_LOG"
  if [[ "$1 $2" == "release list" ]]; then
    jq -c \
      '[{
        tagName: .tagName,
        isDraft: .isDraft,
        isPrerelease: .isPrerelease,
        publishedAt: .publishedAt
      }]' \
      "$FAKE_RELEASE_JSON"
    return 0
  fi
  if [[ "$1 $2" == "release view" ]]; then
    if [[ "${3:-}" == "--json" ]]; then
      jq -r .tagName "$FAKE_RELEASE_JSON"
      return 0
    fi
    jq -c . "$FAKE_RELEASE_JSON"
    return 0
  fi
  echo "unexpected gh mutation in idempotency test: $*" >&2
  return 1
}
export -f gh
export FAKE_GH_LOG="$fake_gh_log"
export FAKE_RELEASE_JSON="$fake_release_json"

approval_failure="$(
  cd "$publisher_root"
  bash scripts/publish_github_release.sh "$tag" "$publisher_bundle" 2>&1 || true
)"
grep -Fq "publicação manual exige aprovação explícita do snapshot" \
  <<<"$approval_failure"
[[ ! -s "$fake_gh_log" ]] || {
  echo "release pipeline test failed: publisher chamou gh sem aprovação" >&2
  exit 1
}

export RELEASE_MANUAL_APPROVAL="publish:$tag@$publisher_sha#$approved_bundle_digest"

# Uma aprovação de source não pode ser reutilizada depois que os sete arquivos
# do bundle são integralmente substituídos por outro conjunto coerente.
printf 'replacement macOS fixture\n' >"$bundle_dir/DryEyeWidget.dmg"
printf 'replacement Windows installer fixture\n' \
  >"$bundle_dir/DryEyeWidget-Setup-x64.exe"
printf 'replacement Windows portable fixture\n' \
  >"$bundle_dir/DryEyeWidget-windows-x64.zip"
printf 'replacement MSIX fixture\n' >"$bundle_dir/dry_eye_widget.msix"
write_publisher_manifests
: >"$fake_gh_log"
replacement_failure="$(
  cd "$publisher_root"
  bash scripts/publish_github_release.sh "$tag" "$publisher_bundle" 2>&1 || true
)"
grep -Fq "publicação manual exige aprovação explícita do snapshot" \
  <<<"$replacement_failure"
[[ ! -s "$fake_gh_log" ]] || {
  echo "release pipeline test failed: bundle substituído acessou gh com aprovação antiga" >&2
  exit 1
}

rm "$publisher_bundle"/*
cp "$publisher_bundle_backup"/* "$publisher_bundle/"
bundle_dir="$publisher_bundle"
write_publisher_manifests
[[ "$(canonical_bundle_digest_for "$publisher_bundle")" == \
  "$approved_bundle_digest" ]] || {
  echo "release pipeline test failed: restauração do bundle aprovado divergiu" >&2
  exit 1
}
: >"$fake_gh_log"

publisher_output="$(
  cd "$publisher_root"
  bash scripts/publish_github_release.sh "$tag" "$publisher_bundle"
)"
grep -Fq "já publicada e idêntica aos manifests; nada a fazer" \
  <<<"$publisher_output"
if grep -Eq 'release (upload|edit|create)' "$fake_gh_log"; then
  echo "release pipeline test failed: retomada idempotente tentou mutação" >&2
  exit 1
fi

# Um rascunho recuperável pode conter lixo de tentativa anterior. O publisher
# remove somente extras, preserva os quatro nomes esperados, faz clobber neles
# e não rouba latest de uma versão SemVer mais nova.
draft_release_json="$fixture_root/draft-release.json"
clean_draft_json="$fixture_root/clean-draft-release.json"
jq \
  '.isDraft = true
   | .publishedAt = null
   | .assets += [{
       name: "obsolete-debug.zip",
       size: 17,
       digest: "sha256:obsolete"
     }]' \
  "$fake_release_json" >"$draft_release_json"
jq '.isDraft = true | .publishedAt = null' \
  "$fake_release_json" >"$clean_draft_json"
: >"$fake_gh_log"

gh() {
  printf '%s\n' "$*" >>"$FAKE_GH_LOG"
  if [[ "$1 $2" == "release list" ]]; then
    jq -c \
      '[{
          tagName: .tagName,
          isDraft: .isDraft,
          isPrerelease: .isPrerelease,
          publishedAt: .publishedAt
        },
        {
          tagName: "v9.0.0",
          isDraft: false,
          isPrerelease: false,
          publishedAt: "2026-07-30T00:00:00Z"
        }]' \
      "$DRAFT_RELEASE_JSON"
    return 0
  fi
  if [[ "$1 $2" == "release view" ]]; then
    if [[ "${3:-}" == "--json" ]]; then
      printf 'v9.0.0\n'
    else
      jq -c . "$DRAFT_RELEASE_JSON"
    fi
    return 0
  fi
  if [[ "$1 $2" == "release delete-asset" ]]; then
    [[ "${4:-}" == "obsolete-debug.zip" ]] || return 1
    cp "$CLEAN_DRAFT_JSON" "$DRAFT_RELEASE_JSON"
    return 0
  fi
  if [[ "$1 $2" == "release upload" ]]; then
    cp "$CLEAN_DRAFT_JSON" "$DRAFT_RELEASE_JSON"
    return 0
  fi
  if [[ "$1 $2" == "release edit" ]]; then
    if [[ "$*" == *"--draft=false"* ]]; then
      jq '.isDraft = false | .publishedAt = "2026-07-29T00:00:00Z"' \
        "$DRAFT_RELEASE_JSON" >"$DRAFT_RELEASE_JSON.next"
      mv "$DRAFT_RELEASE_JSON.next" "$DRAFT_RELEASE_JSON"
    fi
    return 0
  fi
  echo "unexpected gh command in draft recovery test: $*" >&2
  return 1
}
export -f gh
export DRAFT_RELEASE_JSON="$draft_release_json"
export CLEAN_DRAFT_JSON="$clean_draft_json"

draft_output="$(
  cd "$publisher_root"
  bash scripts/publish_github_release.sh "$tag" "$publisher_bundle"
)"
grep -Fq "Removendo asset extra do rascunho: obsolete-debug.zip" \
  <<<"$draft_output"
grep -Fq "release delete-asset $tag obsolete-debug.zip --yes" "$fake_gh_log"
if grep -Eq "release delete-asset $tag (DryEyeWidget|dry_eye_widget)" \
  "$fake_gh_log"; then
  echo "release pipeline test failed: asset esperado foi removido" >&2
  exit 1
fi
grep -Fq "release upload $tag" "$fake_gh_log"
grep -Fq "release edit $tag --draft=false" "$fake_gh_log"
if grep -F "release edit $tag" "$fake_gh_log" | grep -Fq -- "--latest"; then
  echo "release pipeline test failed: release antiga tomou latest" >&2
  exit 1
fi

# A reconciliação pós-publicação deve convergir para a maior SemVer qualquer
# que seja a ordem em que duas versões terminem a publicação.
latest_releases_json="$fixture_root/latest-releases.json"
latest_current_tag="$fixture_root/latest-current.txt"
latest_gh_log="$fixture_root/latest-gh.log"

gh() {
  printf '%s\n' "$*" >>"$LATEST_GH_LOG"
  if [[ "$1 $2" == "release list" ]]; then
    jq -c . "$LATEST_RELEASES_JSON"
    return 0
  fi
  if [[ "$1 $2" == "release view" && "${3:-}" == "--json" ]]; then
    test -s "$LATEST_CURRENT_TAG" || return 1
    tr -d '\n' <"$LATEST_CURRENT_TAG"
    printf '\n'
    return 0
  fi
  if [[ "$1 $2" == "release edit" && "${4:-}" == "--latest" ]]; then
    printf '%s\n' "$3" >"$LATEST_CURRENT_TAG"
    return 0
  fi
  echo "unexpected gh command in latest convergence test: $*" >&2
  return 1
}
export -f gh
export LATEST_RELEASES_JSON="$latest_releases_json"
export LATEST_CURRENT_TAG="$latest_current_tag"
export LATEST_GH_LOG="$latest_gh_log"

publish_for_latest_test() {
  local published_tag="$1"
  jq \
    --arg tag "$published_tag" \
    '. + [{
      tagName: $tag,
      isDraft: false,
      isPrerelease: false,
      publishedAt: "2026-07-29T00:00:00Z"
    }]' \
    "$latest_releases_json" >"$latest_releases_json.next"
  mv "$latest_releases_json.next" "$latest_releases_json"
  # Simula o comportamento remoto em que a última publicação pode tomar latest
  # antes da reconciliação determinística.
  printf '%s\n' "$published_tag" >"$latest_current_tag"
  bash scripts/reconcile_release_latest.sh >/dev/null
}

run_latest_order() {
  local first="$1"
  local second="$2"
  printf '[]\n' >"$latest_releases_json"
  : >"$latest_current_tag"
  : >"$latest_gh_log"
  publish_for_latest_test "$first"
  publish_for_latest_test "$second"
  [[ "$(tr -d '\n' <"$latest_current_tag")" == "v1.27.0" ]] || {
    echo "release pipeline test failed: latest não convergiu em $first -> $second" >&2
    exit 1
  }
}

run_latest_order v1.26.0 v1.27.0
run_latest_order v1.27.0 v1.26.0

echo "release pipeline tests: passed (read-only Actions, bundle-bound manual approval, source trust, metadata, bundle, draft recovery, convergent latest and idempotency guards)"
