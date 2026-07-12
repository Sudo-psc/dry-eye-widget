# Landing screenshot refresh — 2026-07-12

## Objective

Update the public carousel with current app UI while keeping the Flutter app isolated from the static landing and avoiding personal/runtime data in the captures.

## Artifacts

- `site/assets/shots/ball-menu.webp`: current liquid orb, progress ring and compact menu.
- `site/assets/shots/day-summary.webp`: current daily summary flow.
- `projects/dry-eye-widget-app/artifacts/landing-menu-current.png`: clean runtime source capture.
- `2026-07-12-screenshots-desktop.png`: landing carousel at 1440×1000.
- `2026-07-12-screenshots-mobile.png`: landing carousel at 430×932.
- `tool/landing_menu_preview.dart`: isolated Flutter preview without app services or private data.
- `tool/capture_landing_section.mjs`: repeatable Chrome DevTools section capture.

## Verification

- `node site/scripts/smoke-check.mjs`: passed.
- `flutter analyze tool/landing_menu_preview.dart`: passed with no issues.
- `node --check tool/capture_landing_section.mjs`: passed.
- `git diff --check`: passed.
- Desktop and mobile carousel evidence reviewed visually; the updated screenshot remains fully framed and captions remain legible.

## Learning and next action

Portrait app screens need a transparent 16:10 presentation canvas before entering this landscape carousel; relying on percentage `max-height` alone can crop them after responsive layout. The next screenshot round should capture the current Windows v1.24+ app on a real Windows session.
