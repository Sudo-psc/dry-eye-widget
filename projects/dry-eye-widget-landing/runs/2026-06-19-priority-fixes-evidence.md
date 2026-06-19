# 2026-06-19 priority fixes evidence

## Scope

- Confirmed `/app/` as the single official landing route.
- Kept the implementation in `site/`.
- Fixed landing JavaScript safety for pages that do not load i18n.
- Added complete FAQ i18n coverage.
- Updated PT-BR privacy and terms text for Windows/macOS, optional camera presence, OSDI history, and screen-time history.
- Added release guardrails to the Windows MSIX workflow.
- Added a static smoke check for the landing contract.
- Added the static smoke check to the GitHub Pages deployment workflow.

## Verification

- `node site/scripts/smoke-check.mjs`: passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed with 73 tests.

## Residual notes

- Flutter still warns that `screen_retriever_macos`, `tray_manager`, and `local_notifier` do not support Swift Package Manager for macOS. This is not failing today but should be tracked before future Flutter upgrades.
- The first concurrent test run failed while Flutter tried to delete an ephemeral macOS package file during another Flutter command. Re-running tests in isolation passed.
